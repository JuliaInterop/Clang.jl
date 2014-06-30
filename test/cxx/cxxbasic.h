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

	const char* func3(int x, int y=1, const char* z=0) {
		return z;
	}
};

const char* func_constcharptr();

int func(int x, int y=-10) {
    return x+y;
}

const char* func2(const char* a=0) {
	const char* b = a + 2;
    return b;
}
