#define CONST 1
#define CONSTADD CONST + 2
#define CONSTSFT (1<<2)

typedef enum {
    Juneau = 0x0,
    Seattle = 0x1,
    Portland = 0x3
} WtoECapitals;

int func(int x, int y=1) {
    return x+y;
}

const char* func2(const char* a=0) {
	const char* b = a + 2;
    return b;
}

class MyClass1 {
public:
	const char* funcA(int x, int y=1, const char* z=0) {
		return z;
	}
};

class MyClass2 : public MyClass1 {
public:
	const char* funcA(int x, int y=1, const char* z=0) {
		return z;
	}

	MyClass1* funcB() {
		return new MyClass1();
	}

	void funcC(MyClass1* m) {
		m->funcA(0,0,0);
	}

};
int func1(int a, double b, double* c, void* d);

const char* func_constcharptr();

int func(int x, int y=1) {
    return x+y;
}

const char* func2(const char* a=0) {
	const char* b = a + 2;
    return b;
}

class MyClass1 {
public:
	const char* funcA(int x, int y=1, const char* z=0) {
		return z;
	}
};

class MyClass2 : public MyClass1 {
public:
	const char* funcA(int x, int y=1, const char* z=0) {
		return z;
	}

	MyClass1* funcB() {
		return new MyClass1();
	}

	void funcC(MyClass1* m) {
		m->funcA(0,0,0);
	}

};
