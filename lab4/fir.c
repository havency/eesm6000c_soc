#include "fir.h"

void __attribute__ ((section(".mprjram"))) initfir() {
    // Initialize inputbuffer to zeros
    for (int i = 0; i < N; i++) {
        inputbuffer[i] = 0;
    }
}

int* __attribute__ ((section(".mprjram"))) fir() {
    initfir();
    
    // Process each output sample
    for (int i = 0; i < N; i++) {
        // Shift inputbuffer and add new input
        for (int j = N-1; j > 0; j--) {
            inputbuffer[j] = inputbuffer[j-1];
        }
        inputbuffer[0] = inputsignal[i];
        
        // Compute FIR output: y[i] = Σ(taps[k] * inputbuffer[k])
        outputsignal[i] = 0;
        for (int k = 0; k < N; k++) {
            outputsignal[i] += taps[k] * inputbuffer[k];
        }
    }
    
    return outputsignal;
}