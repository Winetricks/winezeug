#include "boost/date_time/gregorian/gregorian.hpp"
#include <iostream>
#include <string>

int main()
{
    using namespace boost::gregorian;

    std::string s("2001-10-9");
    date d(from_simple_string(s));
    std::cout << "Testing date parsing and printing: 9 October 2001 = " << to_simple_string(d) << std::endl;
    return 0;
}
