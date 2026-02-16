#include <inttypes.h>

#define N (3)

int multiply(uint32_t x, uint32_t y) {
    int sign = 1;
    int sum = 0;

    int a, b;

    // Smaller number is the loop iterator
    if (x > y) {
        a = y;
        b = x;
    } else {
        a = x;
        b = y;
    }

    for (uint32_t i = 0; i < a; i++) {
        sum += b;
    }

    return sum;
}

int main(void) {
    uint32_t a1[N] = {2, 80, 3};
    uint32_t a2[N] = {7, 2, 27};

    uint32_t sum = 0;

    for (uint32_t i = 0; i < N; i++) {
        sum += multiply(a1[i], a2[i]);
    }

    return 0;
}