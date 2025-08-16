//+------------------------------------------------------------------+
//| Logger.mqh                                                       |
//| Copyright 2024, SuppResist                                       |
//| https://www.mql5.com                                             |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, SuppResist"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "SuppResist.mqh"

//+------------------------------------------------------------------+
//| Log Level Enumeration                                            |
//+------------------------------------------------------------------+
enum ENUM_LOG_LEVEL
{
   LOG_LEVEL_DEBUG = 0,     // Debug messages
   LOG_LEVEL_INFO = 1,      // Information messages
   LOG_LEVEL_WARNING = 2,   // Warning messages
   LOG_LEVEL_ERROR = 3,     // Error messages
   LOG_LEVEL_CRITICAL = 4   // Critical error messages
};

//+------------------------------------------------------------------+
//| CLogger Class                                                    |
//+------------------------------------------------------------------+
class CLogger
{
private:
   string            m_log_prefix;           // Log message prefix
   ENUM_LOG_LEVEL    m_min_log_level;        // Minimum log level to output
   bool              m_log_to_file;          // Enable file logging
   bool              m_log_to_console;       // Enable console logging
   bool              m_enable_debug;         // Enable debug logging
   int               m_file_handle;          // File handle for logging
   string            m_log_file_path;        // Log file path
   bool              m_initialized;          // Initialization flag
   
   // Internal methods
   string GetLogLevelText(ENUM_LOG_LEVEL level);
   color GetLogLevelColor(ENUM_LOG_LEVEL level);
   bool WriteToFile(const string message);
   string FormatMessage(ENUM_LOG_LEVEL level, const string message, const string function_name = "");
   
public:
   // Constructor/Destructor
   CLogger();
   ~CLogger();
   
   // Initialization
   bool Initialize(const string log_prefix = "SuppResist", 
                   bool enable_debug = false,
                   bool log_to_file = true,
                   bool log_to_console = true,
                   ENUM_LOG_LEVEL min_level = LOG_LEVEL_INFO);
   void Deinitialize();
   
   // Configuration methods
   void SetLogPrefix(const string prefix) { m_log_prefix = prefix; }
   void SetMinLogLevel(ENUM_LOG_LEVEL level) { m_min_log_level = level; }
   void SetDebugMode(bool enable) { m_enable_debug = enable; }
   void SetFileLogging(bool enable) { m_log_to_file = enable; }
   void SetConsoleLogging(bool enable) { m_log_to_console = enable; }
   
   // Main logging methods
   void Debug(const string message, const string function_name = "");
   void Info(const string message, const string function_name = "");
   void Warning(const string message, const string function_name = "");
   void Error(const string message, const string function_name = "");
   void Critical(const string message, const string function_name = "");
   
   // Specialized logging methods
   void LogTrade(const string symbol, const string action, const string details = "");
   void LogSignal(const string symbol, ENUM_SIGNAL_DIRECTION signal, const string reason = "");
   void LogIndicator(const string symbol, const string indicator_name, const string values);
   void LogPerformance(const string operation, uint execution_time_ms);
   void LogPosition(const string symbol, const string action, double price, double volume, const string comment = "");
   
   // Utility methods
   void Print(const string message);                    // Replacement for standard Print()

   void LogArray(const string array_name, const double& array[], int start_index = 0, int count = -1);
   void LogArray(const string array_name, const string& array[], int start_index = 0, int count = -1);
   
   // Status methods
   bool IsInitialized() const { return m_initialized; }
   bool IsDebugEnabled() const { return m_enable_debug; }
   string GetLogFilePath() const { return m_log_file_path; }
   
   // File management
   bool FlushLogFile();
   bool ClearLogFile();
   long GetLogFileSize();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CLogger::CLogger() : m_initialized(false),
                     m_log_prefix("SuppResist"),
                     m_min_log_level(LOG_LEVEL_INFO),
                     m_log_to_file(true),
                     m_log_to_console(true),
                     m_enable_debug(false),
                     m_file_handle(INVALID_HANDLE)
{
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CLogger::~CLogger()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize logger                                                |
//+------------------------------------------------------------------+
bool CLogger::Initialize(const string log_prefix = "SuppResist",
                         bool enable_debug = false,
                         bool log_to_file = true,
                         bool log_to_console = true,
                         ENUM_LOG_LEVEL min_level = LOG_LEVEL_INFO)
{
   if(m_initialized)
      return true;
   
   m_log_prefix = log_prefix;
   m_enable_debug = enable_debug;
   m_log_to_file = log_to_file;
   m_log_to_console = log_to_console;
   m_min_log_level = min_level;
   
   // Initialize file logging if enabled
   if(m_log_to_file)
   {
      // Create log file path
      m_log_file_path = StringFormat("%s\\Files\\%s_%s.log", 
                                     TerminalInfoString(TERMINAL_DATA_PATH),
                                     m_log_prefix,
                                     TimeToString(TimeCurrent(), TIME_DATE));
      
      // Try to open log file
      m_file_handle = FileOpen(StringFormat("%s_%s.log", m_log_prefix, TimeToString(TimeCurrent(), TIME_DATE)),
                               FILE_WRITE | FILE_TXT | FILE_ANSI);
      
      if(m_file_handle == INVALID_HANDLE)
      {
         ::Print("Logger: Failed to open log file: ", GetLastError());
         m_log_to_file = false;
      }
      else
      {
         // Write header to log file
         string header = StringFormat("=== %s Log Started ===\n", m_log_prefix);
         FileWrite(m_file_handle, header);
         FileFlush(m_file_handle);
      }
   }
   
   m_initialized = true;
   
   // Log initialization
   Info(StringFormat("Logger initialized - Debug: %s, File: %s, Console: %s", 
                     enable_debug ? "ON" : "OFF",
                     m_log_to_file ? "ON" : "OFF", 
                     m_log_to_console ? "ON" : "OFF"));
   
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize logger                                              |
//+------------------------------------------------------------------+
void CLogger::Deinitialize()
{
   if(!m_initialized)
      return;
   
   if(m_file_handle != INVALID_HANDLE)
   {
      // Write footer to log file
      string footer = StringFormat("=== %s Log Ended ===\n", m_log_prefix);
      FileWrite(m_file_handle, footer);
      FileClose(m_file_handle);
      m_file_handle = INVALID_HANDLE;
   }
   
   m_initialized = false;
}

//+------------------------------------------------------------------+
//| Get log level text                                               |
//+------------------------------------------------------------------+
string CLogger::GetLogLevelText(ENUM_LOG_LEVEL level)
{
   switch(level)
   {
      case LOG_LEVEL_DEBUG:     return "DEBUG";
      case LOG_LEVEL_INFO:      return "INFO";
      case LOG_LEVEL_WARNING:   return "WARN";
      case LOG_LEVEL_ERROR:     return "ERROR";
      case LOG_LEVEL_CRITICAL:  return "CRITICAL";
      default:                  return "UNKNOWN";
   }
}

//+------------------------------------------------------------------+
//| Get log level color                                              |
//+------------------------------------------------------------------+
color CLogger::GetLogLevelColor(ENUM_LOG_LEVEL level)
{
   switch(level)
   {
      case LOG_LEVEL_DEBUG:     return clrGray;
      case LOG_LEVEL_INFO:      return clrBlue;
      case LOG_LEVEL_WARNING:   return clrOrange;
      case LOG_LEVEL_ERROR:     return clrRed;
      case LOG_LEVEL_CRITICAL:  return clrMagenta;
      default:                  return clrBlack;
   }
}

//+------------------------------------------------------------------+
//| Format log message                                               |
//+------------------------------------------------------------------+
string CLogger::FormatMessage(ENUM_LOG_LEVEL level, const string message, const string function_name = "")
{
   string formatted_message = m_log_prefix + ": ";
   
   // Add log level
   formatted_message += "[" + GetLogLevelText(level) + "] ";
   
   // Add function name if provided
   if(function_name != "")
      formatted_message += function_name + "() - ";
   
   // Add main message
   formatted_message += message;
   
   return formatted_message;
}

//+------------------------------------------------------------------+
//| Write message to file                                            |
//+------------------------------------------------------------------+
bool CLogger::WriteToFile(const string message)
{
   if(!m_log_to_file || m_file_handle == INVALID_HANDLE)
      return false;
   
   // Add timestamp for file logging
   string timestamped_message = StringFormat("[%s] %s", 
                                           TimeToString(TimeCurrent(), TIME_SECONDS), 
                                           message);
   
   uint bytes_written = FileWrite(m_file_handle, timestamped_message);
   FileFlush(m_file_handle);
   
   return (bytes_written > 0);
}

//+------------------------------------------------------------------+
//| Debug logging                                                    |
//+------------------------------------------------------------------+
void CLogger::Debug(const string message, const string function_name = "")
{
   if(!m_enable_debug || LOG_LEVEL_DEBUG < m_min_log_level)
      return;
   
   string formatted_message = FormatMessage(LOG_LEVEL_DEBUG, message, function_name);
   
   if(m_log_to_console)
      ::Print(formatted_message);
      
   if(m_log_to_file)
      WriteToFile(formatted_message);
}

//+------------------------------------------------------------------+
//| Info logging                                                     |
//+------------------------------------------------------------------+
void CLogger::Info(const string message, const string function_name = "")
{
   if(LOG_LEVEL_INFO < m_min_log_level)
      return;
   
   string formatted_message = FormatMessage(LOG_LEVEL_INFO, message, function_name);
   
   if(m_log_to_console)
      ::Print(formatted_message);
      
   if(m_log_to_file)
      WriteToFile(formatted_message);
}

//+------------------------------------------------------------------+
//| Warning logging                                                  |
//+------------------------------------------------------------------+
void CLogger::Warning(const string message, const string function_name = "")
{
   if(LOG_LEVEL_WARNING < m_min_log_level)
      return;
   
   string formatted_message = FormatMessage(LOG_LEVEL_WARNING, message, function_name);
   
   if(m_log_to_console)
      ::Print(formatted_message);
      
   if(m_log_to_file)
      WriteToFile(formatted_message);
}

//+------------------------------------------------------------------+
//| Error logging                                                    |
//+------------------------------------------------------------------+
void CLogger::Error(const string message, const string function_name = "")
{
   if(LOG_LEVEL_ERROR < m_min_log_level)
      return;
   
   string formatted_message = FormatMessage(LOG_LEVEL_ERROR, message, function_name);
   
   if(m_log_to_console)
      ::Print(formatted_message);
      
   if(m_log_to_file)
      WriteToFile(formatted_message);
}

//+------------------------------------------------------------------+
//| Critical logging                                                 |
//+------------------------------------------------------------------+
void CLogger::Critical(const string message, const string function_name = "")
{
   string formatted_message = FormatMessage(LOG_LEVEL_CRITICAL, message, function_name);
   
   if(m_log_to_console)
      ::Print(formatted_message);
      
   if(m_log_to_file)
      WriteToFile(formatted_message);
}

//+------------------------------------------------------------------+
//| Log trade action                                                 |
//+------------------------------------------------------------------+
void CLogger::LogTrade(const string symbol, const string action, const string details = "")
{
   string message = StringFormat("TRADE %s: %s", symbol, action);
   if(details != "")
      message += " - " + details;
   
   Info(message, "LogTrade");
}

//+------------------------------------------------------------------+
//| Log signal                                                       |
//+------------------------------------------------------------------+
void CLogger::LogSignal(const string symbol, ENUM_SIGNAL_DIRECTION signal, const string reason = "")
{
   string signal_text = GetSignalText(signal);
   string message = StringFormat("SIGNAL %s: %s", symbol, signal_text);
   if(reason != "")
      message += " (" + reason + ")";
   
   Info(message, "LogSignal");
}

//+------------------------------------------------------------------+
//| Log indicator values                                             |
//+------------------------------------------------------------------+
void CLogger::LogIndicator(const string symbol, const string indicator_name, const string values)
{
   string message = StringFormat("INDICATOR %s %s: %s", symbol, indicator_name, values);
   Debug(message, "LogIndicator");
}

//+------------------------------------------------------------------+
//| Log performance metrics                                          |
//+------------------------------------------------------------------+
void CLogger::LogPerformance(const string operation, uint execution_time_ms)
{
   string message = StringFormat("PERFORMANCE %s: %d ms", operation, execution_time_ms);
   
   if(execution_time_ms > 1000)
      Warning(message, "LogPerformance");
   else
      Debug(message, "LogPerformance");
}

//+------------------------------------------------------------------+
//| Log position action                                              |
//+------------------------------------------------------------------+
void CLogger::LogPosition(const string symbol, const string action, double price, double volume, const string comment = "")
{
   string message = StringFormat("POSITION %s %s: %.5f @ %.2f", symbol, action, volume, price);
   if(comment != "")
      message += " (" + comment + ")";
      
   Info(message, "LogPosition");
}

//+------------------------------------------------------------------+
//| Standard print replacement                                       |
//+------------------------------------------------------------------+
void CLogger::Print(const string message)
{
   Info(message);
}



//+------------------------------------------------------------------+
//| Log double array                                                 |
//+------------------------------------------------------------------+
void CLogger::LogArray(const string array_name, const double& array[], int start_index = 0, int count = -1)
{
   int array_size = ArraySize(array);
   if(count < 0) count = array_size - start_index;
   
   string message = StringFormat("ARRAY %s[%d-%d]: ", array_name, start_index, start_index + count - 1);
   
   for(int i = start_index; i < start_index + count && i < array_size; i++)
   {
      if(i > start_index) message += ", ";
      message += DoubleToString(array[i], 5);
   }
   
   Debug(message, "LogArray");
}

//+------------------------------------------------------------------+
//| Log string array                                                 |
//+------------------------------------------------------------------+
void CLogger::LogArray(const string array_name, const string& array[], int start_index = 0, int count = -1)
{
   int array_size = ArraySize(array);
   if(count < 0) count = array_size - start_index;
   
   string message = StringFormat("ARRAY %s[%d-%d]: ", array_name, start_index, start_index + count - 1);
   
   for(int i = start_index; i < start_index + count && i < array_size; i++)
   {
      if(i > start_index) message += ", ";
      message += array[i];
   }
   
   Debug(message, "LogArray");
}

//+------------------------------------------------------------------+
//| Flush log file                                                   |
//+------------------------------------------------------------------+
bool CLogger::FlushLogFile()
{
   if(m_file_handle != INVALID_HANDLE)
   {
      FileFlush(m_file_handle);
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Clear log file                                                   |
//+------------------------------------------------------------------+
bool CLogger::ClearLogFile()
{
   if(m_file_handle != INVALID_HANDLE)
   {
      FileClose(m_file_handle);
      
      // Reopen file in write mode (this clears the content)
      m_file_handle = FileOpen(StringFormat("%s_%s.log", m_log_prefix, TimeToString(TimeCurrent(), TIME_DATE)),
                               FILE_WRITE | FILE_TXT | FILE_ANSI);
      
      if(m_file_handle != INVALID_HANDLE)
      {
         string header = StringFormat("=== %s Log Cleared and Restarted ===\n", m_log_prefix);
         FileWrite(m_file_handle, header);
         FileFlush(m_file_handle);
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Get log file size                                                |
//+------------------------------------------------------------------+
long CLogger::GetLogFileSize()
{
   if(m_file_handle != INVALID_HANDLE)
      return (long)FileSize(m_file_handle);
   return -1;
}

//+------------------------------------------------------------------+
//| Global Logger Instance                                           |
//+------------------------------------------------------------------+
static CLogger g_Logger;

// Global convenience functions
void LogDebug(const string message, const string function_name = "")
{
   g_Logger.Debug(message, function_name);
}

void LogInfo(const string message, const string function_name = "")
{
   g_Logger.Info(message, function_name);
}

void LogWarning(const string message, const string function_name = "")
{
   g_Logger.Warning(message, function_name);
}

void LogError(const string message, const string function_name = "")
{
   g_Logger.Error(message, function_name);
}

void LogCritical(const string message, const string function_name = "")
{
   g_Logger.Critical(message, function_name);
}

// Logger instance is available as g_Logger
// Use g_Logger.Info(), g_Logger.Error(), etc. instead of Print()

//+------------------------------------------------------------------+
