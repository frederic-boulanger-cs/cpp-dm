#include <iostream>

int main(int argc, char * argv[]) {
    std::cout << "Program called with " << argc << " arguments" << std::endl;
    for (int i = 0; i < argc; ++i) {
        std::cout << "arg[" << i << "] = " << argv[i] << std::endl;
    }
}
