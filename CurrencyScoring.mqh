//+------------------------------------------------------------------+
//| CurrencyScoring.mqh                                             |
//| Copyright 2024, SuppResist                                       |
//| https://www.mql5.com                                             |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, SuppResist"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "SuppResist.mqh"
#include "Logger.mqh"
#include "SR_Engine.mqh"
#include "CurrencyStrength.mqh"

//+------------------------------------------------------------------+
//| Currency Score Structure                                        |
//+------------------------------------------------------------------+
struct CurrencyScore
{
   // Default constructor
   CurrencyScore()
   {
      Reset();
   }

   // Copy constructor
   CurrencyScore(const CurrencyScore &other)
   {
      symbol = other.symbol;
      total_score = other.total_score;
      sr_score = other.sr_score;
      volatility_score = other.volatility_score;
      strength_score = other.strength_score;
      trend_score = other.trend_score;
      last_update = other.last_update;
      sr_levels_count = other.sr_levels_count;
      avg_sr_strength = other.avg_sr_strength;
      atr_percent = other.atr_percent;
      strength_difference = other.strength_difference;
      trend_clear = other.trend_clear;
      trend_direction = other.trend_direction;
      rank = other.rank;
      is_tradeable = other.is_tradeable;
      notes = other.notes;
   }
   
   void Reset()
   {
      symbol = "";
      total_score = 0.0;
      sr_score = 0.0;
      volatility_score = 0.0;
      strength_score = 0.0;
      trend_score = 0.0;
      last_update = 0;
      sr_levels_count = 0;
      avg_sr_strength = 0.0;
      atr_percent = 0.0;
      strength_difference = 0.0;
      trend_clear = false;
      trend_direction = SIGNAL_NONE;
      rank = 0;
      is_tradeable = false;
      notes = "";
   }
   
   string            symbol;                        // Currency pair symbol
   double            total_score;                   // Total combined score (0-100)
   double            sr_score;                      // S&R quality score (0-100)
   double            volatility_score;              // Volatility score (0-100)
   double            strength_score;                // Currency strength score (0-100)
   double            trend_score;                   // Trend clarity score (0-100)
   datetime          last_update;                   // Last update time
   
   // Detailed breakdown
   int               sr_levels_count;               // Number of S&R levels
   double            avg_sr_strength;               // Average S&R strength
   double            atr_percent;                   // Current ATR percentage
   double            strength_difference;           // Base-Quote strength difference
   bool              trend_clear;                   // Is trend direction clear
   ENUM_SIGNAL_DIRECTION trend_direction;          // Current trend direction
   
   // Ranking info
   int               rank;                          // Current rank (1 = best)
   bool              is_tradeable;                  // Meets minimum criteria for trading
   string            notes;                         // Additional notes
};

//+------------------------------------------------------------------+
//| CCurrencyScoring Class                                          |
//+------------------------------------------------------------------+
class CCurrencyScoring
{
private:
   // Core components
   SSettings         m_settings;                    // Settings
   CSR_Engine*       m_sr_engine;                   // S&R engine reference
   CCurrencyStrength* m_currency_strength;          // Currency strength reference
   bool              m_initialized;                 // Initialization flag
   
   // Scoring data
   CurrencyScore     m_scores[];                    // Currency scores array
   int               m_scores_count;                // Number of scored currencies
   string            m_symbols[];                   // Symbols to analyze
   int               m_symbols_count;               // Number of symbols
   
   // Scoring weights (should total 100%)
   double            m_sr_weight;                   // S&R quality weight
   double            m_volatility_weight;           // Volatility weight  
   double            m_strength_weight;             // Currency strength weight
   double            m_trend_weight;                // Trend clarity weight
   
   // Scoring parameters
   double            m_optimal_atr_min;             // Minimum optimal ATR%
   double            m_optimal_atr_max;             // Maximum optimal ATR%
   double            m_min_strength_diff;           // Minimum strength difference
   double            m_min_total_score;             // Minimum score for trading
   
   // Update tracking
   datetime          m_last_calculation_time;       // Last calculation time
   int               m_calculation_interval;        // Calculation interval (seconds)
   
   // Private calculation methods
   double CalculateSRScore(const string symbol);
   double CalculateVolatilityScore(const string symbol);
   double CalculateStrengthScore(const string symbol);
   double CalculateTrendScore(const string symbol);
   
   double CombineScores(double sr_score, double volatility_score, 
                        double strength_score, double trend_score);
   
   void SortScoresByTotal();
   void UpdateRankings();
   void ValidateScores();
   
   // Utility methods
   double NormalizeScore(double value, double min_val, double max_val);
   double GetATRPercent(const string symbol);
   bool IsTrendClear(const string symbol, ENUM_SIGNAL_DIRECTION& direction);
   
public:
   // Constructor/Destructor
   CCurrencyScoring();
   ~CCurrencyScoring();
   
   // Initialization
   bool Initialize(const SSettings& settings, CSR_Engine* sr_engine, CCurrencyStrength* currency_strength);
   void Deinitialize();
   
   // Main scoring methods
   void CalculateAllScores();
   void UpdateScores();
   void RecalculateScores();
   
   // Individual scoring
   CurrencyScore CalculateSymbolScore(const string symbol);
   double GetSymbolTotalScore(const string symbol);
   
   // Results access
   void GetTopPairs(string &symbols[], double &scores[], int count);
   void GetTradeablePairs(string &symbols[], double &scores[]);
   CurrencyScore GetSymbolScore(const string symbol);
   CurrencyScore GetBestPair();
   
   // Ranking methods
   int GetSymbolRank(const string symbol);
   string GetTopRankedSymbol();
   bool IsSymbolTradeable(const string symbol);
   
   // Analysis methods
   double GetAverageScore();
   double GetScoreRange();
   int GetTradeablePairsCount();
   
   // Settings and configuration
   void SetScoringWeights(double sr_weight, double vol_weight, double str_weight, double trend_weight);
   void SetVolatilityRange(double min_atr_percent, double max_atr_percent);
   void SetMinimumScore(double min_score);
   void SetCalculationInterval(int seconds);
   
   // Information methods
   datetime GetLastUpdateTime() { return m_last_calculation_time; }
   bool IsCalculationCurrent(int max_age_seconds = 300);
   int GetAnalyzedSymbolsCount() { return m_symbols_count; }
   
   // Debug and reporting
   void PrintAllScores();
   void PrintTopPairs(int count = 10);
   void PrintDetailedScore(const string symbol);
   string GetScoringReport();
   string GetSymbolAnalysis(const string symbol);
   
   // Export methods
   bool ExportScoresToCSV(const string filename);
   string GetScoresJSON();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CCurrencyScoring::CCurrencyScoring() : m_initialized(false),
                                       m_sr_engine(NULL),
                                       m_currency_strength(NULL),
                                       m_scores_count(0),
                                       m_symbols_count(0),
                                       m_last_calculation_time(0),
                                       m_calculation_interval(300)
{
   ZeroMemory(m_settings);
   
   // Set default weights (total should be 100%)
   m_sr_weight = 40.0;           // S&R Quality: 40%
   m_volatility_weight = 25.0;   // Volatility: 25%
   m_strength_weight = 20.0;     // Currency Strength: 20%
   m_trend_weight = 15.0;        // Trend Clarity: 15%
   
   // Set default parameters
   m_optimal_atr_min = 0.05;     // 0.05% minimum volatility
   m_optimal_atr_max = 0.20;     // 0.20% maximum volatility
   m_min_strength_diff = 0.10;   // 0.10 minimum strength difference
   m_min_total_score = 60.0;     // 60.0 minimum score for trading
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CCurrencyScoring::~CCurrencyScoring()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize currency scoring system                              |
//+------------------------------------------------------------------+
bool CCurrencyScoring::Initialize(const SSettings& settings, CSR_Engine* sr_engine, CCurrencyStrength* currency_strength)
{
   if(m_initialized)
      return true;
   
   if(sr_engine == NULL || currency_strength == NULL)
   {
      LogError("SR Engine or Currency Strength reference is NULL", "CCurrencyScoring::Initialize");
      return false;
   }
   
   m_settings = settings;
   m_sr_engine = sr_engine;
   m_currency_strength = currency_strength;
   m_symbols_count = settings.symbols_count;
   
   if(m_symbols_count <= 0)
   {
      LogError("No symbols provided for scoring", "CCurrencyScoring::Initialize");
      return false;
   }
   
   // Copy symbols
   ArrayResize(m_symbols, m_symbols_count);
   for(int i = 0; i < m_symbols_count; i++)
   {
      m_symbols[i] = settings.symbols[i];
   }
   
   // Initialize scores array
   ArrayResize(m_scores, m_symbols_count);
   m_scores_count = m_symbols_count;
   
   // Initialize all scores
   for(int i = 0; i < m_scores_count; i++)
   {
      ZeroMemory(m_scores[i]);
      m_scores[i].symbol = m_symbols[i];
      m_scores[i].rank = i + 1;
      m_scores[i].is_tradeable = false;
   }
   
   m_initialized = true;
   
   LogInfo(StringFormat("Currency Scoring initialized for %d symbols", m_symbols_count), "CCurrencyScoring::Initialize");
   
   // Perform initial calculation
   CalculateAllScores();
   
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize currency scoring system                           |
//+------------------------------------------------------------------+
void CCurrencyScoring::Deinitialize()
{
   if(!m_initialized)
      return;
   
   ArrayFree(m_symbols);
   ArrayFree(m_scores);
   
   m_symbols_count = 0;
   m_scores_count = 0;
   m_initialized = false;
   
   LogInfo("Currency Scoring deinitialized", "CCurrencyScoring::Deinitialize");
}

//+------------------------------------------------------------------+
//| Calculate scores for all symbols                               |
//+------------------------------------------------------------------+
void CCurrencyScoring::CalculateAllScores()
{
   if(!m_initialized)
      return;
   
   MEASURE_PERFORMANCE("CalculateCurrencyScores");
   
   LogDebug("Calculating currency scores for all symbols", "CalculateAllScores");
   
   // Calculate individual scores
   for(int i = 0; i < m_scores_count; i++)
   {
      m_scores[i] = CalculateSymbolScore(m_symbols[i]);
   }
   
   // Sort and rank
   SortScoresByTotal();
   UpdateRankings();
   ValidateScores();
   
   m_last_calculation_time = TimeCurrent();
   
   LogInfo(StringFormat("Currency scoring completed - %d symbols analyzed", m_scores_count), "CalculateAllScores");
}

//+------------------------------------------------------------------+
//| Update scores (alias for CalculateAllScores)                   |
//+------------------------------------------------------------------+
void CCurrencyScoring::UpdateScores()
{
   CalculateAllScores();
}

//+------------------------------------------------------------------+
//| Recalculate scores (force refresh)                             |
//+------------------------------------------------------------------+
void CCurrencyScoring::RecalculateScores()
{
   CalculateAllScores();
}

//+------------------------------------------------------------------+
//| Calculate score for individual symbol                          |
//+------------------------------------------------------------------+
CurrencyScore CCurrencyScoring::CalculateSymbolScore(const string symbol)
{
   CurrencyScore score;
   ZeroMemory(score);
   
   score.symbol = symbol;
   score.last_update = TimeCurrent();
   
   if(!m_initialized)
      return score;
   
   // Calculate individual component scores
   score.sr_score = CalculateSRScore(symbol);
   score.volatility_score = CalculateVolatilityScore(symbol);
   score.strength_score = CalculateStrengthScore(symbol);
   score.trend_score = CalculateTrendScore(symbol);
   
   // Combine scores with weights
   score.total_score = CombineScores(score.sr_score, score.volatility_score, 
                                    score.strength_score, score.trend_score);
   
   // Fill additional details
   score.sr_levels_count = m_sr_engine.GetActiveLevelsCount(symbol);
   score.avg_sr_strength = m_sr_engine.GetAverageStrength(symbol);
   score.atr_percent = GetATRPercent(symbol);
   score.strength_difference = m_currency_strength.GetPairStrengthDifference(symbol);
   score.trend_clear = IsTrendClear(symbol, score.trend_direction);
   
   // Determine if tradeable
   score.is_tradeable = (score.total_score >= m_min_total_score);
   
   // Add notes
   if(!score.is_tradeable)
      score.notes = StringFormat("Score %.1f below minimum %.1f", score.total_score, m_min_total_score);
   else
      score.notes = "Meets trading criteria";
   
   LogDebug(StringFormat("%s Score: Total=%.1f (SR=%.1f, Vol=%.1f, Str=%.1f, Trend=%.1f)", 
                         symbol, score.total_score, score.sr_score, score.volatility_score, 
                         score.strength_score, score.trend_score), "CalculateSymbolScore");
   
   return score;
}

//+------------------------------------------------------------------+
//| Calculate S&R quality score                                    |
//+------------------------------------------------------------------+
double CCurrencyScoring::CalculateSRScore(const string symbol)
{
   if(m_sr_engine == NULL)
      return 0.0;
   
   // Get S&R levels count and average strength
   int levels_count = m_sr_engine.GetActiveLevelsCount(symbol);
   double avg_strength = m_sr_engine.GetAverageStrength(symbol);
   
   // Score based on number of levels (more levels = more opportunities)
   double levels_score = MathMin(100.0, (levels_count / 10.0) * 100.0); // Max at 10 levels
   
   // Score based on average strength
   double strength_score = MathMin(100.0, (avg_strength / 50.0) * 100.0); // Max at strength 50
   
   // Combine (50% levels, 50% strength)
   double combined_score = (levels_score * 0.5) + (strength_score * 0.5);
   
   // Check if current price is near strong S&R level (bonus)
   double current_price = SymbolInfoDouble(symbol, SYMBOL_BID);
   SRLevel nearest_support, nearest_resistance;
   
   if(m_sr_engine.GetNearestSRLevels(symbol, current_price, nearest_support, nearest_resistance))
   {
      // Bonus if near strong levels
      if((nearest_support.is_active && nearest_support.strength >= 20) ||
         (nearest_resistance.is_active && nearest_resistance.strength >= 20))
      {
         combined_score += 10.0; // 10% bonus
      }
   }
   
   return MathMin(100.0, combined_score);
}

//+------------------------------------------------------------------+
//| Calculate volatility score                                     |
//+------------------------------------------------------------------+
double CCurrencyScoring::CalculateVolatilityScore(const string symbol)
{
   double atr_percent = GetATRPercent(symbol);
   
   if(atr_percent <= 0)
      return 0.0;
   
   // Optimal range scoring
   if(atr_percent >= m_optimal_atr_min && atr_percent <= m_optimal_atr_max)
   {
      // Within optimal range = high score
      return 100.0;
   }
   else if(atr_percent < m_optimal_atr_min)
   {
      // Too low volatility - scale down
      return (atr_percent / m_optimal_atr_min) * 100.0;
   }
   else
   {
      // Too high volatility - scale down  
      double excess = atr_percent - m_optimal_atr_max;
      double penalty = (excess / m_optimal_atr_max) * 50.0; // Penalty up to 50%
      return MathMax(0.0, 100.0 - penalty);
   }
}

//+------------------------------------------------------------------+
//| Calculate currency strength score                              |
//+------------------------------------------------------------------+
double CCurrencyScoring::CalculateStrengthScore(const string symbol)
{
   if(m_currency_strength == NULL)
      return 0.0;
   
   double strength_diff = m_currency_strength.GetPairStrengthDifference(symbol);
   double abs_diff = MathAbs(strength_diff);
   
   // Score based on strength difference magnitude
   double score = 0.0;
   
   if(abs_diff >= m_min_strength_diff)
   {
      // Strong difference = high score
      score = MathMin(100.0, (abs_diff / 2.0) * 100.0); // Max at 2.0 difference
   }
   else
   {
      // Weak difference = low score
      score = (abs_diff / m_min_strength_diff) * 50.0; // Max 50% for weak difference
   }
   
   return score;
}

//+------------------------------------------------------------------+
//| Calculate trend clarity score                                  |
//+------------------------------------------------------------------+
double CCurrencyScoring::CalculateTrendScore(const string symbol)
{
   ENUM_SIGNAL_DIRECTION trend_direction;
   bool trend_clear = IsTrendClear(symbol, trend_direction);
   
   if(!trend_clear)
      return 30.0; // Low score for unclear trend
   
   // Check trend strength using multiple timeframes
   double score = 60.0; // Base score for clear trend
   
   // Add bonus for strong trend confirmation
   // This could include EMA alignment, momentum, etc.
   
   // Simple implementation: check if currency strength supports the trend
   if(m_currency_strength != NULL)
   {
      double strength_diff = m_currency_strength.GetPairStrengthDifference(symbol);
      
      // If trend direction matches strength difference, give bonus
      if((trend_direction == SIGNAL_BUY && strength_diff > 0) ||
         (trend_direction == SIGNAL_SELL && strength_diff < 0))
      {
         score += 30.0; // Bonus for aligned trend and strength
      }
   }
   
   return MathMin(100.0, score);
}

//+------------------------------------------------------------------+
//| Combine individual scores with weights                         |
//+------------------------------------------------------------------+
double CCurrencyScoring::CombineScores(double sr_score, double volatility_score, 
                                       double strength_score, double trend_score)
{
   double total = (sr_score * m_sr_weight / 100.0) +
                  (volatility_score * m_volatility_weight / 100.0) +
                  (strength_score * m_strength_weight / 100.0) +
                  (trend_score * m_trend_weight / 100.0);
   
   return MathMin(100.0, MathMax(0.0, total));
}

//+------------------------------------------------------------------+
//| Sort scores by total score (descending)                        |
//+------------------------------------------------------------------+
void CCurrencyScoring::SortScoresByTotal()
{
   // Simple bubble sort
   for(int i = 0; i < m_scores_count - 1; i++)
   {
      for(int j = 0; j < m_scores_count - 1 - i; j++)
      {
         if(m_scores[j].total_score < m_scores[j + 1].total_score)
         {
            CurrencyScore temp = m_scores[j];
            m_scores[j] = m_scores[j + 1];
            m_scores[j + 1] = temp;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Update rankings after sorting                                  |
//+------------------------------------------------------------------+
void CCurrencyScoring::UpdateRankings()
{
   for(int i = 0; i < m_scores_count; i++)
   {
      m_scores[i].rank = i + 1;
   }
}

//+------------------------------------------------------------------+
//| Validate scores and set tradeable status                       |
//+------------------------------------------------------------------+
void CCurrencyScoring::ValidateScores()
{
   for(int i = 0; i < m_scores_count; i++)
   {
      m_scores[i].is_tradeable = (m_scores[i].total_score >= m_min_total_score);
   }
}

//+------------------------------------------------------------------+
//| Get ATR percentage for symbol                                   |
//+------------------------------------------------------------------+
double CCurrencyScoring::GetATRPercent(const string symbol)
{
   int atr_handle = iATR(symbol, PERIOD_H1, 14);
   if(atr_handle == INVALID_HANDLE)
      return 0.0;
   
   double atr_buffer[];
   if(CopyBuffer(atr_handle, 0, 0, 1, atr_buffer) <= 0)
   {
      IndicatorRelease(atr_handle);
      return 0.0;
   }
   
   double atr = atr_buffer[0];
   double current_price = SymbolInfoDouble(symbol, SYMBOL_BID);
   
   IndicatorRelease(atr_handle);
   
   if(current_price <= 0)
      return 0.0;
   
   return (atr / current_price) * 100.0;
}

//+------------------------------------------------------------------+
//| Check if trend is clear                                        |
//+------------------------------------------------------------------+
bool CCurrencyScoring::IsTrendClear(const string symbol, ENUM_SIGNAL_DIRECTION& direction)
{
   direction = SIGNAL_NONE;
   
   // Simple trend detection using EMAs
   int ema20_handle = iMA(symbol, PERIOD_H1, 20, 0, MODE_EMA, PRICE_CLOSE);
   int ema50_handle = iMA(symbol, PERIOD_H1, 50, 0, MODE_EMA, PRICE_CLOSE);
   
   if(ema20_handle == INVALID_HANDLE || ema50_handle == INVALID_HANDLE)
   {
      if(ema20_handle != INVALID_HANDLE) IndicatorRelease(ema20_handle);
      if(ema50_handle != INVALID_HANDLE) IndicatorRelease(ema50_handle);
      return false;
   }
   
   double ema20[], ema50[];
   
   if(CopyBuffer(ema20_handle, 0, 0, 2, ema20) <= 0 ||
      CopyBuffer(ema50_handle, 0, 0, 2, ema50) <= 0)
   {
      IndicatorRelease(ema20_handle);
      IndicatorRelease(ema50_handle);
      return false;
   }
   
   IndicatorRelease(ema20_handle);
   IndicatorRelease(ema50_handle);
   
   // Check if EMAs are clearly separated
   double current_diff = ema20[0] - ema50[0];
   double previous_diff = ema20[1] - ema50[1];
   
   double min_separation = SymbolInfoDouble(symbol, SYMBOL_POINT) * 20; // 20 points minimum
   
   if(MathAbs(current_diff) < min_separation)
      return false; // Not enough separation
   
   // Check if trend is consistent
   if(current_diff > 0 && previous_diff > 0)
   {
      direction = SIGNAL_BUY;
      return true;
   }
   else if(current_diff < 0 && previous_diff < 0)
   {
      direction = SIGNAL_SELL;
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Get top pairs by score                                         |
//+------------------------------------------------------------------+
void CCurrencyScoring::GetTopPairs(string &symbols[], double &scores[], int count)
{
   if(count > m_scores_count) count = m_scores_count;
   
   ArrayResize(symbols, count);
   ArrayResize(scores, count);
   
   for(int i = 0; i < count; i++)
   {
      symbols[i] = m_scores[i].symbol;
      scores[i] = m_scores[i].total_score;
   }
}

//+------------------------------------------------------------------+
//| Get tradeable pairs                                            |
//+------------------------------------------------------------------+
void CCurrencyScoring::GetTradeablePairs(string &symbols[], double &scores[])
{
   int tradeable_count = GetTradeablePairsCount();
   
   if(tradeable_count == 0)
   {
      ArrayResize(symbols, 0);
      ArrayResize(scores, 0);
      return;
   }
   
   ArrayResize(symbols, tradeable_count);
   ArrayResize(scores, tradeable_count);
   
   int index = 0;
   for(int i = 0; i < m_scores_count && index < tradeable_count; i++)
   {
      if(m_scores[i].is_tradeable)
      {
         symbols[index] = m_scores[i].symbol;
         scores[index] = m_scores[i].total_score;
         index++;
      }
   }
}

//+------------------------------------------------------------------+
//| Get symbol score structure                                      |
//+------------------------------------------------------------------+
CurrencyScore CCurrencyScoring::GetSymbolScore(const string symbol)
{
   CurrencyScore empty_score;
   ZeroMemory(empty_score);
   
   for(int i = 0; i < m_scores_count; i++)
   {
      if(m_scores[i].symbol == symbol)
         return m_scores[i];
   }
   
   return empty_score;
}

//+------------------------------------------------------------------+
//| Get best pair                                                   |
//+------------------------------------------------------------------+
CurrencyScore CCurrencyScoring::GetBestPair()
{
   CurrencyScore empty_score;
   ZeroMemory(empty_score);
   
   if(m_scores_count > 0)
      return m_scores[0]; // First is best after sorting
   
   return empty_score;
}

//+------------------------------------------------------------------+
//| Get symbol total score                                          |
//+------------------------------------------------------------------+
double CCurrencyScoring::GetSymbolTotalScore(const string symbol)
{
   CurrencyScore score = GetSymbolScore(symbol);
   return score.total_score;
}

//+------------------------------------------------------------------+
//| Get symbol rank                                                 |
//+------------------------------------------------------------------+
int CCurrencyScoring::GetSymbolRank(const string symbol)
{
   CurrencyScore score = GetSymbolScore(symbol);
   return score.rank;
}

//+------------------------------------------------------------------+
//| Get top ranked symbol                                          |
//+------------------------------------------------------------------+
string CCurrencyScoring::GetTopRankedSymbol()
{
   if(m_scores_count > 0)
      return m_scores[0].symbol;
   return "";
}

//+------------------------------------------------------------------+
//| Check if symbol is tradeable                                   |
//+------------------------------------------------------------------+
bool CCurrencyScoring::IsSymbolTradeable(const string symbol)
{
   CurrencyScore score = GetSymbolScore(symbol);
   return score.is_tradeable;
}

//+------------------------------------------------------------------+
//| Get tradeable pairs count                                      |
//+------------------------------------------------------------------+
int CCurrencyScoring::GetTradeablePairsCount()
{
   int count = 0;
   for(int i = 0; i < m_scores_count; i++)
   {
      if(m_scores[i].is_tradeable)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| Print all scores                                               |
//+------------------------------------------------------------------+
void CCurrencyScoring::PrintAllScores()
{
   g_Logger.Info("=== Currency Scoring Results ===");
   g_Logger.Info(StringFormat("Last Update: %s", TimeToString(m_last_calculation_time, TIME_SECONDS)));
   g_Logger.Info(StringFormat("Tradeable Pairs: %d/%d", GetTradeablePairsCount(), m_scores_count));
   g_Logger.Info("");
   
   for(int i = 0; i < m_scores_count; i++)
   {
      g_Logger.Info(StringFormat("%d. %s: %.1f (SR:%.1f Vol:%.1f Str:%.1f Trend:%.1f) %s", 
                        m_scores[i].rank,
                        m_scores[i].symbol,
                        m_scores[i].total_score,
                        m_scores[i].sr_score,
                        m_scores[i].volatility_score,
                        m_scores[i].strength_score,
                        m_scores[i].trend_score,
                        m_scores[i].is_tradeable ? "✓" : "✗"));
   }
   
   g_Logger.Info("=================================");
}

//+------------------------------------------------------------------+
//| Print top pairs                                                |
//+------------------------------------------------------------------+
void CCurrencyScoring::PrintTopPairs(int count = 10)
{
   if(count > m_scores_count) count = m_scores_count;
   
   g_Logger.Info(StringFormat("=== Top %d Currency Pairs ===", count));
   
   for(int i = 0; i < count; i++)
   {
      g_Logger.Info(StringFormat("%d. %s: %.1f %s", 
                        i + 1,
                        m_scores[i].symbol,
                        m_scores[i].total_score,
                        m_scores[i].is_tradeable ? "(Tradeable)" : "(Not tradeable)"));
   }
   
   g_Logger.Info("============================");
}

//+------------------------------------------------------------------+
//| Check if calculation is current                                |
//+------------------------------------------------------------------+
bool CCurrencyScoring::IsCalculationCurrent(int max_age_seconds = 300)
{
   return ((TimeCurrent() - m_last_calculation_time) <= max_age_seconds);
}

//+------------------------------------------------------------------+
//| Set scoring weights                                            |
//+------------------------------------------------------------------+
void CCurrencyScoring::SetScoringWeights(double sr_weight, double vol_weight, double str_weight, double trend_weight)
{
   // Ensure weights total 100%
   double total = sr_weight + vol_weight + str_weight + trend_weight;
   if(total != 100.0)
   {
      LogWarning(StringFormat("Scoring weights total %.1f%%, normalizing to 100%%", total), "SetScoringWeights");
      sr_weight = (sr_weight / total) * 100.0;
      vol_weight = (vol_weight / total) * 100.0;
      str_weight = (str_weight / total) * 100.0;
      trend_weight = (trend_weight / total) * 100.0;
   }
   
   m_sr_weight = sr_weight;
   m_volatility_weight = vol_weight;
   m_strength_weight = str_weight;
   m_trend_weight = trend_weight;
   
   LogInfo(StringFormat("Scoring weights updated: SR:%.1f%% Vol:%.1f%% Str:%.1f%% Trend:%.1f%%", 
                       sr_weight, vol_weight, str_weight, trend_weight), "SetScoringWeights");
}

//+------------------------------------------------------------------+
//| Set volatility range                                           |
//+------------------------------------------------------------------+
void CCurrencyScoring::SetVolatilityRange(double min_atr_percent, double max_atr_percent)
{
   m_optimal_atr_min = min_atr_percent;
   m_optimal_atr_max = max_atr_percent;
   
   LogInfo(StringFormat("Volatility range updated: %.2f%% - %.2f%%", min_atr_percent, max_atr_percent), "SetVolatilityRange");
}

//+------------------------------------------------------------------+
//| Set minimum score                                              |
//+------------------------------------------------------------------+
void CCurrencyScoring::SetMinimumScore(double min_score)
{
   m_min_total_score = min_score;
   LogInfo(StringFormat("Minimum tradeable score set to %.1f", min_score), "SetMinimumScore");
}

//+------------------------------------------------------------------+
