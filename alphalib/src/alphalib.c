#include <stdio.h>
#include "alphalib.h"

void alphaprintint(num val) {
    printf("%lld", val);
}

void alphaprintstr(const str val) {
    printf("%s", val);
}

num alphascan() {
    num i;
    scanf("%lld", &i);

    return i;
}
