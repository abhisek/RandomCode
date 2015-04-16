#include <stdio.h>
#include <sys/types.h>
#include <iostream>

using namespace std;

class Bling {
	public:
	virtual void hello();
};

void Bling::hello()
{
	cout << "Hello World" << endl;
}

int main(int argc, char **argv)
{
	Bling *b1 = new Bling();
	Bling *b2 = b1;

	b1->hello();
	delete b1;

	b2->hello();
}



