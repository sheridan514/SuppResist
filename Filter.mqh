//+------------------------------------------------------------------+
//| Filter.mqh                                                       |
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
//| CFilter Class                                                    |
//+------------------------------------------------------------------+
class CFilter
{
private:
   SSettings         m_settings;                    // Filter settings
   bool              m_initialized;                 // Initialization flag
   
   // Indicator handles
   int               m_rsi_handles[];               // RSI handles for each symbol
   int               m_bb_handles[];                // Bollinger Bands handles
   int               m_stoch_handles[];             // Stochastic handles
   int               m_atr_handles[];               // ATR handles
   int               m_adx_handles[];               // ADX handles
   int               m_ema_handles[];               // Main EMA handles
   int               m_ema50_handles[];             // 50 EMA handles
   int               m_ema200_handles[];            // 200 EMA handles
   
   // Symbol-to-index mapping
   string            m_symbols[];                   // Symbols array
   int               m_symbols_count;               // Number of symbols
   
   // Internal calculation methods
   bool CreateIndicatorHandles();
   void ReleaseIndicatorHandles();
   int GetSymbolIndex(const string symbol);
   bool ValidateIndicatorData(const string symbol, int required_bars = 3);
   
   // RSI methods
   double GetRsiValue(const string symbol, int shift = 0);
   ENUM_SIGNAL_DIRECTION GetRsiSignal(const string symbol);
   
   // Bollinger Bands methods
   bool GetBollingerValues(const string symbol, double& upper, double& middle, double& lower, int shift = 0);
   ENUM_SIGNAL_DIRECTION GetBollingerSignal(const string symbol);
   double GetBollingerPosition(const string symbol); // -1 to +1 position within bands
   
   // Stochastic methods
   bool GetStochasticValues(const string symbol, double& main, double& signal, int shift = 0);
   ENUM_SIGNAL_DIRECTION CheckStochasticSignal(const string symbol);
   
   // ATR methods
   double GetAtrValue(const string symbol, int shift = 0);
   double GetAtrPercent(const string symbol);
   bool IsHighVolatility(const string symbol);
   
   // ADX methods
   double GetAdxValue(const string symbol, int shift = 0);
   bool IsTrendingMarket(const string symbol);
   
   // EMA methods
   bool GetEmaValues(const string symbol, double& ema_main, double& ema_50, double& ema_200, int shift = 0);
   bool IsEmaStackBullish(const string symbol);
   bool IsEmaStackBearish(const string symbol);
   bool IsPullbackToEma(const string symbol);
   
   // Score calculation methods
   double CalculateRsiScore(const string symbol);
   double CalculateBollingerScore(const string symbol);
   double CalculateStochasticScore(const string symbol);
   double CalculateAtrAdxScore(const string symbol);
   
   // Strategy specific methods
   ENUM_SIGNAL_DIRECTION GetTrendSignal(const string symbol);
   ENUM_SIGNAL_DIRECTION GetConsolidationSignal(const string symbol);
   ENUM_SIGNAL_DIRECTION GetCombinedSignal(const string symbol);
   
   // Penalty methods
   double ApplyEarlyWarningPenalty(const string symbol, double base_score);
   bool IsConsolidationEnding(const string symbol);
   
   // Utility methods
   double NormalizeScore(double score, double min_val, double max_val);
   bool IsNewBar(const string symbol);
   
public:
   // Constructor/Destructor
   CFilter();
   ~CFilter();
   
   // Initialization
   bool Initialize(const SSettings& settings);
   void Deinitialize();
   
   // Main interface methods
   double GetSymbolScore(const string symbol);
   ENUM_SIGNAL_DIRECTION GetStrategySignal(const string symbol, double score);
   ENUM_SIGNAL_DIRECTION GetFinalSignal(const string symbol);
   
   // Individual indicator access
   SIndicatorSnapshot GetIndicatorSnapshot(const string symbol);
   
   // Signal information
   SSignalInfo GetSignalInfo(const string symbol);
   
   // Validation methods
   bool IsSymbolSupported(const string symbol);
   bool IsMarketSuitable(const string symbol);
   
   // Debug methods
   void PrintIndicatorValues(const string symbol);
   string GetDebugInfo(const string symbol);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CFilter::CFilter() : m_initialized(false), m_symbols_count(0)
{
   ZeroMemory(m_settings);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CFilter::~CFilter()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize filter                                                |
//+------------------------------------------------------------------+
bool CFilter::Initialize(const SSettings& settings)
{
   if(m_initialized)
      return true;
   
   m_settings = settings;
   m_symbols_count = settings.symbols_count;
   
   if(m_symbols_count <= 0)
   {
      LogError("No symbols provided for filter initialization", "CFilter::Initialize");
      return false;
   }
   
   // Copy symbols
   ArrayResize(m_symbols, m_symbols_count);
   for(int i = 0; i < m_symbols_count; i++)
   {
      m_symbols[i] = settings.symbols[i];
   }
   
   // Create indicator handles
   if(!CreateIndicatorHandles())
   {
      LogError("Failed to create indicator handles", "CFilter::Initialize");
      return false;
   }
   
   m_initialized = true;
   LogInfo(StringFormat("Filter initialized for %d symbols", m_symbols_count), "CFilter::Initialize");
   
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize filter                                              |
//+------------------------------------------------------------------+
void CFilter::Deinitialize()
{
   if(!m_initialized)
      return;
   
   ReleaseIndicatorHandles();
   ArrayFree(m_symbols);
   m_symbols_count = 0;
   m_initialized = false;
   
   LogInfo("Filter deinitialized", "CFilter::Deinitialize");
}

//+------------------------------------------------------------------+
//| Create indicator handles for all symbols                         |
//+------------------------------------------------------------------+
bool CFilter::CreateIndicatorHandles()
{
   // Resize arrays
   ArrayResize(m_rsi_handles, m_symbols_count);
   ArrayResize(m_bb_handles, m_symbols_count);
   ArrayResize(m_stoch_handles, m_symbols_count);
   ArrayResize(m_atr_handles, m_symbols_count);
   ArrayResize(m_adx_handles, m_symbols_count);
   ArrayResize(m_ema_handles, m_symbols_count);
   ArrayResize(m_ema50_handles, m_symbols_count);
   ArrayResize(m_ema200_handles, m_symbols_count);
   
   // Initialize handles
   ArrayInitialize(m_rsi_handles, INVALID_HANDLE);
   ArrayInitialize(m_bb_handles, INVALID_HANDLE);
   ArrayInitialize(m_stoch_handles, INVALID_HANDLE);
   ArrayInitialize(m_atr_handles, INVALID_HANDLE);
   ArrayInitialize(m_adx_handles, INVALID_HANDLE);
   ArrayInitialize(m_ema_handles, INVALID_HANDLE);
   ArrayInitialize(m_ema50_handles, INVALID_HANDLE);
   ArrayInitialize(m_ema200_handles, INVALID_HANDLE);
   
   bool all_created = true;
   
   for(int i = 0; i < m_symbols_count; i++)
   {
      string symbol = m_symbols[i];
      
         // Create RSI handle (using ATR period as fallback)
   m_rsi_handles[i] = iRSI(symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
      if(m_rsi_handles[i] == INVALID_HANDLE)
      {
         LogError(StringFormat("Failed to create RSI handle for %s", symbol), "CFilter::CreateIndicatorHandles");
         all_created = false;
      }
      
      // Create Bollinger Bands handle
      m_bb_handles[i] = iBands(symbol, PERIOD_CURRENT, 20, 0, 2.0, PRICE_CLOSE);
      if(m_bb_handles[i] == INVALID_HANDLE)
      {
         LogError(StringFormat("Failed to create BB handle for %s", symbol), "CFilter::CreateIndicatorHandles");
         all_created = false;
      }
      
      // Create Stochastic handle
      m_stoch_handles[i] = iStochastic(symbol, PERIOD_CURRENT, 5, 3, 3, MODE_SMA, STO_LOWHIGH);
      if(m_stoch_handles[i] == INVALID_HANDLE)
      {
         LogError(StringFormat("Failed to create Stochastic handle for %s", symbol), "CFilter::CreateIndicatorHandles");
         all_created = false;
      }
      
      // Create ATR handle
      m_atr_handles[i] = iATR(symbol, PERIOD_CURRENT, m_settings.atr_period);
      if(m_atr_handles[i] == INVALID_HANDLE)
      {
         LogError(StringFormat("Failed to create ATR handle for %s", symbol), "CFilter::CreateIndicatorHandles");
         all_created = false;
      }
      
      // Create ADX handle
      m_adx_handles[i] = iADX(symbol, PERIOD_CURRENT, 14);
      if(m_adx_handles[i] == INVALID_HANDLE)
      {
         LogError(StringFormat("Failed to create ADX handle for %s", symbol), "CFilter::CreateIndicatorHandles");
         all_created = false;
      }
      
      // Create EMA handles
      m_ema_handles[i] = iMA(symbol, PERIOD_CURRENT, 21, 0, MODE_EMA, PRICE_CLOSE);
      if(m_ema_handles[i] == INVALID_HANDLE)
      {
         LogError(StringFormat("Failed to create main EMA handle for %s", symbol), "CFilter::CreateIndicatorHandles");
         all_created = false;
      }
      
      m_ema50_handles[i] = iMA(symbol, PERIOD_CURRENT, 50, 0, MODE_EMA, PRICE_CLOSE);
      if(m_ema50_handles[i] == INVALID_HANDLE)
      {
         LogError(StringFormat("Failed to create EMA50 handle for %s", symbol), "CFilter::CreateIndicatorHandles");
         all_created = false;
      }
      
      m_ema200_handles[i] = iMA(symbol, PERIOD_CURRENT, 200, 0, MODE_EMA, PRICE_CLOSE);
      if(m_ema200_handles[i] == INVALID_HANDLE)
      {
         LogError(StringFormat("Failed to create EMA200 handle for %s", symbol), "CFilter::CreateIndicatorHandles");
         all_created = false;
      }
      
      LogDebug(StringFormat("Created indicator handles for %s", symbol), "CFilter::CreateIndicatorHandles");
   }
   
   if(!all_created)
   {
      ReleaseIndicatorHandles();
      return false;
   }
   
   // Wait for indicator data to be available
   Sleep(1000);
   
   return true;
}

//+------------------------------------------------------------------+
//| Release indicator handles                                        |
//+------------------------------------------------------------------+
void CFilter::ReleaseIndicatorHandles()
{
   // Release RSI handles
   for(int i = 0; i < ArraySize(m_rsi_handles); i++)
   {
      if(m_rsi_handles[i] != INVALID_HANDLE)
         IndicatorRelease(m_rsi_handles[i]);
   }
   ArrayFree(m_rsi_handles);
   
   // Release BB handles
   for(int i = 0; i < ArraySize(m_bb_handles); i++)
   {
      if(m_bb_handles[i] != INVALID_HANDLE)
         IndicatorRelease(m_bb_handles[i]);
   }
   ArrayFree(m_bb_handles);
   
   // Release Stochastic handles
   for(int i = 0; i < ArraySize(m_stoch_handles); i++)
   {
      if(m_stoch_handles[i] != INVALID_HANDLE)
         IndicatorRelease(m_stoch_handles[i]);
   }
   ArrayFree(m_stoch_handles);
   
   // Release ATR handles
   for(int i = 0; i < ArraySize(m_atr_handles); i++)
   {
      if(m_atr_handles[i] != INVALID_HANDLE)
         IndicatorRelease(m_atr_handles[i]);
   }
   ArrayFree(m_atr_handles);
   
   // Release ADX handles
   for(int i = 0; i < ArraySize(m_adx_handles); i++)
   {
      if(m_adx_handles[i] != INVALID_HANDLE)
         IndicatorRelease(m_adx_handles[i]);
   }
   ArrayFree(m_adx_handles);
   
   // Release EMA handles
   for(int i = 0; i < ArraySize(m_ema_handles); i++)
   {
      if(m_ema_handles[i] != INVALID_HANDLE)
         IndicatorRelease(m_ema_handles[i]);
   }
   ArrayFree(m_ema_handles);
   
   for(int i = 0; i < ArraySize(m_ema50_handles); i++)
   {
      if(m_ema50_handles[i] != INVALID_HANDLE)
         IndicatorRelease(m_ema50_handles[i]);
   }
   ArrayFree(m_ema50_handles);
   
   for(int i = 0; i < ArraySize(m_ema200_handles); i++)
   {
      if(m_ema200_handles[i] != INVALID_HANDLE)
         IndicatorRelease(m_ema200_handles[i]);
   }
   ArrayFree(m_ema200_handles);
}

//+------------------------------------------------------------------+
//| Get symbol index in arrays                                       |
//+------------------------------------------------------------------+
int CFilter::GetSymbolIndex(const string symbol)
{
   for(int i = 0; i < m_symbols_count; i++)
   {
      if(m_symbols[i] == symbol)
         return i;
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Validate indicator data availability                             |
//+------------------------------------------------------------------+
bool CFilter::ValidateIndicatorData(const string symbol, int required_bars = 3)
{
   int symbol_idx = GetSymbolIndex(symbol);
   if(symbol_idx < 0)
      return false;
   
   // Check if we have enough data for calculations
   if(BarsCalculated(m_rsi_handles[symbol_idx]) < required_bars)
      return false;
   if(BarsCalculated(m_bb_handles[symbol_idx]) < required_bars)
      return false;
   if(BarsCalculated(m_stoch_handles[symbol_idx]) < required_bars)
      return false;
   if(BarsCalculated(m_atr_handles[symbol_idx]) < required_bars)
      return false;
   if(BarsCalculated(m_adx_handles[symbol_idx]) < required_bars)
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Get RSI value                                                    |
//+------------------------------------------------------------------+
double CFilter::GetRsiValue(const string symbol, int shift = 0)
{
   int symbol_idx = GetSymbolIndex(symbol);
   if(symbol_idx < 0 || m_rsi_handles[symbol_idx] == INVALID_HANDLE)
      return 0.0;
   
   double rsi_buffer[];
   if(CopyBuffer(m_rsi_handles[symbol_idx], 0, shift, 1, rsi_buffer) <= 0)
      return 0.0;
   
   return rsi_buffer[0];
}

//+------------------------------------------------------------------+
//| Get RSI signal                                                   |
//+------------------------------------------------------------------+
ENUM_SIGNAL_DIRECTION CFilter::GetRsiSignal(const string symbol)
{
   double rsi_current = GetRsiValue(symbol, 0);
   double rsi_previous = GetRsiValue(symbol, 1);
   
   if(rsi_current == 0.0 || rsi_previous == 0.0)
      return SIGNAL_NONE;
   
   // RSI oversold reversal signal
   if(rsi_previous <= RSI_OVERSOLD_LEVEL && rsi_current > RSI_OVERSOLD_LEVEL)
   {
      LogDebug(StringFormat("%s RSI BUY signal: %f . %f", symbol, rsi_previous, rsi_current), "GetRsiSignal");
      return SIGNAL_BUY;
   }
   
   // RSI overbought reversal signal
   if(rsi_previous >= RSI_OVERBOUGHT_LEVEL && rsi_current < RSI_OVERBOUGHT_LEVEL)
   {
      LogDebug(StringFormat("%s RSI SELL signal: %f . %f", symbol, rsi_previous, rsi_current), "GetRsiSignal");
      return SIGNAL_SELL;
   }
   
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Get Bollinger Bands values                                       |
//+------------------------------------------------------------------+
bool CFilter::GetBollingerValues(const string symbol, double& upper, double& middle, double& lower, int shift = 0)
{
   int symbol_idx = GetSymbolIndex(symbol);
   if(symbol_idx < 0 || m_bb_handles[symbol_idx] == INVALID_HANDLE)
      return false;
   
   double upper_buffer[], middle_buffer[], lower_buffer[];
   
   if(CopyBuffer(m_bb_handles[symbol_idx], 1, shift, 1, upper_buffer) <= 0 ||
      CopyBuffer(m_bb_handles[symbol_idx], 0, shift, 1, middle_buffer) <= 0 ||
      CopyBuffer(m_bb_handles[symbol_idx], 2, shift, 1, lower_buffer) <= 0)
      return false;
   
   upper = upper_buffer[0];
   middle = middle_buffer[0];
   lower = lower_buffer[0];
   
   return true;
}

//+------------------------------------------------------------------+
//| Get Bollinger Bands signal                                       |
//+------------------------------------------------------------------+
ENUM_SIGNAL_DIRECTION CFilter::GetBollingerSignal(const string symbol)
{
   double upper, middle, lower;
   if(!GetBollingerValues(symbol, upper, middle, lower, 0))
      return SIGNAL_NONE;
   
   double close_price = iClose(symbol, PERIOD_CURRENT, 0);
   double previous_close = iClose(symbol, PERIOD_CURRENT, 1);
   
   // BB bounce from lower band
   if(previous_close <= lower && close_price > lower)
   {
      LogDebug(StringFormat("%s BB BUY signal: bounce from lower band", symbol), "GetBollingerSignal");
      return SIGNAL_BUY;
   }
   
   // BB bounce from upper band
   if(previous_close >= upper && close_price < upper)
   {
      LogDebug(StringFormat("%s BB SELL signal: bounce from upper band", symbol), "GetBollingerSignal");
      return SIGNAL_SELL;
   }
   
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Get position within Bollinger Bands                             |
//+------------------------------------------------------------------+
double CFilter::GetBollingerPosition(const string symbol)
{
   double upper, middle, lower;
   if(!GetBollingerValues(symbol, upper, middle, lower, 0))
      return 0.0;
   
   double close_price = iClose(symbol, PERIOD_CURRENT, 0);
   double band_width = upper - lower;
   
   if(band_width == 0)
      return 0.0;
   
   // Return position: -1 = at lower band, 0 = at middle, +1 = at upper band
   return ((close_price - middle) / (band_width / 2.0));
}

//+------------------------------------------------------------------+
//| Get Stochastic values                                            |
//+------------------------------------------------------------------+
bool CFilter::GetStochasticValues(const string symbol, double& main, double& signal, int shift = 0)
{
   int symbol_idx = GetSymbolIndex(symbol);
   if(symbol_idx < 0 || m_stoch_handles[symbol_idx] == INVALID_HANDLE)
      return false;
   
   double main_buffer[], signal_buffer[];
   
   if(CopyBuffer(m_stoch_handles[symbol_idx], 0, shift, 1, main_buffer) <= 0 ||
      CopyBuffer(m_stoch_handles[symbol_idx], 1, shift, 1, signal_buffer) <= 0)
      return false;
   
   main = main_buffer[0];
   signal = signal_buffer[0];
   
   return true;
}

//+------------------------------------------------------------------+
//| Check Stochastic signal                                          |
//+------------------------------------------------------------------+
ENUM_SIGNAL_DIRECTION CFilter::CheckStochasticSignal(const string symbol)
{
   double main_current, signal_current, main_previous, signal_previous;
   
   if(!GetStochasticValues(symbol, main_current, signal_current, 0) ||
      !GetStochasticValues(symbol, main_previous, signal_previous, 1))
      return SIGNAL_NONE;
   
   // Stochastic oversold crossover
   if(main_previous <= 20.0 && 
      main_current > 20.0 &&
      main_current > signal_current)
   {
      LogDebug(StringFormat("%s Stochastic BUY signal: %f . %f", symbol, main_previous, main_current), "CheckStochasticSignal");
      return SIGNAL_BUY;
   }
   
   // Stochastic overbought crossunder
   if(main_previous >= 80.0 &&
      main_current < 80.0 &&
      main_current < signal_current)
   {
      LogDebug(StringFormat("%s Stochastic SELL signal: %f . %f", symbol, main_previous, main_current), "CheckStochasticSignal");
      return SIGNAL_SELL;
   }
   
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Get ATR value                                                    |
//+------------------------------------------------------------------+
double CFilter::GetAtrValue(const string symbol, int shift = 0)
{
   int symbol_idx = GetSymbolIndex(symbol);
   if(symbol_idx < 0 || m_atr_handles[symbol_idx] == INVALID_HANDLE)
      return 0.0;
   
   double atr_buffer[];
   if(CopyBuffer(m_atr_handles[symbol_idx], 0, shift, 1, atr_buffer) <= 0)
      return 0.0;
   
   return atr_buffer[0];
}

//+------------------------------------------------------------------+
//| Get ATR as percentage                                            |
//+------------------------------------------------------------------+
double CFilter::GetAtrPercent(const string symbol)
{
   double atr_value = GetAtrValue(symbol, 0);
   if(atr_value == 0.0)
      return 0.0;
   
   double close_price = iClose(symbol, PERIOD_CURRENT, 0);
   if(close_price == 0.0)
      return 0.0;
   
   return (atr_value / close_price) * 100.0;
}

//+------------------------------------------------------------------+
//| Check if market has high volatility                             |
//+------------------------------------------------------------------+
bool CFilter::IsHighVolatility(const string symbol)
{
   double atr_current = GetAtrValue(symbol, 0);
   double atr_average = 0.0;
   int lookback = 10;
   
   // Calculate average ATR over lookback period
   for(int i = 1; i <= lookback; i++)
   {
      atr_average += GetAtrValue(symbol, i);
   }
   atr_average /= lookback;
   
   if(atr_average == 0.0)
      return false;
   
   // High volatility if current ATR is 50% higher than average
   return (atr_current / atr_average) > 1.5;
}

//+------------------------------------------------------------------+
//| Get ADX value                                                    |
//+------------------------------------------------------------------+
double CFilter::GetAdxValue(const string symbol, int shift = 0)
{
   int symbol_idx = GetSymbolIndex(symbol);
   if(symbol_idx < 0 || m_adx_handles[symbol_idx] == INVALID_HANDLE)
      return 0.0;
   
   double adx_buffer[];
   if(CopyBuffer(m_adx_handles[symbol_idx], 0, shift, 1, adx_buffer) <= 0)
      return 0.0;
   
   return adx_buffer[0];
}

//+------------------------------------------------------------------+
//| Check if market is trending                                      |
//+------------------------------------------------------------------+
bool CFilter::IsTrendingMarket(const string symbol)
{
   double adx_value = GetAdxValue(symbol, 0);
   return (adx_value >= 25.0); // Standard ADX trending threshold
}

//+------------------------------------------------------------------+
//| Get EMA values                                                   |
//+------------------------------------------------------------------+
bool CFilter::GetEmaValues(const string symbol, double& ema_main, double& ema_50, double& ema_200, int shift = 0)
{
   int symbol_idx = GetSymbolIndex(symbol);
   if(symbol_idx < 0)
      return false;
   
   if(m_ema_handles[symbol_idx] == INVALID_HANDLE ||
      m_ema50_handles[symbol_idx] == INVALID_HANDLE ||
      m_ema200_handles[symbol_idx] == INVALID_HANDLE)
      return false;
   
   double ema_buffer[], ema50_buffer[], ema200_buffer[];
   
   if(CopyBuffer(m_ema_handles[symbol_idx], 0, shift, 1, ema_buffer) <= 0 ||
      CopyBuffer(m_ema50_handles[symbol_idx], 0, shift, 1, ema50_buffer) <= 0 ||
      CopyBuffer(m_ema200_handles[symbol_idx], 0, shift, 1, ema200_buffer) <= 0)
      return false;
   
   ema_main = ema_buffer[0];
   ema_50 = ema50_buffer[0];
   ema_200 = ema200_buffer[0];
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if EMA stack is bullish                                   |
//+------------------------------------------------------------------+
bool CFilter::IsEmaStackBullish(const string symbol)
{
   double ema_main, ema_50, ema_200;
   if(!GetEmaValues(symbol, ema_main, ema_50, ema_200, 0))
      return false;
   
   // Bullish stack: EMA_main > EMA_50 > EMA_200
   return (ema_main > ema_50 && ema_50 > ema_200);
}

//+------------------------------------------------------------------+
//| Check if EMA stack is bearish                                   |
//+------------------------------------------------------------------+
bool CFilter::IsEmaStackBearish(const string symbol)
{
   double ema_main, ema_50, ema_200;
   if(!GetEmaValues(symbol, ema_main, ema_50, ema_200, 0))
      return false;
   
   // Bearish stack: EMA_main < EMA_50 < EMA_200
   return (ema_main < ema_50 && ema_50 < ema_200);
}

//+------------------------------------------------------------------+
//| Check if price is in pullback to EMA                           |
//+------------------------------------------------------------------+
bool CFilter::IsPullbackToEma(const string symbol)
{
   double ema_main, ema_50, ema_200;
   if(!GetEmaValues(symbol, ema_main, ema_50, ema_200, 0))
      return false;
   
   double close_price = iClose(symbol, PERIOD_CURRENT, 0);
   double point_value = GetPointValue(symbol);
   double tolerance = 5.0 * point_value; // 5 points tolerance
   
   // Check if price is close to any EMA
   return (MathAbs(close_price - ema_main) <= tolerance ||
           MathAbs(close_price - ema_50) <= tolerance ||
           MathAbs(close_price - ema_200) <= tolerance);
}

//+------------------------------------------------------------------+
//| Calculate symbol score                                           |
//+------------------------------------------------------------------+
double CFilter::GetSymbolScore(const string symbol)
{
   if(!ValidateIndicatorData(symbol))
   {
      LogWarning(StringFormat("Insufficient indicator data for %s", symbol), "GetSymbolScore");
      return 0.0;
   }
   
   double rsi_score = CalculateRsiScore(symbol);
   double bb_score = CalculateBollingerScore(symbol);
   double stoch_score = CalculateStochasticScore(symbol);
   double atr_adx_score = CalculateAtrAdxScore(symbol);
   
   // Weighted combination
   double base_score = (rsi_score * WEIGHT_RSI +
                       bb_score * WEIGHT_BOLLINGER +
                       stoch_score * WEIGHT_STOCHASTIC +
                       atr_adx_score * WEIGHT_ATR_ADX) / 100.0;
   
   // Apply early warning penalties
   double final_score = ApplyEarlyWarningPenalty(symbol, base_score);
   
   LogDebug(StringFormat("%s Score: RSI=%.1f, BB=%.1f, Stoch=%.1f, ATR_ADX=%.1f, Final=%.1f", 
                         symbol, rsi_score, bb_score, stoch_score, atr_adx_score, final_score), "GetSymbolScore");
   
   return MathMax(0.0, MathMin(100.0, final_score));
}

//+------------------------------------------------------------------+
//| Calculate RSI score                                              |
//+------------------------------------------------------------------+
double CFilter::CalculateRsiScore(const string symbol)
{
   double rsi_value = GetRsiValue(symbol, 0);
   if(rsi_value == 0.0)
      return 0.0;
   
   // Score based on RSI position (0-100 scale)
   // Higher score for extreme values (good for mean reversion)
   if(rsi_value <= 30.0)
      return 100.0 - ((rsi_value / 30.0) * 50.0); // 50-100
   else if(rsi_value >= 70.0)
      return 100.0 - (((rsi_value - 70.0) / 30.0) * 50.0); // 50-100
   else
      return (50.0 - MathAbs(rsi_value - 50.0)); // 0-50
}

//+------------------------------------------------------------------+
//| Calculate Bollinger score                                        |
//+------------------------------------------------------------------+
double CFilter::CalculateBollingerScore(const string symbol)
{
   double bb_position = GetBollingerPosition(symbol);
   
   // Score based on position within bands
   // Higher score for positions near bands (good for mean reversion)
   return MathAbs(bb_position) * 100.0;
}

//+------------------------------------------------------------------+
//| Calculate Stochastic score                                       |
//+------------------------------------------------------------------+
double CFilter::CalculateStochasticScore(const string symbol)
{
   double main, signal;
   if(!GetStochasticValues(symbol, main, signal, 0))
      return 0.0;
   
   // Score based on Stochastic extremes
   if(main <= 20.0 || main >= 80.0)
      return 100.0;
   else if(main <= 30.0 || main >= 70.0)
      return 75.0;
   else
      return MathMax(0.0, 50.0 - MathAbs(main - 50.0));
}

//+------------------------------------------------------------------+
//| Calculate ATR/ADX combined score                                 |
//+------------------------------------------------------------------+
double CFilter::CalculateAtrAdxScore(const string symbol)
{
   double atr_percent = GetAtrPercent(symbol);
   double adx_value = GetAdxValue(symbol, 0);
   
   double atr_score = 0.0;
   double adx_score = 0.0;
   
   // ATR score (higher volatility = higher score for scalping)
   if(atr_percent > 1.0)
      atr_score = 100.0;
   else if(atr_percent > 0.5)
      atr_score = 75.0;
   else
      atr_score = atr_percent * 100.0;
   
   // ADX score (lower trend strength = higher score for range trading)
   if(adx_value < 20.0)
      adx_score = 100.0;
   else if(adx_value < 25.0)
      adx_score = 75.0;
   else
      adx_score = MathMax(0.0, 100.0 - ((adx_value - 25.0) * 2.0));
   
   return (atr_score + adx_score) / 2.0;
}

//+------------------------------------------------------------------+
//| Get strategy signal based on score                              |
//+------------------------------------------------------------------+
ENUM_SIGNAL_DIRECTION CFilter::GetStrategySignal(const string symbol, double score)
{
   if(score <= m_settings.trend_threshold)
   {
      // Use trend strategy
      return GetTrendSignal(symbol);
   }
   else if(score >= m_settings.scalping_min_score)
   {
      // Use consolidation/scalping strategy
      return GetConsolidationSignal(symbol);
   }
   
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Get trend signal                                                 |
//+------------------------------------------------------------------+
ENUM_SIGNAL_DIRECTION CFilter::GetTrendSignal(const string symbol)
{
   // Check EMA stack alignment
   bool bullish_stack = IsEmaStackBullish(symbol);
   bool bearish_stack = IsEmaStackBearish(symbol);
   
   if(!bullish_stack && !bearish_stack)
      return SIGNAL_NONE;
   
   // Check for pullback opportunity
   bool is_pullback = IsPullbackToEma(symbol);
   if(!is_pullback)
      return SIGNAL_NONE;
   
   // Check Stochastic for timing
   double stoch_main, stoch_signal;
   if(!GetStochasticValues(symbol, stoch_main, stoch_signal, 0))
      return SIGNAL_NONE;
   
   if(bullish_stack && stoch_main <= 30.0) // Oversold in bullish trend
   {
      LogInfo(StringFormat("%s TREND BUY signal: Pullback in bullish trend", symbol), "GetTrendSignal");
      return SIGNAL_BUY;
   }
   
   if(bearish_stack && stoch_main >= 70.0) // Overbought in bearish trend
   {
      LogInfo(StringFormat("%s TREND SELL signal: Pullback in bearish trend", symbol), "GetTrendSignal");
      return SIGNAL_SELL;
   }
   
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Get consolidation signal                                         |
//+------------------------------------------------------------------+
ENUM_SIGNAL_DIRECTION CFilter::GetConsolidationSignal(const string symbol)
{
   return GetCombinedSignal(symbol);
}

//+------------------------------------------------------------------+
//| Get combined signal for range trading                           |
//+------------------------------------------------------------------+
ENUM_SIGNAL_DIRECTION CFilter::GetCombinedSignal(const string symbol)
{
   ENUM_SIGNAL_DIRECTION rsi_signal = GetRsiSignal(symbol);
   ENUM_SIGNAL_DIRECTION bb_signal = GetBollingerSignal(symbol);
   ENUM_SIGNAL_DIRECTION stoch_signal = CheckStochasticSignal(symbol);
   
   int buy_votes = 0;
   int sell_votes = 0;
   
   if(rsi_signal == SIGNAL_BUY) buy_votes++;
   else if(rsi_signal == SIGNAL_SELL) sell_votes++;
   
   if(bb_signal == SIGNAL_BUY) buy_votes++;
   else if(bb_signal == SIGNAL_SELL) sell_votes++;
   
   if(stoch_signal == SIGNAL_BUY) buy_votes++;
   else if(stoch_signal == SIGNAL_SELL) sell_votes++;
   
   // Require at least 2 indicators to agree
   if(buy_votes >= 2)
   {
      LogInfo(StringFormat("%s RANGE BUY signal: %d votes", symbol, buy_votes), "GetCombinedSignal");
      return SIGNAL_BUY;
   }
   else if(sell_votes >= 2)
   {
      LogInfo(StringFormat("%s RANGE SELL signal: %d votes", symbol, sell_votes), "GetCombinedSignal");
      return SIGNAL_SELL;
   }
   
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Apply early warning penalty                                      |
//+------------------------------------------------------------------+
double CFilter::ApplyEarlyWarningPenalty(const string symbol, double base_score)
{
   double penalty = 0.0;
   
   // Penalty for expanding Bollinger Bands
   double upper, middle, lower;
   double upper_prev, middle_prev, lower_prev;
   
   if(GetBollingerValues(symbol, upper, middle, lower, 0) &&
      GetBollingerValues(symbol, upper_prev, middle_prev, lower_prev, 1))
   {
      double width_current = upper - lower;
      double width_previous = upper_prev - lower_prev;
      
      if(width_current > width_previous * 1.1) // 10% expansion
      {
         penalty += 10.0;
         LogDebug(StringFormat("%s BB expansion penalty: %.1f", symbol, 10.0), "ApplyEarlyWarningPenalty");
      }
   }
   
   // Penalty for rising ATR
   double atr_current = GetAtrValue(symbol, 0);
   double atr_previous = GetAtrValue(symbol, 1);
   
   if(atr_current > atr_previous * 1.2) // 20% increase
   {
      penalty += 15.0;
      LogDebug(StringFormat("%s ATR rise penalty: %.1f", symbol, 15.0), "ApplyEarlyWarningPenalty");
   }
   
   // Penalty for extreme BB position
   double bb_position = GetBollingerPosition(symbol);
   if(MathAbs(bb_position) > 0.8)
   {
      penalty += 5.0;
      LogDebug(StringFormat("%s BB extreme position penalty: %.1f", symbol, 5.0), "ApplyEarlyWarningPenalty");
   }
   
   return base_score - penalty;
}

//+------------------------------------------------------------------+
//| Check if consolidation is ending                                |
//+------------------------------------------------------------------+
bool CFilter::IsConsolidationEnding(const string symbol)
{
   // Check if ADX is rising (trend might be starting)
   double adx_current = GetAdxValue(symbol, 0);
   double adx_previous = GetAdxValue(symbol, 1);
   
   if(adx_current > adx_previous && adx_current > 20.0)
      return true;
   
   // Check if BB is expanding rapidly
   double upper, middle, lower;
   double upper_prev, middle_prev, lower_prev;
   
   if(GetBollingerValues(symbol, upper, middle, lower, 0) &&
      GetBollingerValues(symbol, upper_prev, middle_prev, lower_prev, 1))
   {
      double expansion_ratio = (upper - lower) / (upper_prev - lower_prev);
      if(expansion_ratio > 1.15) // 15% expansion
         return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Get final signal for symbol                                      |
//+------------------------------------------------------------------+
ENUM_SIGNAL_DIRECTION CFilter::GetFinalSignal(const string symbol)
{
   double score = GetSymbolScore(symbol);
   return GetStrategySignal(symbol, score);
}

//+------------------------------------------------------------------+
//| Get indicator snapshot                                           |
//+------------------------------------------------------------------+
SIndicatorSnapshot CFilter::GetIndicatorSnapshot(const string symbol)
{
   SIndicatorSnapshot snapshot;
   ZeroMemory(snapshot);
   
   snapshot.symbol = symbol;
   snapshot.timestamp = TimeCurrent();
   
   // Get indicator values
   snapshot.rsi_value = GetRsiValue(symbol, 0);
   
   double upper, middle, lower;
   if(GetBollingerValues(symbol, upper, middle, lower, 0))
   {
      snapshot.bb_upper = upper;
      snapshot.bb_middle = middle;
      snapshot.bb_lower = lower;
   }
   
   double stoch_main, stoch_signal;
   if(GetStochasticValues(symbol, stoch_main, stoch_signal, 0))
   {
      snapshot.stoch_main = stoch_main;
      snapshot.stoch_signal = stoch_signal;
   }
   
   snapshot.atr_value = GetAtrValue(symbol, 0);
   snapshot.atr_percent = GetAtrPercent(symbol);
   snapshot.adx_value = GetAdxValue(symbol, 0);
   
   double ema_main, ema_50, ema_200;
   if(GetEmaValues(symbol, ema_main, ema_50, ema_200, 0))
   {
      snapshot.ema_fast = ema_main;
      snapshot.ema_50 = ema_50;
      snapshot.ema_200 = ema_200;
   }
   
   return snapshot;
}

//+------------------------------------------------------------------+
//| Get signal info for symbol                                       |
//+------------------------------------------------------------------+
SSignalInfo CFilter::GetSignalInfo(const string symbol)
{
   SSignalInfo info;
   ZeroMemory(info);
   
   info.symbol = symbol;
   info.last_update = TimeCurrent();
   
   info.score = GetSymbolScore(symbol);
   info.rsi_signal = GetRsiSignal(symbol);
   info.bb_signal = GetBollingerSignal(symbol);
   info.stoch_signal = CheckStochasticSignal(symbol);
   info.final_signal = GetFinalSignal(symbol);
   
   // Determine strategy type
   if(info.score <= m_settings.trend_threshold)
      info.strategy_type = STRATEGY_TREND;
   else if(info.score >= m_settings.scalping_min_score)
      info.strategy_type = STRATEGY_RANGE;
   
   info.grid_status = GRID_NONE; // Will be set by TradeManager
   
   return info;
}

//+------------------------------------------------------------------+
//| Check if symbol is supported                                     |
//+------------------------------------------------------------------+
bool CFilter::IsSymbolSupported(const string symbol)
{
   return (GetSymbolIndex(symbol) >= 0);
}

//+------------------------------------------------------------------+
//| Check if market is suitable for trading                         |
//+------------------------------------------------------------------+
bool CFilter::IsMarketSuitable(const string symbol)
{
   if(!ValidateIndicatorData(symbol))
      return false;
   
   // Check if market is open
   if(!IsMarketOpen(symbol))
      return false;
   
   // Check volatility
   double atr_percent = GetAtrPercent(symbol);
   if(atr_percent < 0.1 || atr_percent > 5.0) // Too low or too high volatility
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Print indicator values for debugging                            |
//+------------------------------------------------------------------+
void CFilter::PrintIndicatorValues(const string symbol)
{
   SIndicatorSnapshot snapshot = GetIndicatorSnapshot(symbol);
   
   g_Logger.Info(StringFormat("=== %s Indicator Values ===", symbol));
   g_Logger.Info(StringFormat("RSI: %s", DoubleToString(snapshot.rsi_value, 2)));
   g_Logger.Info(StringFormat("BB: %s / %s / %s", 
         DoubleToString(snapshot.bb_upper, 5),
         DoubleToString(snapshot.bb_middle, 5),
         DoubleToString(snapshot.bb_lower, 5)));
   g_Logger.Info(StringFormat("Stochastic: %s / %s", 
         DoubleToString(snapshot.stoch_main, 2),
         DoubleToString(snapshot.stoch_signal, 2)));
   g_Logger.Info(StringFormat("ATR: %s (%s%%)", 
         DoubleToString(snapshot.atr_value, 5),
         DoubleToString(snapshot.atr_percent, 2)));
   g_Logger.Info(StringFormat("ADX: %s", DoubleToString(snapshot.adx_value, 2)));
   g_Logger.Info(StringFormat("EMAs: %s / %s / %s", 
         DoubleToString(snapshot.ema_fast, 5),
         DoubleToString(snapshot.ema_50, 5),
         DoubleToString(snapshot.ema_200, 5)));
   g_Logger.Info("=============================");
}

//+------------------------------------------------------------------+
//| Get debug information                                            |
//+------------------------------------------------------------------+
string CFilter::GetDebugInfo(const string symbol)
{
   SSignalInfo info = GetSignalInfo(symbol);
   
   return StringFormat("%s: Score=%.1f, RSI=%s, BB=%s, Stoch=%s, Final=%s, Strategy=%s",
                      symbol,
                      info.score,
                      GetSignalText(info.rsi_signal),
                      GetSignalText(info.bb_signal), 
                      GetSignalText(info.stoch_signal),
                      GetSignalText(info.final_signal),
                      GetStrategyText(info.strategy_type));
}

//+------------------------------------------------------------------+
//| Check if new bar formed                                          |
//+------------------------------------------------------------------+
bool CFilter::IsNewBar(const string symbol)
{
   return ::IsNewBar(symbol, PERIOD_CURRENT);
}

//+------------------------------------------------------------------+
//| Normalize score to range                                         |
//+------------------------------------------------------------------+
double CFilter::NormalizeScore(double score, double min_val, double max_val)
{
   if(max_val == min_val)
      return 0.0;
   
   return ((score - min_val) / (max_val - min_val)) * 100.0;
}

//+------------------------------------------------------------------+
