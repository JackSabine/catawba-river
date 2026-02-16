#include <inttypes.h>

#define N (5)


int main(void) {
    uint32_t a[N] = {5, 10, 6, 89, 42};
    int sum;

    for (uint32_t i = 0; i < N; i++) {
        sum += a[i];
    }

    return 0;
}