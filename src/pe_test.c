#include <stdio.h>


int r(int);
int r_no(int);
int get_32(int);

int plus_7(int x) {
    return x+7;
}

int main(int argc, char** argv) {
    printf("%i\n",get_32(2));
}