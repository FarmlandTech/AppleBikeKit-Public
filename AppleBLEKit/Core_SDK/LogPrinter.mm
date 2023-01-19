#include "LogPrinter.h"

void LogPrinter::error(std::string msg_str)
{
	std::cout << "[ERROR]:"+ msg_str + "\n";
}

void LogPrinter::debug(std::string msg_str)
{
	std::cout << "[DEBUG]:"+ msg_str+"\n";
}


