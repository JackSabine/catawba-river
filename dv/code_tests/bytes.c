#include <inttypes.h>

int main () {
    uint8_t a;
    int8_t b;
    int8_t c;

    a = 3;
    b = -1;

    b = b + b;

    c = a + b + b;

    return c;
}
