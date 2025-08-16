//+------------------------------------------------------------------+
//| CurrencyStrength.mqh                                            |
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
//| Currency Strength Structure                                     |
//+------------------------------------------------------------------+
struct CurrencyStrengthData
{
   string            currency;                      // Currency code (USD, EUR, etc.)
   double            strength;                      // Current strength (-100 to +100)
   double            previous_strength;             // Previous strength for comparison
   double            strength_change;               // Change in strength
   datetime          last_update;                   // Last update time
   double            raw_values[];                  // Raw price changes for calculation
   int               pairs_count;                   // Number of pairs used in calculation
};

//+------------------------------------------------------------------+
//| CCurrencyStrength Class                                         |
//+------------------------------------------------------------------+
class CCurrencyStrength
{
private:
   // Settings and state
   SSettings         m_settings;                    // Engine settings
   bool              m_initialized;                 // Initialization flag
   
   // Currency data
   CurrencyStrengthData m_currencies[8];           // 8 major currencies
   string            m_currency_codes[8];           // Currency codes
   int               m_currencies_count;            // Number of currencies (should be 8)
   
   // Trading pairs matrix
   string            m_major_pairs[];               // All major pairs to analyze
   int               m_pairs_count;                 // Number of pairs
   
   // Calculation parameters
   int               m_calculation_period;          // Bars to look back for calculation
   ENUM_TIMEFRAMES   m_calculation_timeframe;       // Timeframe for calculation
   datetime          m_last_calculation_time;       // Last calculation time
   
   // Internal calculation methods
   bool InitializeCurrencies();
   bool InitializePairs();
   void CalculateSingleCurrencyStrength(int currency_index);
   double GetPairChange(const string symbol, int bars_back = 1);
   double NormalizeStrength(double raw_strength);
   
   // Pair analysis
   bool IsCurrencyInPair(const string currency, const string pair);
   bool IsBaseCurrency(const string currency, const string pair);
   int GetCurrencyIndex(const string currency);
   
   // Data validation
   bool ValidatePairData(const string symbol);
   void ResetCurrencyData();
   
   // Utility methods
   string ExtractBaseCurrency(const string symbol);
   string ExtractQuoteCurrency(const string symbol);
   double CalculateAverageStrength(const double &values[]);
   
public:
   // Constructor/Destructor
   CCurrencyStrength();
   ~CCurrencyStrength();
   
   // Initialization
   bool Initialize(const SSettings& settings);
   void Deinitialize();
   
   // Main calculation method
   void CalculateAllStrengths();
   void UpdateStrengths();
   
   // Individual currency methods
   double GetCurrencyStrength(const string currency_code);
   double GetCurrencyChange(const string currency_code);
   CurrencyStrengthData GetCurrencyData(const string currency_code);
   
   // Pair analysis methods
   double GetPairStrengthDifference(const string symbol);
   double GetPairStrengthScore(const string symbol);
   bool IsPairTrendingStrong(const string symbol, double threshold = 0.5);
   
   // Ranking methods
   void GetStrongestCurrencies(string &currencies[], double &strengths[], int count);
   void GetWeakestCurrencies(string &currencies[], double &strengths[], int count);
   string GetStrongestCurrency();
   string GetWeakestCurrency();
   
   // Analysis methods
   double GetAverageStrength();
   double GetStrengthRange();
   double GetMarketVolatility();
   
   // Information methods
   datetime GetLastUpdateTime() { return m_last_calculation_time; }
   bool IsDataCurrent(int max_age_seconds = 300);
   
   // Debug and display methods
   void PrintAllStrengths();
   void PrintCurrencyRanking();
   string GetStrengthReport();
   string GetPairAnalysis(const string symbol);
   
   // Historical analysis
   bool HasStrengthChanged(const string currency, double min_change = 0.1);
   ENUM_SIGNAL_DIRECTION GetCurrencyTrend(const string currency);
   
   // Validation
   bool IsValidCurrency(const string currency);
   bool IsCalculationCurrent();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CCurrencyStrength::CCurrencyStrength() : m_initialized(false),
                                         m_currencies_count(8),
                                         m_pairs_count(0),
                                         m_calculation_period(1),
                                         m_calculation_timeframe(PERIOD_H1),
                                         m_last_calculation_time(0)
{
   ZeroMemory(m_settings);
   
   // Initialize currency codes
   m_currency_codes[0] = "USD";
   m_currency_codes[1] = "EUR";
   m_currency_codes[2] = "GBP";
   m_currency_codes[3] = "JPY";
   m_currency_codes[4] = "AUD";
   m_currency_codes[5] = "CAD";
   m_currency_codes[6] = "CHF";
   m_currency_codes[7] = "NZD";
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CCurrencyStrength::~CCurrencyStrength()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize Currency Strength module                             |
//+------------------------------------------------------------------+
bool CCurrencyStrength::Initialize(const SSettings& settings)
{
   if(m_initialized)
      return true;
   
   m_settings = settings;
   
   // Initialize currencies
   if(!InitializeCurrencies())
   {
      LogError("Failed to initialize currencies", "CCurrencyStrength::Initialize");
      return false;
   }
   
   // Initialize trading pairs
   if(!InitializePairs())
   {
      LogError("Failed to initialize trading pairs", "CCurrencyStrength::Initialize");
      return false;
   }
   
   // Set calculation parameters
   m_calculation_timeframe = PERIOD_H1;  // Use H1 for currency strength calculation
   m_calculation_period = 1;             // Look at last 1 bar for changes
   
   m_initialized = true;
   
   LogInfo(StringFormat("Currency Strength initialized - %d currencies, %d pairs", 
                       m_currencies_count, m_pairs_count), "CCurrencyStrength::Initialize");
   
   // Perform initial calculation
   CalculateAllStrengths();
   
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize Currency Strength module                           |
//+------------------------------------------------------------------+
void CCurrencyStrength::Deinitialize()
{
   if(!m_initialized)
      return;
   
   // Free arrays
   for(int i = 0; i < m_currencies_count; i++)
   {
      ArrayFree(m_currencies[i].raw_values);
   }
   
   ArrayFree(m_major_pairs);
   
   m_initialized = false;
   
   LogInfo("Currency Strength deinitialized", "CCurrencyStrength::Deinitialize");
}

//+------------------------------------------------------------------+
//| Initialize currencies data                                       |
//+------------------------------------------------------------------+
bool CCurrencyStrength::InitializeCurrencies()
{
   for(int i = 0; i < m_currencies_count; i++)
   {
      m_currencies[i].currency = m_currency_codes[i];
      m_currencies[i].strength = 0.0;
      m_currencies[i].previous_strength = 0.0;
      m_currencies[i].strength_change = 0.0;
      m_currencies[i].last_update = 0;
      m_currencies[i].pairs_count = 0;
      
      ArrayResize(m_currencies[i].raw_values, 50); // Space for raw calculation values
      ArrayInitialize(m_currencies[i].raw_values, 0.0);
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Initialize trading pairs for analysis                           |
//+------------------------------------------------------------------+
bool CCurrencyStrength::InitializePairs()
{
   // Define major pairs for currency strength calculation
   string temp_pairs[] = {
      "EURUSD", "GBPUSD", "USDJPY", "USDCHF", "AUDUSD", "USDCAD", "NZDUSD",
      "EURJPY", "GBPJPY", "EURGBP", "EURAUD", "EURCHF", "EURCAD", "EURNZD",
      "GBPAUD", "GBPCHF", "GBPCAD", "GBPNZD",
      "AUDJPY", "AUDCHF", "AUDCAD", "AUDNZD",
      "CHFJPY", "CADCHF", "CADJPY",
      "NZDJPY", "NZDCHF", "NZDCAD"
   };
   
   int temp_count = ArraySize(temp_pairs);
   
   // Validate which pairs are available
   ArrayResize(m_major_pairs, temp_count);
   m_pairs_count = 0;
   
   for(int i = 0; i < temp_count; i++)
   {
      if(SymbolSelect(temp_pairs[i], true))
      {
         // Check if we can get price data
         double test_data[];
         if(CopyClose(temp_pairs[i], m_calculation_timeframe, 0, 2, test_data) >= 2)
         {
            m_major_pairs[m_pairs_count] = temp_pairs[i];
            m_pairs_count++;
         }
         else
         {
            LogDebug(StringFormat("Pair %s not available for currency strength calculation", temp_pairs[i]), "InitializePairs");
         }
      }
   }
   
   ArrayResize(m_major_pairs, m_pairs_count);
   
   LogInfo(StringFormat("Initialized %d pairs for currency strength calculation", m_pairs_count), "InitializePairs");
   
   return (m_pairs_count > 0);
}

//+------------------------------------------------------------------+
//| Calculate strength for all currencies                           |
//+------------------------------------------------------------------+
void CCurrencyStrength::CalculateAllStrengths()
{
   if(!m_initialized)
      return;
   
   MEASURE_PERFORMANCE("CalculateCurrencyStrengths");
   
   LogDebug("Calculating currency strengths", "CalculateAllStrengths");
   
   // Reset calculation data
   ResetCurrencyData();
   
   // Calculate strength for each currency
   for(int i = 0; i < m_currencies_count; i++)
   {
      CalculateSingleCurrencyStrength(i);
   }
   
   m_last_calculation_time = TimeCurrent();
   
   LogDebug("Currency strength calculation completed", "CalculateAllStrengths");
}

//+------------------------------------------------------------------+
//| Update currency strengths (alias for CalculateAllStrengths)     |
//+------------------------------------------------------------------+
void CCurrencyStrength::UpdateStrengths()
{
   CalculateAllStrengths();
}

//+------------------------------------------------------------------+
//| Calculate strength for single currency                          |
//+------------------------------------------------------------------+
void CCurrencyStrength::CalculateSingleCurrencyStrength(int currency_index)
{
   if(currency_index < 0 || currency_index >= m_currencies_count)
      return;
   
   string currency_code = m_currencies[currency_index].currency;
   
   double total_change = 0.0;
   int valid_pairs = 0;
   
   // Go through all pairs and calculate changes for this currency
   for(int i = 0; i < m_pairs_count; i++)
   {
      string pair = m_major_pairs[i];
      
      if(!IsCurrencyInPair(currency_code, pair))
         continue;
      
      if(!ValidatePairData(pair))
         continue;
      
      double pair_change = GetPairChange(pair, m_calculation_period);
      if(pair_change == 0.0)
         continue; // Skip if no valid data
      
      // If currency is quote currency, invert the change
      if(!IsBaseCurrency(currency_code, pair))
         pair_change = -pair_change;
      
      total_change += pair_change;
      valid_pairs++;
      
      // Store raw value for debugging
      if(valid_pairs <= ArraySize(m_currencies[currency_index].raw_values))
         m_currencies[currency_index].raw_values[valid_pairs - 1] = pair_change;
   }
   
   m_currencies[currency_index].pairs_count = valid_pairs;
   
   if(valid_pairs > 0)
   {
      // Calculate average change
      double average_change = total_change / valid_pairs;
      
      // Store previous strength
      m_currencies[currency_index].previous_strength = m_currencies[currency_index].strength;
      
      // Normalize and store new strength
      m_currencies[currency_index].strength = NormalizeStrength(average_change * 10000); // Convert to more readable scale
      
      // Calculate change
      m_currencies[currency_index].strength_change = m_currencies[currency_index].strength - m_currencies[currency_index].previous_strength;
      
      m_currencies[currency_index].last_update = TimeCurrent();
      
      LogDebug(StringFormat("Currency %s: Strength=%.2f, Change=%.2f, Pairs=%d", 
                           currency_code, m_currencies[currency_index].strength, m_currencies[currency_index].strength_change, valid_pairs), 
               "CalculateSingleCurrencyStrength");
   }
   else
   {
      LogWarning(StringFormat("No valid pairs found for currency %s", currency_code), "CalculateSingleCurrencyStrength");
   }
}

//+------------------------------------------------------------------+
//| Get price change for pair                                       |
//+------------------------------------------------------------------+
double CCurrencyStrength::GetPairChange(const string symbol, int bars_back = 1)
{
   double close_data[];
   
   if(CopyClose(symbol, m_calculation_timeframe, 0, bars_back + 1, close_data) < bars_back + 1)
      return 0.0;
   
   if(close_data[0] == 0.0 || close_data[bars_back] == 0.0)
      return 0.0;
   
   // Calculate percentage change
   double change = (close_data[0] - close_data[bars_back]) / close_data[bars_back];
   
   return change;
}

//+------------------------------------------------------------------+
//| Normalize strength value                                         |
//+------------------------------------------------------------------+
double CCurrencyStrength::NormalizeStrength(double raw_strength)
{
   // Clamp to reasonable range and scale
   double normalized = raw_strength;
   
   // Apply limits
   if(normalized > 100.0) normalized = 100.0;
   if(normalized < -100.0) normalized = -100.0;
   
   return normalized;
}

//+------------------------------------------------------------------+
//| Check if currency is in pair                                    |
//+------------------------------------------------------------------+
bool CCurrencyStrength::IsCurrencyInPair(const string currency, const string pair)
{
   return (StringFind(pair, currency) >= 0);
}

//+------------------------------------------------------------------+
//| Check if currency is base currency in pair                      |
//+------------------------------------------------------------------+
bool CCurrencyStrength::IsBaseCurrency(const string currency, const string pair)
{
   if(StringLen(pair) < 6) return false;
   
   string base = StringSubstr(pair, 0, 3);
   return (base == currency);
}

//+------------------------------------------------------------------+
//| Get currency index                                              |
//+------------------------------------------------------------------+
int CCurrencyStrength::GetCurrencyIndex(const string currency)
{
   for(int i = 0; i < m_currencies_count; i++)
   {
      if(m_currencies[i].currency == currency)
         return i;
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Get currency strength by code                                   |
//+------------------------------------------------------------------+
double CCurrencyStrength::GetCurrencyStrength(const string currency_code)
{
   int index = GetCurrencyIndex(currency_code);
   if(index >= 0)
      return m_currencies[index].strength;
   
   return 0.0;
}

//+------------------------------------------------------------------+
//| Get currency strength change                                    |
//+------------------------------------------------------------------+
double CCurrencyStrength::GetCurrencyChange(const string currency_code)
{
   int index = GetCurrencyIndex(currency_code);
   if(index >= 0)
      return m_currencies[index].strength_change;
   
   return 0.0;
}

//+------------------------------------------------------------------+
//| Get currency data structure                                     |
//+------------------------------------------------------------------+
CurrencyStrengthData CCurrencyStrength::GetCurrencyData(const string currency_code)
{
   CurrencyStrengthData empty_data;
   ZeroMemory(empty_data);
   
   int index = GetCurrencyIndex(currency_code);
   if(index >= 0)
      return m_currencies[index];
   
   return empty_data;
}

//+------------------------------------------------------------------+
//| Get pair strength difference                                    |
//+------------------------------------------------------------------+
double CCurrencyStrength::GetPairStrengthDifference(const string symbol)
{
   if(StringLen(symbol) < 6)
      return 0.0;
   
   string base = ExtractBaseCurrency(symbol);
   string quote = ExtractQuoteCurrency(symbol);
   
   double base_strength = GetCurrencyStrength(base);
   double quote_strength = GetCurrencyStrength(quote);
   
   return (base_strength - quote_strength);
}

//+------------------------------------------------------------------+
//| Get pair strength score                                         |
//+------------------------------------------------------------------+
double CCurrencyStrength::GetPairStrengthScore(const string symbol)
{
   double difference = GetPairStrengthDifference(symbol);
   
   // Convert difference to score (0-100)
   double score = MathAbs(difference);
   
   // Normalize to 0-100 scale
   if(score > 100.0) score = 100.0;
   
   return score;
}

//+------------------------------------------------------------------+
//| Check if pair is trending strongly                             |
//+------------------------------------------------------------------+
bool CCurrencyStrength::IsPairTrendingStrong(const string symbol, double threshold = 0.5)
{
   double difference = MathAbs(GetPairStrengthDifference(symbol));
   return (difference >= threshold);
}

//+------------------------------------------------------------------+
//| Extract base currency from symbol                               |
//+------------------------------------------------------------------+
string CCurrencyStrength::ExtractBaseCurrency(const string symbol)
{
   if(StringLen(symbol) >= 3)
      return StringSubstr(symbol, 0, 3);
   return "";
}

//+------------------------------------------------------------------+
//| Extract quote currency from symbol                              |
//+------------------------------------------------------------------+
string CCurrencyStrength::ExtractQuoteCurrency(const string symbol)
{
   if(StringLen(symbol) >= 6)
      return StringSubstr(symbol, 3, 3);
   return "";
}

//+------------------------------------------------------------------+
//| Validate pair data                                              |
//+------------------------------------------------------------------+
bool CCurrencyStrength::ValidatePairData(const string symbol)
{
   double test_data[];
   return (CopyClose(symbol, m_calculation_timeframe, 0, 2, test_data) >= 2);
}

//+------------------------------------------------------------------+
//| Reset currency calculation data                                 |
//+------------------------------------------------------------------+
void CCurrencyStrength::ResetCurrencyData()
{
   for(int i = 0; i < m_currencies_count; i++)
   {
      m_currencies[i].pairs_count = 0;
      ArrayInitialize(m_currencies[i].raw_values, 0.0);
   }
}

//+------------------------------------------------------------------+
//| Get strongest currencies                                         |
//+------------------------------------------------------------------+
void CCurrencyStrength::GetStrongestCurrencies(string &currencies[], double &strengths[], int count)
{
   if(count > m_currencies_count) count = m_currencies_count;
   
   ArrayResize(currencies, count);
   ArrayResize(strengths, count);
   
   // Create sorted indices
   int indices[];
   ArrayResize(indices, m_currencies_count);
   
   for(int i = 0; i < m_currencies_count; i++)
      indices[i] = i;
   
   // Simple bubble sort by strength (descending)
   for(int i = 0; i < m_currencies_count - 1; i++)
   {
      for(int j = 0; j < m_currencies_count - 1 - i; j++)
      {
         if(m_currencies[indices[j]].strength < m_currencies[indices[j + 1]].strength)
         {
            int temp = indices[j];
            indices[j] = indices[j + 1];
            indices[j + 1] = temp;
         }
      }
   }
   
   // Fill results
   for(int i = 0; i < count; i++)
   {
      currencies[i] = m_currencies[indices[i]].currency;
      strengths[i] = m_currencies[indices[i]].strength;
   }
}

//+------------------------------------------------------------------+
//| Get weakest currencies                                          |
//+------------------------------------------------------------------+
void CCurrencyStrength::GetWeakestCurrencies(string &currencies[], double &strengths[], int count)
{
   if(count > m_currencies_count) count = m_currencies_count;
   
   ArrayResize(currencies, count);
   ArrayResize(strengths, count);
   
   // Create sorted indices
   int indices[];
   ArrayResize(indices, m_currencies_count);
   
   for(int i = 0; i < m_currencies_count; i++)
      indices[i] = i;
   
   // Simple bubble sort by strength (ascending)
   for(int i = 0; i < m_currencies_count - 1; i++)
   {
      for(int j = 0; j < m_currencies_count - 1 - i; j++)
      {
         if(m_currencies[indices[j]].strength > m_currencies[indices[j + 1]].strength)
         {
            int temp = indices[j];
            indices[j] = indices[j + 1];
            indices[j + 1] = temp;
         }
      }
   }
   
   // Fill results
   for(int i = 0; i < count; i++)
   {
      currencies[i] = m_currencies[indices[i]].currency;
      strengths[i] = m_currencies[indices[i]].strength;
   }
}

//+------------------------------------------------------------------+
//| Get strongest currency                                          |
//+------------------------------------------------------------------+
string CCurrencyStrength::GetStrongestCurrency()
{
   double max_strength = -999999.0;
   string strongest = "";
   
   for(int i = 0; i < m_currencies_count; i++)
   {
      if(m_currencies[i].strength > max_strength)
      {
         max_strength = m_currencies[i].strength;
         strongest = m_currencies[i].currency;
      }
   }
   
   return strongest;
}

//+------------------------------------------------------------------+
//| Get weakest currency                                            |
//+------------------------------------------------------------------+
string CCurrencyStrength::GetWeakestCurrency()
{
   double min_strength = 999999.0;
   string weakest = "";
   
   for(int i = 0; i < m_currencies_count; i++)
   {
      if(m_currencies[i].strength < min_strength)
      {
         min_strength = m_currencies[i].strength;
         weakest = m_currencies[i].currency;
      }
   }
   
   return weakest;
}

//+------------------------------------------------------------------+
//| Print all currency strengths                                   |
//+------------------------------------------------------------------+
void CCurrencyStrength::PrintAllStrengths()
{
   g_Logger.Info("=== Currency Strengths ===");
   g_Logger.Info(StringFormat("Last Update: %s", TimeToString(m_last_calculation_time, TIME_SECONDS)));
   
   for(int i = 0; i < m_currencies_count; i++)
   {
      g_Logger.Info(StringFormat("%s: %.2f (Change: %+.2f, Pairs: %d)", 
                        m_currencies[i].currency, 
                        m_currencies[i].strength, 
                        m_currencies[i].strength_change,
                        m_currencies[i].pairs_count));
   }
   
   g_Logger.Info(StringFormat("Strongest: %s", GetStrongestCurrency()));
   g_Logger.Info(StringFormat("Weakest: %s", GetWeakestCurrency()));
   g_Logger.Info("==========================");
}

//+------------------------------------------------------------------+
//| Print currency ranking                                          |
//+------------------------------------------------------------------+
void CCurrencyStrength::PrintCurrencyRanking()
{
   string strongest_currencies[];
   double strongest_values[];
   
   GetStrongestCurrencies(strongest_currencies, strongest_values, m_currencies_count);
   
   g_Logger.Info("=== Currency Strength Ranking ===");
   
   for(int i = 0; i < ArraySize(strongest_currencies); i++)
   {
      g_Logger.Info(StringFormat("%d. %s: %.2f", i + 1, strongest_currencies[i], strongest_values[i]));
   }
   
   g_Logger.Info("==================================");
}

//+------------------------------------------------------------------+
//| Get strength report                                            |
//+------------------------------------------------------------------+
string CCurrencyStrength::GetStrengthReport()
{
   string report = StringFormat("Currency Strength Report (Updated: %s)\n", 
                               TimeToString(m_last_calculation_time, TIME_SECONDS));
   
   for(int i = 0; i < m_currencies_count; i++)
   {
      report += StringFormat("%s: %.2f (%+.2f)\n", 
                            m_currencies[i].currency, 
                            m_currencies[i].strength, 
                            m_currencies[i].strength_change);
   }
   
   return report;
}

//+------------------------------------------------------------------+
//| Get pair analysis                                               |
//+------------------------------------------------------------------+
string CCurrencyStrength::GetPairAnalysis(const string symbol)
{
   string base = ExtractBaseCurrency(symbol);
   string quote = ExtractQuoteCurrency(symbol);
   
   double base_strength = GetCurrencyStrength(base);
   double quote_strength = GetCurrencyStrength(quote);
   double difference = base_strength - quote_strength;
   
   string analysis = StringFormat("Pair Analysis: %s\n", symbol);
   analysis += StringFormat("Base (%s): %.2f\n", base, base_strength);
   analysis += StringFormat("Quote (%s): %.2f\n", quote, quote_strength);
   analysis += StringFormat("Difference: %.2f\n", difference);
   
   if(difference > 0.5)
      analysis += "Bias: BULLISH (Strong base)\n";
   else if(difference < -0.5)
      analysis += "Bias: BEARISH (Strong quote)\n";
   else
      analysis += "Bias: NEUTRAL (Balanced)\n";
   
   return analysis;
}

//+------------------------------------------------------------------+
//| Check if data is current                                        |
//+------------------------------------------------------------------+
bool CCurrencyStrength::IsDataCurrent(int max_age_seconds = 300)
{
   return ((TimeCurrent() - m_last_calculation_time) <= max_age_seconds);
}

//+------------------------------------------------------------------+
//| Check if currency is valid                                      |
//+------------------------------------------------------------------+
bool CCurrencyStrength::IsValidCurrency(const string currency)
{
   return (GetCurrencyIndex(currency) >= 0);
}

//+------------------------------------------------------------------+
//| Check if calculation is current                                 |
//+------------------------------------------------------------------+
bool CCurrencyStrength::IsCalculationCurrent()
{
   return IsDataCurrent(300); // 5 minutes
}

//+------------------------------------------------------------------+
//| Check if currency strength has changed significantly           |
//+------------------------------------------------------------------+
bool CCurrencyStrength::HasStrengthChanged(const string currency, double min_change = 0.1)
{
   double change = MathAbs(GetCurrencyChange(currency));
   return (change >= min_change);
}

//+------------------------------------------------------------------+
//| Get currency trend direction                                    |
//+------------------------------------------------------------------+
ENUM_SIGNAL_DIRECTION CCurrencyStrength::GetCurrencyTrend(const string currency)
{
   double change = GetCurrencyChange(currency);
   
   if(change > 0.2)
      return SIGNAL_BUY;  // Strengthening
   else if(change < -0.2)
      return SIGNAL_SELL; // Weakening
   else
      return SIGNAL_NONE; // Neutral
}

//+------------------------------------------------------------------+
