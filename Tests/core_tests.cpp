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
    PDEvent t[]={{1,0,0.8f},{1,2,0.7f},{1.25,0,0.8f},{2,1,0.4f}};
    PDEvent h[]={{1.01,0,0.8f},{1.01,2,0.7f},{1.02,0,0.8f},{1.26,0,0.8f},{2.02,4,0.4f}};
    PDResult s{}; pd_score(t,4,h,5,0.1,&s);
    assert(s.hits==3 && s.extras==2 && s.misses==1);
    assert(std::abs(s.biasMs-10)<0.001 && std::abs(s.medianErrorMs-10)<0.001);
    PDEvent b[]={{4,0,0.8f},{4.08,0,0.8f}};
    PDEvent bh[]={{3.99,0,0.8f},{4.081,0,0.8f}};
    pd_score(b,2,bh,2,0.1,&s);
    assert(s.hits==2 && s.extras==0);
    pd_score(nullptr,0,nullptr,0,0.1,&s);
    assert(s.hits==0 && std::isfinite(s.medianErrorMs));
    std::cout<<"PASS: instrument, scheduling, cancellation, polyphony, 16 sounds, one-to-one scoring, unisons, boundaries, empty input\n";
}
