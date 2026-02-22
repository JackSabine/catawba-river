#include <inttypes.h>

#define N (30)

void insertionsort(uint32_t *arr, uint32_t size) {
    for (uint32_t i = 1; i < size; i++) {
        uint32_t key = arr[i];
        uint32_t j = i;
        while (j > 0 && arr[j - 1] > key) {
            arr[j] = arr[j - 1];
            j--;
        }
        arr[j] = key;
    }
}

uint32_t array[N] = {
    184, 423, 17,  956, 302, 71,  648, 215, 839, 504,
    133, 767, 391, 28,  612, 480, 155, 923, 344, 89,
    731, 267, 598, 42,  876, 319, 694, 163, 537, 808
};

int main(void) {
    insertionsort(array, N);

    return 0;
}