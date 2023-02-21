int a, b;

int x, y;

int add_int(int, int);

int mul_int(int, int, int);

void print_global();

int main() {
    int list[5], another_list[5], i;

    a = 1+2*3-4/2+(7%3);

    list[1] = a+list[0]+another_list[0]; // addition of array variables

    {
        int i, j;
    }

    for(i=0; i<5; i++) {
        list[1]++;
    }

    while(a<=0) {
        a--;
    }

    if(list[4]>10 || another_list[4]>=10) {
        i = !0;
    }

    /*
      no float handling
    */
    if(a==0 && x!=9) {
        y = mul_int(2-3, 5*2, 2%4);
    } else {
        b = -add_int(4, 7);
    }

    print_global();

    return 0;
}

int add_int(int a, int b) {
    return a+b;
}

int mul_int(int x, int y, int z) {
    return x*y*z;
}

void print_global() {
    println(a);
    println(b);
    println(x);
    println(y);
}
