#include <iostream>


using namespace std;

extern "C" int get_value_from_asm();

int main()
{
	std::cout << "asm said: " << get_value_from_asm() << std::endl;
	std::cin.get();
	return 0;
}