#ifndef POCKET_CORE_H
#define POCKET_CORE_H
#ifdef __cplusplus
extern "C" {
#endif
typedef struct PDInstrument PDInstrument;
typedef struct { double time; int role; float velocity; } PDEvent;
typedef struct {
    int hits, extras, misses;
    double biasMs, medianErrorMs, spreadMs, velocityError;
} PDResult;
PDInstrument *pd_create(double sampleRate);
void pd_destroy(PDInstrument *engine);
int pd_enqueue(PDInstrument *engine, int pad, float velocity, double hostSeconds, int kit);
void pd_cancel(PDInstrument *engine);
void pd_render(PDInstrument *engine, float *left, float *right, int frames, double hostSeconds);
void pd_score(const PDEvent *targets, int targetCount, const PDEvent *hits, int hitCount, double window, PDResult *result);
#ifdef __cplusplus
}
#endif
#endif
