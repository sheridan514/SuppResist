//+------------------------------------------------------------------+
//| SuppResist.mqh                                                   |
//| Copyright 2024, SuppResist                                       |
//| https://www.mql5.com                                             |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, SuppResist"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Includes                                                         |
//+------------------------------------------------------------------+
#include "Types.mqh"

//+------------------------------------------------------------------+
//| Global Constants                                                 |
//+------------------------------------------------------------------+

// EA identification
#define EA_NAME                "SuppResist"
#define EA_VERSION             "1.0"
#define EA_DESCRIPTION         "Support/Resistance Dashboard & Filter EA"

// Magic numbers for position identification
#define MAGIC_NUMBER_BASE      20241201
#define MAGIC_TREND_STRATEGY   (MAGIC_NUMBER_BASE + 1)
#define MAGIC_RANGE_STRATEGY   (MAGIC_NUMBER_BASE + 2)

// Timer intervals (milliseconds)
#define TIMER_INTERVAL_MS      1000    // Main timer interval
#define UPDATE_INTERVAL_MS     5000    // Dashboard update interval
#define SIGNAL_CHECK_INTERVAL_MS 2000  // Signal check interval

// File paths and names
#define SETTINGS_FILE_NAME     "SuppResist_Settings.set"
#define LOG_FILE_NAME          "SuppResist.log"

// Chart objects naming
#define CHART_OBJECT_PREFIX    "SR_"
#define PANEL_OBJECT_PREFIX    (CHART_OBJECT_PREFIX + "Panel_")
#define SR_LINE_PREFIX         (CHART_OBJECT_PREFIX + "SR_")
#define TREND_LINE_PREFIX      (CHART_OBJECT_PREFIX + "Trend_")

//+------------------------------------------------------------------+
//| Utility Functions                                               |
//+------------------------------------------------------------------+

// String utility functions
string StringArrayToString(string &arr[], string separator)
{
   string result = "";
   int count = ArraySize(arr);
   
   for(int i = 0; i < count; i++)
   {
      if(i > 0) result += separator;
      result += arr[i];
   }
   
   return result;
}

int StringToStringArray(string str, string &arr[], string separator)
{
   ArrayFree(arr);
   
   if(StringLen(str) == 0)
      return 0;
   
   string temp_input = str;
   StringReplace(temp_input, " ", ""); // Remove spaces
   
   int pos = 0;
   int next_pos = 0;
   int count = 0;
   
   // Count elements
   string temp = temp_input;
   while((pos = StringFind(temp, separator)) >= 0)
   {
      count++;
      temp = StringSubstr(temp, pos + StringLen(separator));
   }
   if(StringLen(temp) > 0) count++;
   
   if(count == 0) return 0;
   
   ArrayResize(arr, count);
   
   // Parse elements
   pos = 0;
   for(int i = 0; i < count; i++)
   {
      next_pos = StringFind(temp_input, separator, pos);
      
      if(next_pos >= 0)
      {
         arr[i] = StringSubstr(temp_input, pos, next_pos - pos);
         pos = next_pos + StringLen(separator);
      }
      else
      {
         arr[i] = StringSubstr(temp_input, pos);
      }
      
      // Validate symbol
      if(StringLen(arr[i]) < 3)
      {
         g_Logger.Warning(StringFormat("SuppResist: Invalid symbol: %s", arr[i]));
         ArrayRemove(arr, i, 1);
         i--;
         count--;
      }
   }
   
   return count;
}

// Time utility functions
bool IsNewBar(const string symbol, ENUM_TIMEFRAMES timeframe)
{
   static datetime last_time[];
   static string last_symbols[];
   
   int symbol_index = -1;
   int symbols_count = ArraySize(last_symbols);
   
   // Find symbol index
   for(int i = 0; i < symbols_count; i++)
   {
      if(last_symbols[i] == symbol)
      {
         symbol_index = i;
         break;
      }
   }
   
   // Add new symbol if not found
   if(symbol_index == -1)
   {
      symbol_index = symbols_count;
      ArrayResize(last_symbols, symbols_count + 1);
      ArrayResize(last_time, symbols_count + 1);
      last_symbols[symbol_index] = symbol;
      last_time[symbol_index] = 0;
   }
   
   datetime current_time = iTime(symbol, timeframe, 0);
   
   if(current_time > last_time[symbol_index])
   {
      last_time[symbol_index] = current_time;
      return true;
   }
   
   return false;
}

string TimeToString(datetime time, bool show_seconds = false)
{
   if(show_seconds)
      return TimeToString(time, TIME_DATE | TIME_SECONDS);
   else
      return TimeToString(time, TIME_DATE | TIME_MINUTES);
}

// Price utility functions
double NormalizePrice(const string symbol, double price)
{
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   return NormalizeDouble(price, digits);
}

double GetPointValue(const string symbol)
{
   return SymbolInfoDouble(symbol, SYMBOL_POINT);
}

double GetTickSize(const string symbol)
{
   double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tick_size == 0)
      tick_size = GetPointValue(symbol);
   return tick_size;
}

// Volume utility functions
double NormalizeVolume(const string symbol, double volume)
{
   double min_volume = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double max_volume = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double volume_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   
   if(volume < min_volume)
      volume = min_volume;
   if(volume > max_volume)
      volume = max_volume;
      
   if(volume_step > 0)
      volume = MathRound(volume / volume_step) * volume_step;
   
   return volume;
}

// Color utility functions
color GetSignalColor(ENUM_SIGNAL_DIRECTION signal)
{
   switch(signal)
   {
      case SIGNAL_BUY:  return DEFAULT_BUY_COLOR;
      case SIGNAL_SELL: return DEFAULT_SELL_COLOR;
      default:          return DEFAULT_NEUTRAL_COLOR;
   }
}

string GetSignalText(ENUM_SIGNAL_DIRECTION signal)
{
   switch(signal)
   {
      case SIGNAL_BUY:  return "BUY";
      case SIGNAL_SELL: return "SELL";
      default:          return "—";
   }
}

string GetStrategyText(ENUM_STRATEGY_TYPE strategy)
{
   switch(strategy)
   {
      case STRATEGY_TREND: return "TREND";
      case STRATEGY_RANGE: return "RANGE";
      default:             return "NONE";
   }
}

string GetGridStatusText(ENUM_GRID_STATUS status)
{
   switch(status)
   {
      case GRID_ACTIVE:   return "Active";
      case GRID_RECOVERY: return "Recover";
      default:            return "None";
   }
}

// Math utility functions
double CalculatePercentage(double value, double total)
{
   if(total == 0) return 0;
   return (value / total) * 100.0;
}

bool IsInRange(double value, double min_val, double max_val)
{
   return (value >= min_val && value <= max_val);
}

// Validation functions
bool IsValidSymbol(const string symbol)
{
   if(StringLen(symbol) < 3) return false;
   
   // Check if symbol exists in Market Watch
   if(SymbolSelect(symbol, true))
   {
      // Check if we can get basic symbol info
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      return (point > 0);
   }
   
   return false;
}

bool IsMarketOpen(const string symbol)
{
   datetime current_time = TimeCurrent();
   datetime session_start, session_end;
   
   if(SymbolInfoSessionTrade(symbol, MONDAY, 0, session_start, session_end))
   {
      // This is a simplified check - in real implementation you'd want to check
      // all trading sessions for the current day of week
      return true;
   }
   
   return false;
}

// Array utility functions
template<typename T>
int FindInArray(const T& array[], const T value)
{
   int size = ArraySize(array);
   for(int i = 0; i < size; i++)
   {
      if(array[i] == value)
         return i;
   }
   return -1;
}

template<typename T>
void ArraySortAscending(T& array[])
{
   ArraySort(array);
}

// Performance measurement
class CPerformanceMeter
{
private:
   uint m_start_time;
   string m_operation_name;
   
public:
   CPerformanceMeter(const string operation_name)
   {
      m_operation_name = operation_name;
      m_start_time = GetTickCount();
   }
   
   ~CPerformanceMeter()
   {
      uint elapsed = GetTickCount() - m_start_time;
      if(elapsed > 100) // Log only if operation takes more than 100ms
      {
         g_Logger.Info(StringFormat("SuppResist Performance: %s took %dms", m_operation_name, elapsed));
      }
   }
};

#define MEASURE_PERFORMANCE(operation_name) CPerformanceMeter __perf(operation_name)

//+------------------------------------------------------------------+
