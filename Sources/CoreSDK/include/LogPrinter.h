#pragma once

#ifndef _LOG_PRINTER_H // include guard
#define _LOG_PRINTER_H
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <string.h>
#include <sys/types.h>

class LogPrinter
{
private:
    static std :: string _path;
    enum LogLevel
    {
        ErrorOnly,
        Warning,
        Debug
    };
    static LogLevel _log_level;

public:
    void error(std::string msg_str);
    void debug(std::string msg_str);
};

#endif /* _LOG_PRINTER_H */