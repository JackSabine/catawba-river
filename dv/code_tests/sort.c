#include <inttypes.h>

#define N 2

uint32_t pseudo_print[N] = {};

void swap(uint32_t* x, uint32_t* y) {
    uint32_t temp = *x;
    *x = *y;
    *y = temp;
}

void swapSort(uint32_t a[]) {
    if (a[0] > a[1]) {
        swap(&a[0], &a[1]);
    }
}

int main(void) {
    uint32_t array[N] = {5, 2};

    for (uint8_t i = 0; i < N; i++) {
        array[i] += 2;
    }

    swapSort(array);

    return 0;
}