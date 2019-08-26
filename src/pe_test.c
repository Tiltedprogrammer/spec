#include <stdio.h>


int r(int);
int r_no(int);

int plus_7(int x) {
    return x+7;
}

int main(int argc, char** argv) {
    int x = *(argv[1]) - '0';
    printf("%i\n",x);
    printf("%i\n",r(x));
    printf("%i\n",r_no(x));
}