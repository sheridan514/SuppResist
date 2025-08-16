//+------------------------------------------------------------------+
//| Settings.mqh                                                     |
//| Copyright 2024, SuppResist                                       |
//| https://www.mql5.com                                             |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, SuppResist"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "SuppResist.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+

// === Symbol Selection ===
input string InpSymbols = "EURUSD";
//,GBPUSD,USDJPY,USDCHF,AUDUSD,USDCAD,NZDUSD,EURJPY";  // Symbols for analysis

// === Strategy Selection ===
input bool   InpUseTrendStrategy = true;           // Use trend strategy
input double InpTrendThreshold = 30.0;             // Trend threshold (0-100)
input double InpScalpingMinScore = 70.0;           // Min score for scalping (0-100)

// === Support & Resistance Parameters ===
input group  "=== S&R Detection Settings ==="
input int    InpSR_LookbackBars_Daily = 200;       // Daily lookback bars for S&R
input int    InpSR_LookbackBars_H4 = 300;          // H4 lookback bars for S&R
input int    InpSR_LookbackBars_H1 = 400;          // H1 lookback bars for S&R
input double InpSR_ProximityPips = 10.0;           // Max distance in pips for "touch"
input int    InpSR_MinTouches = 3;                 // Min touches for valid level
input int    InpSR_StrengthMultiplier_Daily = 5;   // Weight for Daily levels
input int    InpSR_StrengthMultiplier_H4 = 3;      // Weight for H4 levels
input int    InpSR_StrengthMultiplier_H1 = 1;      // Weight for H1 levels
input double InpSR_MinCombinedStrength = 15.0;     // Min combined strength for entry

// === Currency Strength Parameters ===
input group  "=== Currency Strength Settings ==="
input bool   InpUseCurrencyStrengthFilter = true;  // Use currency strength filter
input double InpMinCurrencyStrengthDifference = 0.1; // Min strength difference for entry
input int    InpCurrencyStrengthPeriod = 1;        // Bars for strength calculation

// === AI Module Parameters (Optional) ===
input group  "=== AI Settings ==="
input bool   InpUseAI_Estimation = false;          // Enable/disable AI estimates
input int    InpAI_QueryIntervalMinutes = 60;      // AI query interval in minutes
input string InpAI_API_Endpoint = "";              // AI API endpoint URL
input string InpAI_API_Key = "";                   // AI API key
input double InpAI_Weight = 0.3;                   // AI weight in combined strength

// === Filters and Confluence ===
input group  "=== Market Filters ==="
input int    InpATR_Period = 14;                   // ATR period for filters
input double InpMinVolatility_ATR_Pct = 0.05;      // Min volatility (ATR %) for trading
input double InpMaxVolatility_ATR_Pct = 0.20;      // Max volatility (ATR %) for trading
input int    InpEMA_Period_Fast = 20;              // Fast EMA for trend confirmation
input int    InpEMA_Period_Slow = 50;              // Slow EMA for trend confirmation

// === Scoring Weights ===
input group  "=== Currency Scoring ==="
input double InpScoringWeight_SR = 40.0;           // S&R quality weight (%)
input double InpScoringWeight_Volatility = 25.0;   // Volatility weight (%)
input double InpScoringWeight_Strength = 20.0;     // Currency strength weight (%)
input double InpScoringWeight_Trend = 15.0;        // Trend clarity weight (%)
input double InpMinTradingScore = 60.0;            // Minimum score for trading
input int    InpMaxTradingPairs = 5;               // Maximum pairs to trade simultaneously

// === Position Management ===
input group  "=== Position Management ==="
input double InpFixedLot = 0.01;                   // Fixed lot size for each trade
input double InpSL_ATR_Multiplier = 1.5;           // Stop Loss = ATR x multiplier
input double InpTP_RR = 2.5;                       // Take Profit = SL x R:R ratio
input bool   InpUseSR_BasedSL = true;              // Use S&R levels for SL placement
input bool   InpUseSR_BasedTP = true;              // Use S&R levels for TP placement
input double InpSR_SL_Buffer = 5.0;                // Buffer pips beyond S&R level for SL
input double InpSR_TP_Buffer = 3.0;                // Buffer pips before S&R level for TP

// === Trailing Stop ===
input group  "=== Trailing Stop ==="
input bool   InpUseTrailingStop = true;            // Enable/disable Trailing Stop
input double InpTS_Activation_Pips = 20.0;         // Profit pips to activate trailing stop
input double InpTS_Distance_Pips = 10.0;           // Trailing stop distance in pips
input bool   InpUseSR_TrailingStop = true;         // Use S&R levels for trailing stop

// === Risk Management ===
input group  "=== Risk Management ==="
input int    InpMagicNumber = 12345;               // Unique EA magic number
input int    InpMaxPositionsPerSymbol = 1;         // Max positions per symbol
input int    InpMaxTotalPositions = 10;            // Max total positions
input double InpMaxRiskPercent = 2.0;              // Max risk per trade (%)
input double InpMaxDailyLoss = 5.0;                // Max daily loss (%)
input double InpMinFreeMargin = 1000.0;            // Min free margin required

// === Panel Display ===
input group  "=== Panel Display ==="
input bool   InpShowSupportResistance = true;      // Show support/resistance levels
input bool   InpUseAIEstimation = false;           // Use AI estimation
input bool   InpShowPanel = true;                  // Show dashboard panel
input int    InpPanelXPos = 20;                    // Panel X position
input int    InpPanelYPos = 50;                    // Panel Y position
input int    InpPanelWidth = 800;                  // Panel width
input int    InpPanelRowHeight = 25;               // Panel row height

// === Panel Colors ===
input group  "=== Panel Colors ==="
input color  InpPanelBgColor = C'240,240,240';     // Panel background color
input color  InpPanelTextColor = clrBlack;         // Panel text color
input color  InpBuySignalColor = clrGreen;         // Buy signal color
input color  InpSellSignalColor = clrRed;          // Sell signal color
input color  InpNeutralColor = clrGray;            // Neutral signal color

// === Panel Font ===
input group  "=== Panel Font ==="
input string InpPanelFontName = "Arial";           // Panel font name
input int    InpPanelFontSize = 9;                 // Panel font size

// === Support/Resistance ===
input group  "=== Support/Resistance ==="
input int    InpSrLookbackBars = 50;               // S/R lookback bars
input ENUM_TIMEFRAMES InpSrTimeframe = PERIOD_H1;  // S/R timeframe
input int    InpSrMinTouchCount = 2;               // Minimum touches for S/R level
input double InpSrTolerance = 10.0;                // S/R level tolerance (points)

// === Logging ===
input group  "=== Logging ==="
input bool   InpEnableDebugLogging = false;        // Enable debug logging
input bool   InpLogToFile = true;                  // Log to file
input string InpLogPrefix = "SuppResist";          // Log message prefix

//+------------------------------------------------------------------+
//| CSettings Class                                                  |
//+------------------------------------------------------------------+
class CSettings
{
private:
   SSettings    m_settings;                         // Settings structure
   bool         m_initialized;                      // Initialization flag
   
   // Internal methods
   bool ValidateInputs();
   void ParseSymbols();
   void SetDefaultColors();
   void CalculatePanelLayout();
   
public:
   // Constructor/Destructor
   CSettings();
   ~CSettings();
   
   // Initialization
   bool Initialize();
   void Deinitialize();
   
   // Status
   bool IsInitialized() const { return m_initialized; }
   
   // Getters
   SSettings GetSettings() const { return m_settings; }
   SSettings GetSettingsCopy() const { return m_settings; }
   
   // Symbol methods
   int GetSymbolsCount() const { return m_settings.symbols_count; }
   string GetSymbol(int index) const;
   bool IsSymbolValid(const string symbol) const;
   
   // Strategy methods
   bool UseTrendStrategy() const { return m_settings.use_trend_strategy; }
   double GetTrendThreshold() const { return m_settings.trend_threshold; }
   double GetScalpingMinScore() const { return m_settings.scalping_min_score; }
   
   // Indicator getters
   int GetAtrPeriod() const { return m_settings.atr_period; }
   int GetEmaFastPeriod() const { return m_settings.ema_fast_period; }
   int GetEmaSlowPeriod() const { return m_settings.ema_slow_period; }
   
   // Panel getters
   bool ShowPanel() const { return InpShowPanel; }
   bool ShowSupportResistance() const { return m_settings.show_support_resistance; }
   bool UseAIEstimation() const { return m_settings.use_ai_estimation; }
   
   // Position management getters
   double GetFixedLot() const { return m_settings.fixed_lot; }
   double GetSlAtrMultiplier() const { return m_settings.sl_atr_multiplier; }
   double GetTpRrRatio() const { return m_settings.tp_rr_ratio; }
   
   // Validation methods
   bool ValidateSymbol(const string symbol);
   bool ValidateIndicatorPeriod(int period, int min_period);
   bool ValidatePercentageValue(double value);
   
   // Settings update (for optimization)
   bool UpdateSettings(const SSettings& new_settings);
   
   // Debug methods
   void PrintSettings() const;
   string ToString() const;
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSettings::CSettings() : m_initialized(false)
{
   ZeroMemory(m_settings);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSettings::~CSettings()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize settings                                              |
//+------------------------------------------------------------------+
bool CSettings::Initialize()
{
   if(m_initialized)
      return true;
      
   // Copy input parameters to settings structure
   m_settings.symbols_string = InpSymbols;
   m_settings.use_trend_strategy = InpUseTrendStrategy;
   m_settings.trend_threshold = InpTrendThreshold;
   m_settings.scalping_min_score = InpScalpingMinScore;
   
   // S&R parameters
   m_settings.sr_lookback_daily = InpSR_LookbackBars_Daily;
   m_settings.sr_lookback_h4 = InpSR_LookbackBars_H4;
   m_settings.sr_lookback_h1 = InpSR_LookbackBars_H1;
   m_settings.sr_proximity_pips = InpSR_ProximityPips;
   m_settings.sr_min_touches = InpSR_MinTouches;
   m_settings.sr_strength_multiplier_daily = InpSR_StrengthMultiplier_Daily;
   m_settings.sr_strength_multiplier_h4 = InpSR_StrengthMultiplier_H4;
   m_settings.sr_strength_multiplier_h1 = InpSR_StrengthMultiplier_H1;
   m_settings.sr_min_combined_strength = InpSR_MinCombinedStrength;
   
   // Currency strength parameters
   m_settings.use_currency_strength_filter = InpUseCurrencyStrengthFilter;
   m_settings.min_currency_strength_difference = InpMinCurrencyStrengthDifference;
   m_settings.currency_strength_period = InpCurrencyStrengthPeriod;
   
   // AI parameters
   m_settings.use_ai_estimation = InpUseAI_Estimation;
   m_settings.ai_query_interval_minutes = InpAI_QueryIntervalMinutes;
   m_settings.ai_weight = InpAI_Weight;
   
   // Filter parameters
   m_settings.atr_period = InpATR_Period;
   m_settings.min_volatility_pips = InpMinVolatility_ATR_Pct; // Renamed from min_volatility_atr_pct
   m_settings.max_volatility_pips = InpMaxVolatility_ATR_Pct; // Renamed from max_volatility_atr_pct
   m_settings.ema_fast_period = InpEMA_Period_Fast;
   m_settings.ema_slow_period = InpEMA_Period_Slow;
   
   // Scoring parameters
   m_settings.scoring_weight_sr = InpScoringWeight_SR;
   m_settings.scoring_weight_volatility = InpScoringWeight_Volatility;
   m_settings.scoring_weight_strength = InpScoringWeight_Strength;
   m_settings.scoring_weight_trend = InpScoringWeight_Trend;
   m_settings.min_trading_score = InpMinTradingScore;
   m_settings.max_trading_pairs = InpMaxTradingPairs;
   
   // Position management
   m_settings.fixed_lot = InpFixedLot;
   m_settings.sl_atr_multiplier = InpSL_ATR_Multiplier;
   m_settings.tp_rr_ratio = InpTP_RR;
   m_settings.use_sr_based_sl = InpUseSR_BasedSL;
   m_settings.use_sr_based_tp = InpUseSR_BasedTP;
   m_settings.sr_sl_buffer = InpSR_SL_Buffer;
   m_settings.sr_tp_buffer = InpSR_TP_Buffer;
   
   // Trailing stop
   m_settings.use_trailing_stop = InpUseTrailingStop;
   m_settings.ts_activation_pips = InpTS_Activation_Pips;
   m_settings.ts_distance_pips = InpTS_Distance_Pips;
   m_settings.use_sr_trailing_stop = InpUseSR_TrailingStop;
   
   // Risk management
   m_settings.magic_number = InpMagicNumber;
   m_settings.max_positions_per_symbol = InpMaxPositionsPerSymbol;
   m_settings.max_total_positions = InpMaxTotalPositions;
   m_settings.max_risk_percent = InpMaxRiskPercent;
   m_settings.max_daily_loss = InpMaxDailyLoss;
   m_settings.min_free_margin = InpMinFreeMargin;
   
   // Panel settings
   m_settings.show_support_resistance = InpShowSupportResistance;
   m_settings.use_ai_estimation = InpUseAIEstimation;
   m_settings.panel_x_pos = InpPanelXPos;
   m_settings.panel_y_pos = InpPanelYPos;
   m_settings.panel_width = InpPanelWidth;
   m_settings.panel_row_height = InpPanelRowHeight;
   
   // Colors and font
   m_settings.panel_bg_color = InpPanelBgColor;
   m_settings.panel_text_color = InpPanelTextColor;
   m_settings.buy_signal_color = InpBuySignalColor;
   m_settings.sell_signal_color = InpSellSignalColor;
   m_settings.neutral_color = InpNeutralColor;
   m_settings.panel_font_name = InpPanelFontName;
   m_settings.panel_font_size = InpPanelFontSize;
   
   // S/R parameters
   m_settings.sr_lookback_bars = InpSrLookbackBars;
   m_settings.sr_timeframe = InpSrTimeframe;
   
   // Logging
   m_settings.enable_debug_logging = InpEnableDebugLogging;
   m_settings.log_prefix = InpLogPrefix;
   
   // Validate inputs
   if(!ValidateInputs())
   {
      g_Logger.Error("SuppResist Settings: Input validation failed");
      return false;
   }
   
   // Parse symbols
   ParseSymbols();
   
   // Set default colors if needed
   SetDefaultColors();
   
   // Calculate panel layout
   CalculatePanelLayout();
   
   m_initialized = true;
   
   if(m_settings.enable_debug_logging)
      PrintSettings();
      
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize settings                                            |
//+------------------------------------------------------------------+
void CSettings::Deinitialize()
{
   ArrayFree(m_settings.symbols);
   m_initialized = false;
}

//+------------------------------------------------------------------+
//| Validate input parameters                                        |
//+------------------------------------------------------------------+
bool CSettings::ValidateInputs()
{
   // Validate S&R parameters
   if(!ValidateIndicatorPeriod(m_settings.sr_lookback_daily, 10))
   {
      g_Logger.Error(StringFormat("SuppResist Settings: Invalid Daily lookback: %d", m_settings.sr_lookback_daily));
      return false;
   }
   
   if(!ValidateIndicatorPeriod(m_settings.sr_lookback_h4, 10))
   {
      g_Logger.Error(StringFormat("SuppResist Settings: Invalid H4 lookback: %d", m_settings.sr_lookback_h4));
      return false;
   }
   
   if(!ValidateIndicatorPeriod(m_settings.atr_period, 1))
   {
      g_Logger.Error(StringFormat("SuppResist Settings: Invalid ATR period: %d", m_settings.atr_period));
      return false;
   }
   
   // Validate percentage values
   if(!ValidatePercentageValue(m_settings.trend_threshold))
   {
      g_Logger.Error(StringFormat("SuppResist Settings: Invalid trend threshold: %.1f", m_settings.trend_threshold));
      return false;
   }
   
   if(!ValidatePercentageValue(m_settings.scalping_min_score))
   {
      g_Logger.Error(StringFormat("SuppResist Settings: Invalid scalping min score: %.1f", m_settings.scalping_min_score));
      return false;
   }
   
   // Validate multipliers
   if(m_settings.sl_atr_multiplier <= 0)
   {
      g_Logger.Error(StringFormat("SuppResist Settings: Invalid SL ATR multiplier: %.1f", m_settings.sl_atr_multiplier));
      return false;
   }
   
   if(m_settings.tp_rr_ratio <= 0)
   {
      g_Logger.Error(StringFormat("SuppResist Settings: Invalid TP R:R ratio: %.1f", m_settings.tp_rr_ratio));
      return false;
   }
   
   // Validate panel dimensions
   if(m_settings.panel_width < 400)
   {
      g_Logger.Error(StringFormat("SuppResist Settings: Panel width too small: %d", m_settings.panel_width));
      m_settings.panel_width = 400;
   }
   
   if(m_settings.panel_row_height < 15)
   {
      g_Logger.Error(StringFormat("SuppResist Settings: Panel row height too small: %d", m_settings.panel_row_height));
      m_settings.panel_row_height = 15;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Parse symbols string into array                                  |
//+------------------------------------------------------------------+
void CSettings::ParseSymbols()
{
   m_settings.symbols_count = StringToStringArray(m_settings.symbols_string, m_settings.symbols, ",");
   
   if(m_settings.symbols_count == 0)
   {
      g_Logger.Warning("SuppResist Settings: No valid symbols found, using EURUSD as default");
      ArrayResize(m_settings.symbols, 1);
      m_settings.symbols[0] = "EURUSD";
      m_settings.symbols_count = 1;
   }
   
   // Symbols loaded (sorting skipped to avoid ArraySort issues)
   
   // Validate and remove invalid symbols
   for(int i = m_settings.symbols_count - 1; i >= 0; i--)
   {
      if(!IsValidSymbol(m_settings.symbols[i]))
      {
         g_Logger.Warning(StringFormat("SuppResist Settings: Removing invalid symbol: %s", m_settings.symbols[i]));
         ArrayRemove(m_settings.symbols, i, 1);
         m_settings.symbols_count--;
      }
   }
   
   if(m_settings.symbols_count > MAX_SYMBOLS)
   {
      g_Logger.Warning(StringFormat("SuppResist Settings: Too many symbols (%d), limiting to %d", m_settings.symbols_count, MAX_SYMBOLS));
      ArrayResize(m_settings.symbols, MAX_SYMBOLS);
      m_settings.symbols_count = MAX_SYMBOLS;
   }
   
   string temp_symbols2[];
   ArrayCopy(temp_symbols2, m_settings.symbols);
   g_Logger.Info(StringFormat("SuppResist Settings: Loaded %d symbols: %s", m_settings.symbols_count, StringArrayToString(temp_symbols2, ",")));
}

//+------------------------------------------------------------------+
//| Set default colors                                               |
//+------------------------------------------------------------------+
void CSettings::SetDefaultColors()
{
   if(m_settings.panel_bg_color == clrNONE)
      m_settings.panel_bg_color = DEFAULT_PANEL_BG_COLOR;
      
   if(m_settings.panel_text_color == clrNONE)
      m_settings.panel_text_color = DEFAULT_PANEL_TEXT_COLOR;
      
   if(m_settings.buy_signal_color == clrNONE)
      m_settings.buy_signal_color = DEFAULT_BUY_COLOR;
      
   if(m_settings.sell_signal_color == clrNONE)
      m_settings.sell_signal_color = DEFAULT_SELL_COLOR;
      
   if(m_settings.neutral_color == clrNONE)
      m_settings.neutral_color = DEFAULT_NEUTRAL_COLOR;
}

//+------------------------------------------------------------------+
//| Calculate panel layout                                           |
//+------------------------------------------------------------------+
void CSettings::CalculatePanelLayout()
{
   // Panel layout calculations can be done here if needed
   // For now, we use the constants defined in Types.mqh
}

//+------------------------------------------------------------------+
//| Get symbol by index                                              |
//+------------------------------------------------------------------+
string CSettings::GetSymbol(int index) const
{
   if(index >= 0 && index < m_settings.symbols_count)
      return m_settings.symbols[index];
   return "";
}

//+------------------------------------------------------------------+
//| Check if symbol is valid                                         |
//+------------------------------------------------------------------+
bool CSettings::IsSymbolValid(const string symbol) const
{
   return IsValidSymbol(symbol);
}

//+------------------------------------------------------------------+
//| Validate symbol                                                  |
//+------------------------------------------------------------------+
bool CSettings::ValidateSymbol(const string symbol)
{
   return IsValidSymbol(symbol);
}

//+------------------------------------------------------------------+
//| Validate indicator period                                        |
//+------------------------------------------------------------------+
bool CSettings::ValidateIndicatorPeriod(int period, int min_period)
{
   return (period >= min_period && period <= 1000);
}

//+------------------------------------------------------------------+
//| Validate percentage value                                        |
//+------------------------------------------------------------------+
bool CSettings::ValidatePercentageValue(double value)
{
   return (value >= 0.0 && value <= 100.0);
}

//+------------------------------------------------------------------+
//| Update settings                                                  |
//+------------------------------------------------------------------+
bool CSettings::UpdateSettings(const SSettings& new_settings)
{
   m_settings = new_settings;
   return ValidateInputs();
}

//+------------------------------------------------------------------+
//| Print settings for debugging                                     |
//+------------------------------------------------------------------+
void CSettings::PrintSettings() const
{
   g_Logger.Info("=== SuppResist Settings ===");
   string temp_symbols[];
   ArrayCopy(temp_symbols, m_settings.symbols);
   g_Logger.Info(StringFormat("Symbols: %s", StringArrayToString(temp_symbols, ",")));
   g_Logger.Info(StringFormat("Symbols count: %d", m_settings.symbols_count));
   g_Logger.Info(StringFormat("Use trend strategy: %s", m_settings.use_trend_strategy ? "true" : "false"));
   g_Logger.Info(StringFormat("Trend threshold: %.1f", m_settings.trend_threshold));
   g_Logger.Info(StringFormat("Scalping min score: %.1f", m_settings.scalping_min_score));
   g_Logger.Info(StringFormat("ATR period: %d", m_settings.atr_period));
   g_Logger.Info(StringFormat("EMA fast: %d, slow: %d", m_settings.ema_fast_period, m_settings.ema_slow_period));
   g_Logger.Info(StringFormat("Show S/R: %s", m_settings.show_support_resistance ? "true" : "false"));
   g_Logger.Info(StringFormat("Use AI: %s", m_settings.use_ai_estimation ? "true" : "false"));
   g_Logger.Info(StringFormat("Debug logging: %s", m_settings.enable_debug_logging ? "true" : "false"));
   g_Logger.Info("===========================");
}

//+------------------------------------------------------------------+
//| Convert settings to string                                       |
//+------------------------------------------------------------------+
string CSettings::ToString() const
{
   return StringFormat("Settings[Symbols:%d, Trend:%s, ATR:%d, EMA:%d/%d, SR_Min:%.1f]",
                      m_settings.symbols_count,
                      m_settings.use_trend_strategy ? "ON" : "OFF",
                      m_settings.atr_period,
                      m_settings.ema_fast_period,
                      m_settings.ema_slow_period,
                      m_settings.sr_min_combined_strength);
}

//+------------------------------------------------------------------+
