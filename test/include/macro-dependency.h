bool foo(int a, int b);
#define foo(a,b) bar(a) && foo(a,b);