#include <inttypes.h>

#define N (5)

int main(void) {
    uint32_t a1[N] = {5, 10, 6, 89, 42};
    uint32_t a2[N] = {7, 8, 9, 10, 11};
    uint32_t a3[N] = {0};

    for (uint32_t i = 0; i < N; i++) {
        a3[i] = a1[i] + a2[i];
    }

    return 0;
}