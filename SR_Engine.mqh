//+------------------------------------------------------------------+
//| SR_Engine.mqh                                                    |
//| Copyright 2024, SuppResist                                       |
//| https://www.mql5.com                                             |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, SuppResist"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "SuppResist.mqh"
#include "Logger.mqh"

//+------------------------------------------------------------------+
//| Support/Resistance Level Structure                              |
//+------------------------------------------------------------------+
struct SRLevel
{
   // Default constructor
   SRLevel()
   {
      Reset();
   }
   
   // Copy constructor
   SRLevel(const SRLevel &other)
   {
      price = other.price;
      touches = other.touches;
      strength = other.strength;
      first_touch = other.first_touch;
      last_touch = other.last_touch;
      timeframe = other.timeframe;
      is_support = other.is_support;
      is_resistance = other.is_resistance;
      ai_confidence = other.ai_confidence;
      is_active = other.is_active;
      consecutive_touches = other.consecutive_touches;
   }
   
   void Reset()
   {
      price = 0.0;
      touches = 0;
      strength = 0;
      first_touch = 0;
      last_touch = 0;
      timeframe = PERIOD_CURRENT;
      is_support = false;
      is_resistance = false;
      ai_confidence = 0.0;
      is_active = false;
      consecutive_touches = 0;
   }

   double            price;                         // Price level
   int               touches;                       // Number of touches
   int               strength;                      // Calculated strength
   datetime          first_touch;                   // First touch time
   datetime          last_touch;                    // Last touch time
   ENUM_TIMEFRAMES   timeframe;                     // Source timeframe
   bool              is_support;                    // Is support level
   bool              is_resistance;                 // Is resistance level
   double            ai_confidence;                 // AI confidence (0-1) if available
   bool              is_active;                     // Is currently active level
   int               consecutive_touches;           // Consecutive touches without break
};

//+------------------------------------------------------------------+
//| CSR_Engine Class - Support/Resistance Detection Engine          |
//+------------------------------------------------------------------+
class CSR_Engine
{
private:
   // Settings and logger
   SSettings         m_settings;                    // Engine settings
   bool              m_initialized;                 // Initialization flag
   
   // S&R Levels storage
   SRLevel           m_daily_levels[];              // Daily timeframe S&R levels
   SRLevel           m_h4_levels[];                 // H4 timeframe S&R levels  
   SRLevel           m_h1_levels[];                 // H1 timeframe S&R levels
   
   int               m_daily_count;                 // Count of daily levels
   int               m_h4_count;                    // Count of H4 levels
   int               m_h1_count;                    // Count of H1 levels
   
   // Symbol management
   string            m_symbols[];                   // Monitored symbols
   int               m_symbols_count;               // Number of symbols
   
   // Internal calculation parameters
   double            m_proximity_points[];          // Proximity in points for each symbol
   
   // Private methods for S&R detection
   bool DetectPivotPoints(const string symbol, ENUM_TIMEFRAMES timeframe, 
                          double& highs[], double& lows[], datetime& times[]);
   
   bool AnalyzeLevel(const string symbol, double level_price, ENUM_TIMEFRAMES timeframe,
                     int& touches, datetime& first_touch, datetime& last_touch,
                     bool& is_support, bool& is_resistance);
   
   int CalculateLevelStrength(int touches, ENUM_TIMEFRAMES timeframe, bool has_recent_touch);
   
   bool IsNearLevel(double price1, double price2, double proximity_points);
   
   void SortLevelsByStrength(SRLevel& levels[], int count);
   
   bool ValidateLevel(const SRLevel& level, double current_price, double min_distance);
   
   // Timeframe-specific scanning methods
   void ScanTimeframeLevels(const string symbol, ENUM_TIMEFRAMES timeframe);
   
   void UpdateDailyLevels(const string symbol);
   void UpdateH4Levels(const string symbol);
   void UpdateH1Levels(const string symbol);
   
   // Level management
   void AddOrUpdateLevel(SRLevel& levels[], int& count, const SRLevel& new_level);
   void CleanupOldLevels(SRLevel& levels[], int& count);
   void MergeSimilarLevels(SRLevel& levels[], int& count, double proximity);
   
   // Signal analysis helpers
   bool CheckPriceActionSetup(const string symbol, const SRLevel& level, ENUM_SIGNAL_DIRECTION expected_direction);
   bool CheckVolumeConfirmation(const string symbol, const SRLevel& level);
   bool CheckMomentumDivergence(const string symbol, const SRLevel& level);
   
   // Utility methods
   double GetProximityPoints(const string symbol);
   int GetTimeframeMultiplier(ENUM_TIMEFRAMES timeframe);
   string GetLevelDescription(const SRLevel& level);
   
public:
   // Constructor/Destructor
   CSR_Engine();
   ~CSR_Engine();
   
   // Initialization
   bool Initialize(const SSettings& settings);
   void Deinitialize();
   
   // Main S&R detection methods
   void ScanAndUpdateLevels(const string symbol);
   void ScanAllSymbols();
   
   // Level retrieval methods
   SRLevel GetStrongestSR(const string symbol, double current_price, bool is_support_search, 
                          double max_distance = 0.0);
   
   bool GetNearestSRLevels(const string symbol, double current_price, 
                           SRLevel& nearest_support, SRLevel& nearest_resistance,
                           double max_distance = 0.0);
   
   // Get levels by timeframe
   void GetDailyLevels(const string symbol, SRLevel& levels[], int& count);
   void GetH4Levels(const string symbol, SRLevel& levels[], int& count);
   void GetH1Levels(const string symbol, SRLevel& levels[], int& count);
   void GetAllLevels(const string symbol, SRLevel& levels[], int& count);
   
   // Signal generation
   ENUM_SIGNAL_DIRECTION CheckSRSignal(const string symbol);
   ENUM_SIGNAL_DIRECTION CheckBounceSetup(const string symbol);
   ENUM_SIGNAL_DIRECTION CheckBreakoutSetup(const string symbol);
   
   // Level analysis
   double GetLevelStrength(const string symbol, double price_level, ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT);
   bool IsKeyLevel(const string symbol, double price_level);
   double GetCombinedStrength(const string symbol, double price_level);
   
   // AI integration (if enabled)
   bool IntegrateAILevels(const string symbol, const SRLevel& ai_level);
   void ApplyAIConfidence(const string symbol);
   
   // Price level utilities
   double GetNextSupportLevel(const string symbol, double current_price);
   double GetNextResistanceLevel(const string symbol, double current_price);
   double GetOptimalSL(const string symbol, double entry_price, ENUM_SIGNAL_DIRECTION direction);
   double GetOptimalTP(const string symbol, double entry_price, ENUM_SIGNAL_DIRECTION direction);
   
   // Information methods
   int GetActiveLevelsCount(const string symbol);
   double GetAverageStrength(const string symbol);
   
   // Debug and analysis
   void PrintAllLevels(const string symbol);
   void PrintLevelStatistics(const string symbol);
   string GetSRAnalysisReport(const string symbol);
   
   // Validation and health check
   bool ValidateSymbolData(const string symbol);
   bool IsMarketSuitableForSR(const string symbol);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSR_Engine::CSR_Engine() : m_initialized(false), 
                           m_daily_count(0), 
                           m_h4_count(0), 
                           m_h1_count(0),
                           m_symbols_count(0)
{
   ZeroMemory(m_settings);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSR_Engine::~CSR_Engine()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize S&R Engine                                           |
//+------------------------------------------------------------------+
bool CSR_Engine::Initialize(const SSettings& settings)
{
   if(m_initialized)
      return true;
   
   m_settings = settings;
   m_symbols_count = settings.symbols_count;
   
   if(m_symbols_count <= 0)
   {
      LogError("No symbols provided for S&R engine", "CSR_Engine::Initialize");
      return false;
   }
   
   // Copy symbols
   ArrayResize(m_symbols, m_symbols_count);
   ArrayResize(m_proximity_points, m_symbols_count);
   
   for(int i = 0; i < m_symbols_count; i++)
   {
      m_symbols[i] = settings.symbols[i];
      m_proximity_points[i] = GetProximityPoints(m_symbols[i]);
   }
   
   // Initialize S&R levels arrays
   ArrayResize(m_daily_levels, 500);  // Max levels per timeframe
   ArrayResize(m_h4_levels, 500);
   ArrayResize(m_h1_levels, 500);
   
   // Initialize all levels to inactive
   for(int i = 0; i < 500; i++)
   {
      ZeroMemory(m_daily_levels[i]);
      ZeroMemory(m_h4_levels[i]);
      ZeroMemory(m_h1_levels[i]);
      
      m_daily_levels[i].is_active = false;
      m_h4_levels[i].is_active = false;
      m_h1_levels[i].is_active = false;
   }
   
   m_initialized = true;
   
   LogInfo(StringFormat("S&R Engine initialized for %d symbols", m_symbols_count), "CSR_Engine::Initialize");
   
   // Perform initial scan of all symbols
   ScanAllSymbols();
   
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize S&R Engine                                         |
//+------------------------------------------------------------------+
void CSR_Engine::Deinitialize()
{
   if(!m_initialized)
      return;
   
   ArrayFree(m_symbols);
   ArrayFree(m_proximity_points);
   ArrayFree(m_daily_levels);
   ArrayFree(m_h4_levels);
   ArrayFree(m_h1_levels);
   
   m_symbols_count = 0;
   m_daily_count = 0;
   m_h4_count = 0;
   m_h1_count = 0;
   m_initialized = false;
   
   LogInfo("S&R Engine deinitialized", "CSR_Engine::Deinitialize");
}

//+------------------------------------------------------------------+
//| Scan and update S&R levels for symbol                           |
//+------------------------------------------------------------------+
void CSR_Engine::ScanAndUpdateLevels(const string symbol)
{
   if(!m_initialized)
      return;
   
   MEASURE_PERFORMANCE(StringFormat("ScanSR_%s", symbol));
   
   LogDebug(StringFormat("Scanning S&R levels for %s", symbol), "ScanAndUpdateLevels");
   
   // Update levels on all timeframes
   UpdateDailyLevels(symbol);
   UpdateH4Levels(symbol);
   UpdateH1Levels(symbol);
   
   // Cleanup old and invalid levels
   CleanupOldLevels(m_daily_levels, m_daily_count);
   CleanupOldLevels(m_h4_levels, m_h4_count);
   CleanupOldLevels(m_h1_levels, m_h1_count);
   
   // Merge similar levels
   double proximity = GetProximityPoints(symbol);
   MergeSimilarLevels(m_daily_levels, m_daily_count, proximity * 2.0);
   MergeSimilarLevels(m_h4_levels, m_h4_count, proximity * 1.5);
   MergeSimilarLevels(m_h1_levels, m_h1_count, proximity);
   
   LogDebug(StringFormat("S&R scan complete: %s - Daily:%d, H4:%d, H1:%d", 
                         symbol, m_daily_count, m_h4_count, m_h1_count), "ScanAndUpdateLevels");
}

//+------------------------------------------------------------------+
//| Scan all symbols                                                 |
//+------------------------------------------------------------------+
void CSR_Engine::ScanAllSymbols()
{
   if(!m_initialized)
      return;
   
   LogInfo("Scanning S&R levels for all symbols", "ScanAllSymbols");
   
   for(int i = 0; i < m_symbols_count; i++)
   {
      ScanAndUpdateLevels(m_symbols[i]);
   }
   
   LogInfo("All symbols S&R scan completed", "ScanAllSymbols");
}

//+------------------------------------------------------------------+
//| Update Daily timeframe levels                                   |
//+------------------------------------------------------------------+
void CSR_Engine::UpdateDailyLevels(const string symbol)
{
   ScanTimeframeLevels(symbol, PERIOD_D1);
}

//+------------------------------------------------------------------+
//| Update H4 timeframe levels                                      |
//+------------------------------------------------------------------+
void CSR_Engine::UpdateH4Levels(const string symbol)
{
   ScanTimeframeLevels(symbol, PERIOD_H4);
}

//+------------------------------------------------------------------+
//| Update H1 timeframe levels                                      |
//+------------------------------------------------------------------+
void CSR_Engine::UpdateH1Levels(const string symbol)
{
   ScanTimeframeLevels(symbol, PERIOD_H1);
}

//+------------------------------------------------------------------+
//| Scan timeframe for S&R levels                                   |
//+------------------------------------------------------------------+
void CSR_Engine::ScanTimeframeLevels(const string symbol, ENUM_TIMEFRAMES timeframe)
{
   int lookback_bars;
   
   // Determine lookback based on timeframe
   switch(timeframe)
   {
      case PERIOD_D1: lookback_bars = 200; break;  // InpSR_LookbackBars_Daily
      case PERIOD_H4: lookback_bars = 300; break;  // InpSR_LookbackBars_H4  
      case PERIOD_H1: lookback_bars = 400; break;  // InpSR_LookbackBars_H1
      default: lookback_bars = 200; break;
   }
   
   // Get price data
   double highs[], lows[], closes[];
   datetime times[];
   
   if(CopyHigh(symbol, timeframe, 0, lookback_bars, highs) <= 0 ||
      CopyLow(symbol, timeframe, 0, lookback_bars, lows) <= 0 ||
      CopyClose(symbol, timeframe, 0, lookback_bars, closes) <= 0 ||
      CopyTime(symbol, timeframe, 0, lookback_bars, times) <= 0)
   {
      LogError(StringFormat("Failed to get price data for %s %s", symbol, EnumToString(timeframe)), "ScanTimeframeLevels");
      return;
   }
   
   int data_count = ArraySize(highs);
   if(data_count < 20) return;
   
   // Detect pivot points
   double pivot_highs[], pivot_lows[];
   datetime pivot_times[];
   
   if(!DetectPivotPoints(symbol, timeframe, pivot_highs, pivot_lows, pivot_times))
      return;
   
   // Analyze potential S&R levels from pivot points
   int pivot_count = ArraySize(pivot_highs);
   
   for(int i = 0; i < pivot_count; i++)
   {
      // Analyze high as potential resistance
      if(pivot_highs[i] > 0)
      {
         SRLevel level;
         ZeroMemory(level);
         
         if(AnalyzeLevel(symbol, pivot_highs[i], timeframe, level.touches, 
                        level.first_touch, level.last_touch, level.is_support, level.is_resistance))
         {
            if(level.touches >= 2) // InpSR_MinTouches
            {
               level.price = pivot_highs[i];
               level.timeframe = timeframe;
               level.strength = CalculateLevelStrength(level.touches, timeframe, true);
               level.is_active = true;
               level.ai_confidence = 0.0;
               
               // Add to appropriate array
               if(timeframe == PERIOD_D1)
                  AddOrUpdateLevel(m_daily_levels, m_daily_count, level);
               else if(timeframe == PERIOD_H4)
                  AddOrUpdateLevel(m_h4_levels, m_h4_count, level);
               else if(timeframe == PERIOD_H1)
                  AddOrUpdateLevel(m_h1_levels, m_h1_count, level);
            }
         }
      }
      
      // Analyze low as potential support
      if(pivot_lows[i] > 0)
      {
         SRLevel level;
         ZeroMemory(level);
         
         if(AnalyzeLevel(symbol, pivot_lows[i], timeframe, level.touches,
                        level.first_touch, level.last_touch, level.is_support, level.is_resistance))
         {
            if(level.touches >= 2) // InpSR_MinTouches
            {
               level.price = pivot_lows[i];
               level.timeframe = timeframe;
               level.strength = CalculateLevelStrength(level.touches, timeframe, true);
               level.is_active = true;
               level.ai_confidence = 0.0;
               
               // Add to appropriate array
               if(timeframe == PERIOD_D1)
                  AddOrUpdateLevel(m_daily_levels, m_daily_count, level);
               else if(timeframe == PERIOD_H4)
                  AddOrUpdateLevel(m_h4_levels, m_h4_count, level);
               else if(timeframe == PERIOD_H1)
                  AddOrUpdateLevel(m_h1_levels, m_h1_count, level);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Detect pivot points in price data                               |
//+------------------------------------------------------------------+
bool CSR_Engine::DetectPivotPoints(const string symbol, ENUM_TIMEFRAMES timeframe, 
                                   double& highs[], double& lows[], datetime& times[])
{
   int lookback_bars;
   
   switch(timeframe)
   {
      case PERIOD_D1: lookback_bars = 200; break;
      case PERIOD_H4: lookback_bars = 300; break;
      case PERIOD_H1: lookback_bars = 400; break;
      default: lookback_bars = 200; break;
   }
   
   double high_data[], low_data[];
   datetime time_data[];
   
   if(CopyHigh(symbol, timeframe, 0, lookback_bars, high_data) <= 0 ||
      CopyLow(symbol, timeframe, 0, lookback_bars, low_data) <= 0 ||
      CopyTime(symbol, timeframe, 0, lookback_bars, time_data) <= 0)
      return false;
   
   int data_count = ArraySize(high_data);
   if(data_count < 10) return false;
   
   // Detect pivot highs and lows
   int pivot_period = 5; // Look 5 bars left and right
   int max_pivots = 100;
   
   ArrayResize(highs, max_pivots);
   ArrayResize(lows, max_pivots);
   ArrayResize(times, max_pivots);
   ArrayInitialize(highs, 0.0);
   ArrayInitialize(lows, 0.0);
   
   int pivot_count = 0;
   
   for(int i = pivot_period; i < data_count - pivot_period && pivot_count < max_pivots; i++)
   {
      bool is_pivot_high = true;
      bool is_pivot_low = true;
      
      // Check if current bar is pivot high
      for(int j = i - pivot_period; j <= i + pivot_period; j++)
      {
         if(j != i && high_data[j] >= high_data[i])
         {
            is_pivot_high = false;
            break;
         }
      }
      
      // Check if current bar is pivot low
      for(int j = i - pivot_period; j <= i + pivot_period; j++)
      {
         if(j != i && low_data[j] <= low_data[i])
         {
            is_pivot_low = false;
            break;
         }
      }
      
      if(is_pivot_high)
      {
         highs[pivot_count] = high_data[i];
         lows[pivot_count] = 0.0;
         times[pivot_count] = time_data[i];
         pivot_count++;
      }
      else if(is_pivot_low)
      {
         highs[pivot_count] = 0.0;
         lows[pivot_count] = low_data[i];
         times[pivot_count] = time_data[i];
         pivot_count++;
      }
   }
   
   // Resize arrays to actual count
   ArrayResize(highs, pivot_count);
   ArrayResize(lows, pivot_count);
   ArrayResize(times, pivot_count);
   
   LogDebug(StringFormat("Detected %d pivot points for %s %s", pivot_count, symbol, EnumToString(timeframe)), "DetectPivotPoints");
   
   return (pivot_count > 0);
}

//+------------------------------------------------------------------+
//| Analyze level for touches and validity                          |
//+------------------------------------------------------------------+
bool CSR_Engine::AnalyzeLevel(const string symbol, double level_price, ENUM_TIMEFRAMES timeframe,
                              int& touches, datetime& first_touch, datetime& last_touch,
                              bool& is_support, bool& is_resistance)
{
   touches = 0;
   first_touch = 0;
   last_touch = 0;
   is_support = false;
   is_resistance = false;
   
   int lookback_bars;
   switch(timeframe)
   {
      case PERIOD_D1: lookback_bars = 200; break;
      case PERIOD_H4: lookback_bars = 300; break;
      case PERIOD_H1: lookback_bars = 400; break;
      default: lookback_bars = 200; break;
   }
   
   double high_data[], low_data[], close_data[];
   datetime time_data[];
   
   if(CopyHigh(symbol, timeframe, 0, lookback_bars, high_data) <= 0 ||
      CopyLow(symbol, timeframe, 0, lookback_bars, low_data) <= 0 ||
      CopyClose(symbol, timeframe, 0, lookback_bars, close_data) <= 0 ||
      CopyTime(symbol, timeframe, 0, lookback_bars, time_data) <= 0)
      return false;
   
   double proximity = GetProximityPoints(symbol);
   int support_touches = 0;
   int resistance_touches = 0;
   
   // Count touches
   for(int i = 0; i < ArraySize(high_data); i++)
   {
      bool touched_as_support = false;
      bool touched_as_resistance = false;
      
      // Check if low touched the level (support)
      if(IsNearLevel(low_data[i], level_price, proximity))
      {
         support_touches++;
         touched_as_support = true;
      }
      
      // Check if high touched the level (resistance)  
      if(IsNearLevel(high_data[i], level_price, proximity))
      {
         resistance_touches++;
         touched_as_resistance = true;
      }
      
      // Update first/last touch times
      if(touched_as_support || touched_as_resistance)
      {
         if(first_touch == 0)
            first_touch = time_data[i];
         last_touch = time_data[i];
      }
   }
   
   touches = MathMax(support_touches, resistance_touches);
   is_support = (support_touches >= 2);
   is_resistance = (resistance_touches >= 2);
   
   return (touches >= 2);
}

//+------------------------------------------------------------------+
//| Calculate level strength                                         |
//+------------------------------------------------------------------+
int CSR_Engine::CalculateLevelStrength(int touches, ENUM_TIMEFRAMES timeframe, bool has_recent_touch)
{
   int timeframe_multiplier = GetTimeframeMultiplier(timeframe);
   int base_strength = touches * timeframe_multiplier;
   
   // Bonus for recent touches
   if(has_recent_touch)
      base_strength += timeframe_multiplier / 2;
   
   return base_strength;
}

//+------------------------------------------------------------------+
//| Get timeframe multiplier for strength calculation               |
//+------------------------------------------------------------------+
int CSR_Engine::GetTimeframeMultiplier(ENUM_TIMEFRAMES timeframe)
{
   switch(timeframe)
   {
      case PERIOD_D1: return 5;  // InpSR_StrengthMultiplier_Daily
      case PERIOD_H4: return 3;  // InpSR_StrengthMultiplier_H4
      case PERIOD_H1: return 1;  // InpSR_StrengthMultiplier_H1
      default: return 1;
   }
}

//+------------------------------------------------------------------+
//| Check if price is near level                                    |
//+------------------------------------------------------------------+
bool CSR_Engine::IsNearLevel(double price1, double price2, double proximity_points)
{
   return (MathAbs(price1 - price2) <= proximity_points);
}

//+------------------------------------------------------------------+
//| Get proximity in points for symbol                              |
//+------------------------------------------------------------------+
double CSR_Engine::GetProximityPoints(const string symbol)
{
   double point_value = SymbolInfoDouble(symbol, SYMBOL_POINT);
   return 10.0 * point_value; // InpSR_ProximityPips converted to points
}

//+------------------------------------------------------------------+
//| Get strongest S&R level                                         |
//+------------------------------------------------------------------+
SRLevel CSR_Engine::GetStrongestSR(const string symbol, double current_price, bool is_support_search, double max_distance = 0.0)
{
   SRLevel strongest_level;
   ZeroMemory(strongest_level);
   
   if(!m_initialized)
      return strongest_level;
   
   int max_strength = 0;
   double search_distance = (max_distance > 0) ? max_distance : GetProximityPoints(symbol) * 50;
   
   // Search Daily levels
   for(int i = 0; i < m_daily_count; i++)
   {
      if(!m_daily_levels[i].is_active)
         continue;
         
      // Check distance
      if(MathAbs(m_daily_levels[i].price - current_price) > search_distance)
         continue;
         
      // Check if it's the type we're looking for
      if(is_support_search)
      {
         if(!m_daily_levels[i].is_support || m_daily_levels[i].price >= current_price)
            continue;
      }
      else
      {
         if(!m_daily_levels[i].is_resistance || m_daily_levels[i].price <= current_price)
            continue;
      }
      
      // Check if stronger than current best
      if(m_daily_levels[i].strength > max_strength)
      {
         max_strength = m_daily_levels[i].strength;
         strongest_level = m_daily_levels[i];
      }
   }
   
   // Search H4 levels
   for(int i = 0; i < m_h4_count; i++)
   {
      if(!m_h4_levels[i].is_active)
         continue;
         
      // Check distance
      if(MathAbs(m_h4_levels[i].price - current_price) > search_distance)
         continue;
         
      // Check if it's the type we're looking for
      if(is_support_search)
      {
         if(!m_h4_levels[i].is_support || m_h4_levels[i].price >= current_price)
            continue;
      }
      else
      {
         if(!m_h4_levels[i].is_resistance || m_h4_levels[i].price <= current_price)
            continue;
      }
      
      // Check if stronger than current best
      if(m_h4_levels[i].strength > max_strength)
      {
         max_strength = m_h4_levels[i].strength;
         strongest_level = m_h4_levels[i];
      }
   }
   
   // Search H1 levels
   for(int i = 0; i < m_h1_count; i++)
   {
      if(!m_h1_levels[i].is_active)
         continue;
         
      // Check distance
      if(MathAbs(m_h1_levels[i].price - current_price) > search_distance)
         continue;
         
      // Check if it's the type we're looking for
      if(is_support_search)
      {
         if(!m_h1_levels[i].is_support || m_h1_levels[i].price >= current_price)
            continue;
      }
      else
      {
         if(!m_h1_levels[i].is_resistance || m_h1_levels[i].price <= current_price)
            continue;
      }
      
      // Check if stronger than current best
      if(m_h1_levels[i].strength > max_strength)
      {
         max_strength = m_h1_levels[i].strength;
         strongest_level = m_h1_levels[i];
      }
   }
   
   return strongest_level;
}

//+------------------------------------------------------------------+
//| Add or update level in array                                    |
//+------------------------------------------------------------------+
void CSR_Engine::AddOrUpdateLevel(SRLevel& levels[], int& count, const SRLevel& new_level)
{
   double proximity = GetProximityPoints(""); // Use default proximity
   
   // Check if similar level already exists
   for(int i = 0; i < count; i++)
   {
      if(IsNearLevel(levels[i].price, new_level.price, proximity))
      {
         // Update existing level
         if(new_level.strength > levels[i].strength)
         {
            levels[i] = new_level;
         }
         return;
      }
   }
   
   // Add new level if we have space
   if(count < ArraySize(levels))
   {
      levels[count] = new_level;
      count++;
   }
}

//+------------------------------------------------------------------+
//| Cleanup old levels                                              |
//+------------------------------------------------------------------+
void CSR_Engine::CleanupOldLevels(SRLevel& levels[], int& count)
{
   datetime cutoff_time = TimeCurrent() - (7 * 24 * 3600); // 1 week old
   
   for(int i = count - 1; i >= 0; i--)
   {
      if(levels[i].last_touch < cutoff_time)
      {
         // Remove old level
         for(int j = i; j < count - 1; j++)
         {
            levels[j] = levels[j + 1];
         }
         count--;
         ZeroMemory(levels[count]);
      }
   }
}

//+------------------------------------------------------------------+
//| Merge similar levels                                            |
//+------------------------------------------------------------------+
void CSR_Engine::MergeSimilarLevels(SRLevel& levels[], int& count, double proximity)
{
   for(int i = 0; i < count - 1; i++)
   {
      for(int j = i + 1; j < count; j++)
      {
         if(IsNearLevel(levels[i].price, levels[j].price, proximity))
         {
            // Merge j into i (keep stronger one)
            if(levels[j].strength > levels[i].strength)
            {
               levels[i] = levels[j];
            }
            
            // Remove level j
            for(int k = j; k < count - 1; k++)
            {
               levels[k] = levels[k + 1];
            }
            count--;
            ZeroMemory(levels[count]);
            j--; // Adjust index
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check S&R signal                                                |
//+------------------------------------------------------------------+
ENUM_SIGNAL_DIRECTION CSR_Engine::CheckSRSignal(const string symbol)
{
   if(!m_initialized)
      return SIGNAL_NONE;
   
   double current_price = SymbolInfoDouble(symbol, SYMBOL_BID);
   if(current_price <= 0)
      return SIGNAL_NONE;
   
   // Get nearest support and resistance levels
   SRLevel nearest_support, nearest_resistance;
   
   if(!GetNearestSRLevels(symbol, current_price, nearest_support, nearest_resistance, 0.0))
      return SIGNAL_NONE;
   
   double proximity = GetProximityPoints(symbol) * 2; // Double proximity for signal detection
   
   // Check for bounce setup at support
   if(nearest_support.is_active && 
      IsNearLevel(current_price, nearest_support.price, proximity) &&
      current_price > nearest_support.price)
   {
      if(nearest_support.strength >= 15.0 && // InpSR_MinCombinedStrength
         CheckPriceActionSetup(symbol, nearest_support, SIGNAL_BUY))
      {
         LogInfo(StringFormat("%s: BUY signal at support level %.5f (strength: %d)", 
                             symbol, nearest_support.price, nearest_support.strength), "CheckSRSignal");
         return SIGNAL_BUY;
      }
   }
   
   // Check for bounce setup at resistance
   if(nearest_resistance.is_active &&
      IsNearLevel(current_price, nearest_resistance.price, proximity) &&
      current_price < nearest_resistance.price)
   {
      if(nearest_resistance.strength >= 15.0 && // InpSR_MinCombinedStrength
         CheckPriceActionSetup(symbol, nearest_resistance, SIGNAL_SELL))
      {
         LogInfo(StringFormat("%s: SELL signal at resistance level %.5f (strength: %d)", 
                             symbol, nearest_resistance.price, nearest_resistance.strength), "CheckSRSignal");
         return SIGNAL_SELL;
      }
   }
   
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Get nearest support and resistance levels                       |
//+------------------------------------------------------------------+
bool CSR_Engine::GetNearestSRLevels(const string symbol, double current_price,
                                    SRLevel& nearest_support, SRLevel& nearest_resistance,
                                    double max_distance = 0.0)
{
   ZeroMemory(nearest_support);
   ZeroMemory(nearest_resistance);
   
   double support_distance = 999999.0;
   double resistance_distance = 999999.0;
   double search_distance = (max_distance > 0) ? max_distance : GetProximityPoints(symbol) * 100;
   
   // Search Daily levels
   for(int i = 0; i < m_daily_count; i++)
   {
      if(!m_daily_levels[i].is_active)
         continue;
         
      double distance = MathAbs(m_daily_levels[i].price - current_price);
      if(distance > search_distance)
         continue;
      
      // Check for nearest support (below current price)
      if(m_daily_levels[i].is_support && m_daily_levels[i].price < current_price)
      {
         if(distance < support_distance)
         {
            support_distance = distance;
            nearest_support = m_daily_levels[i];
         }
      }
      
      // Check for nearest resistance (above current price)
      if(m_daily_levels[i].is_resistance && m_daily_levels[i].price > current_price)
      {
         if(distance < resistance_distance)
         {
            resistance_distance = distance;
            nearest_resistance = m_daily_levels[i];
         }
      }
   }
   
   // Search H4 levels
   for(int i = 0; i < m_h4_count; i++)
   {
      if(!m_h4_levels[i].is_active)
         continue;
         
      double distance = MathAbs(m_h4_levels[i].price - current_price);
      if(distance > search_distance)
         continue;
      
      // Check for nearest support (below current price)
      if(m_h4_levels[i].is_support && m_h4_levels[i].price < current_price)
      {
         if(distance < support_distance)
         {
            support_distance = distance;
            nearest_support = m_h4_levels[i];
         }
      }
      
      // Check for nearest resistance (above current price)
      if(m_h4_levels[i].is_resistance && m_h4_levels[i].price > current_price)
      {
         if(distance < resistance_distance)
         {
            resistance_distance = distance;
            nearest_resistance = m_h4_levels[i];
         }
      }
   }
   
   // Search H1 levels
   for(int i = 0; i < m_h1_count; i++)
   {
      if(!m_h1_levels[i].is_active)
         continue;
         
      double distance = MathAbs(m_h1_levels[i].price - current_price);
      if(distance > search_distance)
         continue;
      
      // Check for nearest support (below current price)
      if(m_h1_levels[i].is_support && m_h1_levels[i].price < current_price)
      {
         if(distance < support_distance)
         {
            support_distance = distance;
            nearest_support = m_h1_levels[i];
         }
      }
      
      // Check for nearest resistance (above current price)
      if(m_h1_levels[i].is_resistance && m_h1_levels[i].price > current_price)
      {
         if(distance < resistance_distance)
         {
            resistance_distance = distance;
            nearest_resistance = m_h1_levels[i];
         }
      }
   }
   
   return (nearest_support.is_active || nearest_resistance.is_active);
}

//+------------------------------------------------------------------+
//| Check price action setup                                        |
//+------------------------------------------------------------------+
bool CSR_Engine::CheckPriceActionSetup(const string symbol, const SRLevel& level, ENUM_SIGNAL_DIRECTION expected_direction)
{
   // Simple price action check - look for rejection candles
   double open = iOpen(symbol, PERIOD_CURRENT, 1);
   double close = iClose(symbol, PERIOD_CURRENT, 1);
   double high = iHigh(symbol, PERIOD_CURRENT, 1);
   double low = iLow(symbol, PERIOD_CURRENT, 1);
   
   if(open == 0 || close == 0)
      return false;
   
   double body_size = MathAbs(close - open);
   double total_size = high - low;
   
   if(total_size == 0)
      return false;
   
   double body_ratio = body_size / total_size;
   
   if(expected_direction == SIGNAL_BUY)
   {
      // Look for bullish rejection at support
      bool hammer_like = (low <= level.price) && (close > open) && (body_ratio < 0.6);
      return hammer_like;
   }
   else if(expected_direction == SIGNAL_SELL)
   {
      // Look for bearish rejection at resistance  
      bool shooting_star_like = (high >= level.price) && (close < open) && (body_ratio < 0.6);
      return shooting_star_like;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Get optimal stop loss level                                     |
//+------------------------------------------------------------------+
double CSR_Engine::GetOptimalSL(const string symbol, double entry_price, ENUM_SIGNAL_DIRECTION direction)
{
   if(direction == SIGNAL_BUY)
   {
      SRLevel support = GetStrongestSR(symbol, entry_price, true);
      if(support.is_active)
      {
         double buffer = GetProximityPoints(symbol) * 2;
         return support.price - buffer;
      }
   }
   else if(direction == SIGNAL_SELL)
   {
      SRLevel resistance = GetStrongestSR(symbol, entry_price, false);
      if(resistance.is_active)
      {
         double buffer = GetProximityPoints(symbol) * 2;
         return resistance.price + buffer;
      }
   }
   
   // Fallback to ATR-based SL
   int atr_handle = iATR(symbol, PERIOD_CURRENT, 14);
   if(atr_handle != INVALID_HANDLE)
   {
      double atr_buffer[];
      if(CopyBuffer(atr_handle, 0, 0, 1, atr_buffer) > 0)
      {
         double atr = atr_buffer[0];
         IndicatorRelease(atr_handle);
         
         if(direction == SIGNAL_BUY)
            return entry_price - (atr * 1.5);
         else
            return entry_price + (atr * 1.5);
      }
      IndicatorRelease(atr_handle);
   }
   
   return 0.0;
}

//+------------------------------------------------------------------+
//| Get optimal take profit level                                   |
//+------------------------------------------------------------------+
double CSR_Engine::GetOptimalTP(const string symbol, double entry_price, ENUM_SIGNAL_DIRECTION direction)
{
   if(direction == SIGNAL_BUY)
   {
      SRLevel resistance = GetStrongestSR(symbol, entry_price, false);
      if(resistance.is_active)
      {
         double buffer = GetProximityPoints(symbol);
         return resistance.price - buffer;
      }
   }
   else if(direction == SIGNAL_SELL)
   {
      SRLevel support = GetStrongestSR(symbol, entry_price, true);
      if(support.is_active)
      {
         double buffer = GetProximityPoints(symbol);
         return support.price + buffer;
      }
   }
   
   // Fallback to R:R based TP
   double sl_level = GetOptimalSL(symbol, entry_price, direction);
   if(sl_level > 0)
   {
      double sl_distance = MathAbs(entry_price - sl_level);
      double rr_ratio = 2.5; // InpTP_RR
      
      if(direction == SIGNAL_BUY)
         return entry_price + (sl_distance * rr_ratio);
      else
         return entry_price - (sl_distance * rr_ratio);
   }
   
   return 0.0;
}

//+------------------------------------------------------------------+
//| Print all levels for symbol                                     |
//+------------------------------------------------------------------+
void CSR_Engine::PrintAllLevels(const string symbol)
{
   g_Logger.Info(StringFormat("=== S&R Levels for %s ===", symbol));
   
   g_Logger.Info(StringFormat("Daily Levels (%d):", m_daily_count));
   for(int i = 0; i < m_daily_count; i++)
   {
      if(m_daily_levels[i].is_active)
      {
         g_Logger.Info(StringFormat("  %.5f - Strength: %d, Touches: %d, %s%s",
                           m_daily_levels[i].price,
                           m_daily_levels[i].strength,
                           m_daily_levels[i].touches,
                           m_daily_levels[i].is_support ? "Support " : "",
                           m_daily_levels[i].is_resistance ? "Resistance" : ""));
      }
   }
   
   g_Logger.Info(StringFormat("H4 Levels (%d):", m_h4_count));
   for(int i = 0; i < m_h4_count; i++)
   {
      if(m_h4_levels[i].is_active)
      {
         g_Logger.Info(StringFormat("  %.5f - Strength: %d, Touches: %d, %s%s",
                           m_h4_levels[i].price,
                           m_h4_levels[i].strength,
                           m_h4_levels[i].touches,
                           m_h4_levels[i].is_support ? "Support " : "",
                           m_h4_levels[i].is_resistance ? "Resistance" : ""));
      }
   }
   
   g_Logger.Info(StringFormat("H1 Levels (%d):", m_h1_count));
   for(int i = 0; i < m_h1_count; i++)
   {
      if(m_h1_levels[i].is_active)
      {
         g_Logger.Info(StringFormat("  %.5f - Strength: %d, Touches: %d, %s%s",
                           m_h1_levels[i].price,
                           m_h1_levels[i].strength,
                           m_h1_levels[i].touches,
                           m_h1_levels[i].is_support ? "Support " : "",
                           m_h1_levels[i].is_resistance ? "Resistance" : ""));
      }
   }
   
   g_Logger.Info("================================");
}

//+------------------------------------------------------------------+
//| Get active levels count                                         |
//+------------------------------------------------------------------+
int CSR_Engine::GetActiveLevelsCount(const string symbol)
{
   return m_daily_count + m_h4_count + m_h1_count;
}

//+------------------------------------------------------------------+
//| Get average strength of levels                                  |
//+------------------------------------------------------------------+
double CSR_Engine::GetAverageStrength(const string symbol)
{
   int total_levels = 0;
   int total_strength = 0;
   
   // Count Daily levels
   for(int i = 0; i < m_daily_count; i++)
   {
      if(m_daily_levels[i].is_active)
      {
         total_levels++;
         total_strength += m_daily_levels[i].strength;
      }
   }
   
   // Count H4 levels  
   for(int i = 0; i < m_h4_count; i++)
   {
      if(m_h4_levels[i].is_active)
      {
         total_levels++;
         total_strength += m_h4_levels[i].strength;
      }
   }
   
   // Count H1 levels
   for(int i = 0; i < m_h1_count; i++)
   {
      if(m_h1_levels[i].is_active)
      {
         total_levels++;
         total_strength += m_h1_levels[i].strength;
      }
   }
   
   return (total_levels > 0) ? (double)total_strength / total_levels : 0.0;
}

//+------------------------------------------------------------------+
//| Check bounce setup                                              |
//+------------------------------------------------------------------+
ENUM_SIGNAL_DIRECTION CSR_Engine::CheckBounceSetup(const string symbol)
{
   return CheckSRSignal(symbol); // Same as main signal for now
}

//+------------------------------------------------------------------+
//| Check breakout setup                                            |
//+------------------------------------------------------------------+
ENUM_SIGNAL_DIRECTION CSR_Engine::CheckBreakoutSetup(const string symbol)
{
   // Breakout logic would be implemented here
   // For now, return SIGNAL_NONE as this is more complex
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Validate symbol data                                            |
//+------------------------------------------------------------------+
bool CSR_Engine::ValidateSymbolData(const string symbol)
{
   // Check if we have sufficient price data
   double test_data[];
   return (CopyHigh(symbol, PERIOD_H1, 0, 50, test_data) >= 50);
}

//+------------------------------------------------------------------+
//| Check if market is suitable for S&R trading                    |
//+------------------------------------------------------------------+
bool CSR_Engine::IsMarketSuitableForSR(const string symbol)
{
   // Check volatility and market conditions
   int atr_handle = iATR(symbol, PERIOD_H1, 14);
   if(atr_handle == INVALID_HANDLE)
      return false;
   
   double atr_buffer[];
   if(CopyBuffer(atr_handle, 0, 0, 1, atr_buffer) <= 0)
   {
      IndicatorRelease(atr_handle);
      return false;
   }
   
   double atr = atr_buffer[0];
   double current_price = SymbolInfoDouble(symbol, SYMBOL_BID);
   double atr_percent = (current_price > 0) ? (atr / current_price) * 100.0 : 0.0;
   
   IndicatorRelease(atr_handle);
   
   // Check if volatility is in acceptable range
   return (atr_percent >= 0.05 && atr_percent <= 0.2); // 0.05% to 0.2% volatility
}

//+------------------------------------------------------------------+
