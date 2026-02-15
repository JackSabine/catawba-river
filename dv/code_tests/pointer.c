#include <inttypes.h>

void swap(uint32_t* x, uint32_t* y) {
    uint32_t temp = *x;
    *x = *y;
    *y = temp;
}

int main(void) {
    uint32_t x, y;
    uint32_t *x_ptr, *y_ptr;

    x_ptr = &x;
    y_ptr = &y;

    *x_ptr = 10;
    *y_ptr = 20;

    swap(x_ptr, y_ptr);

    return 0;
}
