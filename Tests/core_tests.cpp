#include "../POCKET/Core/PocketCore.h"
#include <cassert>
#include <cmath>
#include <iostream>
#include <vector>
static float peak(const std::vector<float>& v) { float m=0; for(float x:v) { assert(std::isfinite(x)); m=std::max(m,std::abs(x)); } return m; }
int main() {
    auto *e=pd_create(48000);
    assert(e);
    std::vector<float> l(4800),r(4800);
    pd_render(e,l.data(),r.data(),4800,10);
    assert(peak(l)==0);
    assert(pd_enqueue(e,0,0.8f,10.1,0));
    pd_render(e,l.data(),r.data(),4800,10.1);
    assert(peak(l)>0.01f && peak(r)>0.01f);
    pd_cancel(e);
    pd_enqueue(e,5,1,12,0);
    pd_render(e,l.data(),r.data(),4800,11);
    assert(peak(l)==0);
    pd_render(e,l.data(),r.data(),4800,12);
    assert(peak(l)>0.01f);
    pd_cancel(e);
    pd_render(e,l.data(),r.data(),4800,12.1);
    assert(peak(l)==0);
    for(int i=0;i<100;i++) pd_enqueue(e,i%16,1,13,1);
    pd_render(e,l.data(),r.data(),4800,13);
    assert(peak(l)<=1 && peak(r)<=1);
    for(int i=0;i<16;i++) {
        pd_cancel(e); pd_enqueue(e,i,0.8f,20,0);
        pd_render(e,l.data(),r.data(),4800,20);
        assert(peak(l)>0.001);
    }
    pd_destroy(e);
    auto *both=pd_create(48000),*open=pd_create(48000),*closed=pd_create(48000);
    pd_enqueue(both,6,0.8f,30.001,0);pd_enqueue(both,7,0.8f,30.007,0);
    pd_enqueue(open,6,0.8f,30.001,0);pd_enqueue(closed,7,0.8f,30.007,0);
    std::vector<float> a(480),ar(480),b(480),br(480),c(480),cr(480);
    pd_render(both,a.data(),ar.data(),480,30);pd_render(open,b.data(),br.data(),480,30);pd_render(closed,c.data(),cr.data(),480,30);
    for(int i=0;i<336;i++) assert(std::abs(a[i]-b[i])<0.00001f);
    for(int i=336;i<480;i++) assert(std::abs(a[i]-c[i])<0.00001f);
    auto *reverse=pd_create(48000);
    pd_enqueue(reverse,7,0.8f,30.007,0);pd_enqueue(reverse,6,0.8f,30.001,0);
    pd_render(reverse,b.data(),br.data(),480,30);
    for(int i=0;i<480;i++)assert(std::abs(a[i]-b[i])<0.00001f);
    pd_destroy(reverse);pd_destroy(both);pd_destroy(open);pd_destroy(closed);
    auto *variants=pd_create(48000);
    pd_enqueue(variants,5,0.8f,40,0);pd_render(variants,a.data(),ar.data(),480,40);pd_cancel(variants);
    pd_enqueue(variants,5,0.8f,41,0);pd_render(variants,b.data(),br.data(),480,41);
    double difference=0;for(int i=0;i<480;i++)difference+=std::abs(a[i]-b[i]);
    assert(difference>0.001);pd_destroy(variants);
    PDEvent t[]={{1,0,0.8f},{1,2,0.7f},{1.25,0,0.8f},{2,1,0.4f}};
    PDEvent h[]={{1.01,0,0.8f},{1.01,2,0.7f},{1.02,0,0.8f},{1.26,0,0.8f},{2.02,4,0.4f}};
    PDResult s{}; pd_score(t,4,h,5,0.1,&s);
    assert(s.hits==3 && s.extras==2 && s.misses==1);
    assert(std::abs(s.biasMs-10)<0.001 && std::abs(s.medianErrorMs-10)<0.001);
    PDEvent boundary[]={{4,0,0.8f},{4.08,0,0.8f}};
    PDEvent bh[]={{3.99,0,0.8f},{4.081,0,0.8f}};
    pd_score(boundary,2,bh,2,0.1,&s);
    assert(s.hits==2 && s.extras==0);
    PDEvent firstTarget[]={{0,0,0.8f}},early[]={{-0.05,0,0.8f}};
    pd_score(firstTarget,1,early,1,0.12,&s);assert(s.hits==1 && s.extras==0);
    pd_score(nullptr,0,nullptr,0,0.1,&s);
    assert(s.hits==0 && std::isfinite(s.medianErrorMs));
    std::cout<<"PASS: instrument, scheduling, cancellation, polyphony, 16 layered sounds, sample-offset hat choke (both enqueue orders), round robin, one-to-one scoring, unisons, boundaries, early hits, empty input\n";
}
