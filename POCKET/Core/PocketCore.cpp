#include "PocketCore.h"
#include <algorithm>
#include <array>
#include <atomic>
#include <cmath>
#include <cstdint>
#include <vector>
namespace {
constexpr double pi=3.14159265358979323846;
constexpr int queueSize=4096, maxPending=512, voiceCount=96;
constexpr int roles[18]={0,0,2,1,1,1,3,2,4,5,6,7,8,9,10,11,12,12};
struct Command { int pad=0,kit=0; float velocity=0; double time=0; unsigned epoch=0; };
struct Voice { const std::vector<float>* sample=nullptr; int position=0; float gain=0; int role=0; };
float noise(uint32_t& seed) { seed^=seed<<13;seed^=seed>>17;seed^=seed<<5;return float(seed)/float(UINT32_MAX)*2-1; }
std::vector<float> sound(int pad,int kit,double rate) {
    int role=roles[pad];
    double duration=(role==8||role==9)?1.1:(role==3?0.5:0.42);
    if(role==12) duration=0.04;
    std::vector<float> data(static_cast<size_t>(duration*rate));
    uint32_t seed=0x9173abcdU+pad*137+kit*997;
    double phase=0,low=0,lastNoise=0;
    for(size_t i=0;i<data.size();++i) {
        double t=double(i)/rate;
        double n=noise(seed),high=n-lastNoise; lastNoise=n;
        low+=0.10*(n-low);
        double x=0;
        switch(role) {
            case 0: { double f=(kit?45:53)+110*std::exp(-t*48);phase+=2*pi*f/rate;x=std::sin(phase)*std::exp(-t*(kit?10:16))+0.12*high*std::exp(-t*180);break; }
            case 1: x=(0.60*high+0.20*n)*std::exp(-t*(kit?23:32))+0.40*std::sin(2*pi*185*t)*std::exp(-t*35);break;
            case 2: case 3: { double decay=role==2?85:12;double metal=std::sin(2*pi*4123*t)*std::sin(2*pi*5879*t);x=(0.5*high+0.15*metal)*std::exp(-t*decay);break; }
            case 4: x=(std::sin(2*pi*690*t)+0.4*std::sin(2*pi*1050*t))*std::exp(-t*32)*0.55;break;
            case 5: x=high*std::exp(-t*48)*(0.5+0.5*std::sin(2*pi*37*t));break;
            case 6: { double env=std::exp(-t*20); if(t<0.045) env*=0.35+0.65*std::pow(std::sin(2*pi*36*t),2);x=high*env*0.75;break; }
            case 7: x=(std::sin(2*pi*1700*t)+0.6*std::sin(2*pi*2250*t))*std::exp(-t*100)*0.55;break;
            case 8: x=(0.45*high+0.16*std::sin(2*pi*3923*t)*std::sin(2*pi*6679*t))*std::exp(-t*5);break;
            case 9: x=(0.3*high+0.3*std::sin(2*pi*3600*t)*std::sin(2*pi*5700*t))*std::exp(-t*8);break;
            case 10: case 11: { double f=(role==10?180:112)+80*std::exp(-t*38);phase+=2*pi*f/rate;x=0.8*std::sin(phase)*std::exp(-t*15)+0.08*n*std::exp(-t*90);break; }
            case 12: x=0.7*std::sin(2*pi*(pad==17?1500:1000)*t)*std::exp(-t*180);break;
        }
        if(kit==1&&role!=12) x=std::tanh(x*1.4)*0.85;
        double attack=std::min(1.0,t*rate/6);
        data[i]=static_cast<float>(x*attack*0.75);
    }
    return data;
}
}
struct PDInstrument {
    explicit PDInstrument(double rate): rate(rate) { for(int k=0;k<2;++k)for(int p=0;p<18;++p)samples[k][p]=sound(p,k,rate); }
    double rate;
    std::array<std::array<std::vector<float>,18>,2> samples;
    std::array<Command,queueSize> queue;
    std::atomic<unsigned> read{0},write{0},epoch{1};
    unsigned renderEpoch=1;
    std::array<Command,maxPending> pending;
    int pendingCount=0,steal=0;
    std::array<Voice,voiceCount> voices;
};
PDInstrument *pd_create(double rate) { if(!std::isfinite(rate)||rate<8000||rate>192000)return nullptr;return new PDInstrument(rate); }
void pd_destroy(PDInstrument *e) { delete e; }
int pd_enqueue(PDInstrument *e,int pad,float velocity,double time,int kit) {
    if(!e||pad<0||pad>=18||kit<0||kit>1||!std::isfinite(time)||!std::isfinite(velocity))return 0;
    unsigned w=e->write.load(std::memory_order_relaxed),r=e->read.load(std::memory_order_acquire);
    if(w-r>=queueSize)return 0;
    e->queue[w%queueSize]={pad,kit,std::clamp(velocity,0.f,1.f),time,e->epoch.load(std::memory_order_acquire)};
    e->write.store(w+1,std::memory_order_release);return 1;
}
void pd_cancel(PDInstrument *e) { if(e)e->epoch.fetch_add(1,std::memory_order_acq_rel); }
void pd_render(PDInstrument *e,float *l,float *r,int frames,double host) {
    if(!e||!l||!r||frames<=0)return;
    unsigned generation=e->epoch.load(std::memory_order_acquire);
    if(generation!=e->renderEpoch) { e->pendingCount=0;for(auto&v:e->voices)v=Voice{};e->renderEpoch=generation; }
    unsigned read=e->read.load(std::memory_order_relaxed),write=e->write.load(std::memory_order_acquire);
    while(read!=write) {
        Command c=e->queue[read%queueSize];++read;
        if(c.epoch==generation&&e->pendingCount<maxPending)e->pending[e->pendingCount++]=c;
    }
    e->read.store(read,std::memory_order_release);
    double end=host+frames/e->rate;
    for(int i=0;i<e->pendingCount;) {
        Command c=e->pending[i];
        if(c.time>=end) { ++i;continue; }
        int start=std::max(0,static_cast<int>(std::llround((c.time-host)*e->rate)));
        // Events older than a quarter second are stale after an overloaded/interrupted callback.
        if(c.time>=host-0.25) {
            Voice *v=nullptr;
            for(auto&candidate:e->voices)if(!candidate.sample) { v=&candidate;break; }
            if(!v)v=&e->voices[e->steal++%voiceCount];
            float accent=c.pad==4?0.35f:1.f;
            *v={&e->samples[c.kit][c.pad],-start,c.velocity*accent*0.48f,roles[c.pad]};
        }
        e->pending[i]=e->pending[--e->pendingCount];
    }
    for(int f=0;f<frames;++f) {
        // Apply a choke at the strike's sample offset, including unordered look-ahead input.
        for(auto&v:e->voices)if(v.sample&&v.position==0&&v.role==2)
            for(auto&open:e->voices)if(open.sample&&open.role==3&&open.position>=0)open.sample=nullptr;
        float sum=0;
        for(auto&v:e->voices)if(v.sample) {
            if(v.position<0) { ++v.position;continue; }
            if(v.position>=static_cast<int>(v.sample->size())) { v.sample=nullptr;continue; }
            sum+=(*v.sample)[v.position++]*v.gain;
        }
        l[f]=r[f]=std::tanh(sum);
    }
}
void pd_score(const PDEvent *t,int nt,const PDEvent *h,int nh,double window,PDResult *out) {
    if(!out)return;
    *out=PDResult{};nt=std::max(0,nt);nh=std::max(0,nh);
    if(!t)nt=0;if(!h)nh=0;
    std::vector<bool> used(nt,false);
    std::vector<double> errors,absolute;
    double velocity=0;
    for(int i=0;i<nh;++i) {
        int best=-1;double distance=window;
        for(int j=0;j<nt;++j)if(!used[j]&&t[j].role==h[i].role) {
            double d=std::abs(h[i].time-t[j].time);
            double local=window;
            for(int k=0;k<nt;++k)if(k!=j&&t[k].role==t[j].role&&std::abs(t[k].time-t[j].time)>0.000001)
                local=std::min(local,std::abs(t[k].time-t[j].time)*0.49);
            if(std::isfinite(d)&&d<=local&&d<=distance) { best=j;distance=d; }
        }
        if(best<0) { ++out->extras;continue; }
        used[best]=true;++out->hits;
        double error=(h[i].time-t[best].time)*1000;
        errors.push_back(error);absolute.push_back(std::abs(error));
        velocity+=std::abs(h[i].velocity-t[best].velocity);
    }
    out->misses=nt-out->hits;
    if(errors.empty())return;
    for(double x:errors)out->biasMs+=x;
    out->biasMs/=errors.size();
    for(double x:errors)out->spreadMs+=(x-out->biasMs)*(x-out->biasMs);
    out->spreadMs=std::sqrt(out->spreadMs/errors.size());
    std::sort(absolute.begin(),absolute.end());size_t n=absolute.size();
    out->medianErrorMs=n%2?absolute[n/2]:(absolute[n/2-1]+absolute[n/2])/2;
    out->velocityError=velocity/errors.size();
}
