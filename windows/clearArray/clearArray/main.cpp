#include <iostream>
#include <vector>


extern "C" int zero_array(void* ptr, 
									unsigned int size_in_byte, 
									unsigned int byte_at_once
									);

int main()
{
	std::vector<int> data;
	data.resize(21);
	void * start_ptr = &data[0];
	for (int i = 0; i < data.size(); i++)
	{
		data[i] = 1;
	}
	auto first = &data[0];
	data[20] = 99999999;
	auto size = data.size()*sizeof(int);
	bool res = zero_array(first, size, 8);
	std::cout << "clearing was result was: " << res << std::endl;

	std::cin.get();
}