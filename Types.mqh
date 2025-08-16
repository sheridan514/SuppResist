//+------------------------------------------------------------------+
//| Types.mqh                                                        |
//| Copyright 2024, SuppResist                                       |
//| https://www.mql5.com                                             |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, SuppResist"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Enumerations                                                     |
//+------------------------------------------------------------------+

// Signal directions
enum ENUM_SIGNAL_DIRECTION
{
   SIGNAL_NONE = 0,     // No signal
   SIGNAL_BUY = 1,      // Buy signal
   SIGNAL_SELL = -1     // Sell signal
};

// Market status types
enum ENUM_MARKET_STATUS
{
   MARKET_LOADING,      // Loading market data
   MARKET_CONSOLIDATION,// Market in consolidation
   MARKET_TRENDING,     // Market trending
   MARKET_ERROR         // Error in market analysis
};

// Grid status types  
enum ENUM_GRID_STATUS
{
   GRID_NONE,           // No grid active
   GRID_ACTIVE,         // Grid is active
   GRID_RECOVERY        // Grid in recovery mode
};

// Strategy types
enum ENUM_STRATEGY_TYPE
{
   STRATEGY_TREND,      // Trend following strategy
   STRATEGY_RANGE       // Range/consolidation strategy
};

//+------------------------------------------------------------------+
//| Data Structures                                                 |
//+------------------------------------------------------------------+

// Settings structure containing all configuration parameters
struct SSettings
{
   // Default constructor
   SSettings()
   {
      Reset();
   }
   
   // Copy constructor
   SSettings(const SSettings &other)
   {
      symbols_string = other.symbols_string;
      ArrayCopy(symbols, other.symbols);
      symbols_count = other.symbols_count;
      use_trend_strategy = other.use_trend_strategy;
      trend_threshold = other.trend_threshold;
      scalping_min_score = other.scalping_min_score;
      sr_lookback_daily = other.sr_lookback_daily;
      sr_lookback_h4 = other.sr_lookback_h4;
      sr_lookback_h1 = other.sr_lookback_h1;
      sr_proximity_pips = other.sr_proximity_pips;
      sr_min_touches = other.sr_min_touches;
      sr_strength_multiplier_daily = other.sr_strength_multiplier_daily;
      sr_strength_multiplier_h4 = other.sr_strength_multiplier_h4;
      sr_strength_multiplier_h1 = other.sr_strength_multiplier_h1;
      sr_min_combined_strength = other.sr_min_combined_strength;
      use_currency_strength_filter = other.use_currency_strength_filter;
      min_currency_strength_difference = other.min_currency_strength_difference;
      currency_strength_period = other.currency_strength_period;
      use_ai_estimation = other.use_ai_estimation;
      
      // These were missing from the struct definition
      use_market_structure_filter = other.use_market_structure_filter;
      use_volatility_filter = other.use_volatility_filter;
      min_volatility_pips = other.min_volatility_pips;
      max_volatility_pips = other.max_volatility_pips;
      use_spread_filter = other.use_spread_filter;
      max_spread_pips = other.max_spread_pips;
      sr_weight = other.sr_weight;
      volatility_weight = other.volatility_weight;
      currency_strength_weight = other.currency_strength_weight;
      trend_clarity_weight = other.trend_clarity_weight;
      max_risk_per_trade = other.max_risk_per_trade;
      max_daily_risk = other.max_daily_risk;
      panel_x_offset = other.panel_x_offset;
      panel_y_offset = other.panel_y_offset;

      fixed_lot = other.fixed_lot;
      sl_atr_multiplier = other.sl_atr_multiplier;
      tp_rr_ratio = other.tp_rr_ratio;
      max_positions_per_symbol = other.max_positions_per_symbol;
      max_total_positions = other.max_total_positions;
      use_trailing_stop = other.use_trailing_stop;
      ts_activation_pips = other.ts_activation_pips;
      ts_distance_pips = other.ts_distance_pips;
      atr_period = other.atr_period;
      ema_fast_period = other.ema_fast_period;
      ema_slow_period = other.ema_slow_period;
      magic_number = other.magic_number;
      panel_width = other.panel_width;
      panel_row_height = other.panel_row_height;
      panel_bg_color = other.panel_bg_color;
      panel_text_color = other.panel_text_color;
      show_support_resistance = other.show_support_resistance;
      enable_debug_logging = other.enable_debug_logging;
   }

   void Reset()
   {
      symbols_string = "";
      ArrayFree(symbols);
      symbols_count = 0;
      use_trend_strategy = false;
      trend_threshold = 0.0;
      scalping_min_score = 0.0;
      sr_lookback_daily = 0;
      sr_lookback_h4 = 0;
      sr_lookback_h1 = 0;
      sr_proximity_pips = 0.0;
      sr_min_touches = 0;
      sr_strength_multiplier_daily = 0;
      sr_strength_multiplier_h4 = 0;
      sr_strength_multiplier_h1 = 0;
      sr_min_combined_strength = 0.0;
      use_currency_strength_filter = false;
      min_currency_strength_difference = 0.0;
      currency_strength_period = 0;
      use_ai_estimation = false;
      use_market_structure_filter = false;
      use_volatility_filter = false;
      min_volatility_pips = 0.0;
      max_volatility_pips = 0.0;
      use_spread_filter = false;
      max_spread_pips = 0.0;
      sr_weight = 0.0;
      volatility_weight = 0.0;
      currency_strength_weight = 0.0;
      trend_clarity_weight = 0.0;
      fixed_lot = 0.0;
      sl_atr_multiplier = 0.0;
      tp_rr_ratio = 0.0;
      max_positions_per_symbol = 0;
      max_total_positions = 0;
      use_trailing_stop = false;
      ts_activation_pips = 0.0;
      ts_distance_pips = 0.0;
      max_risk_per_trade = 0.0;
      max_daily_risk = 0.0;
      atr_period = 0;
      ema_fast_period = 0;
      ema_slow_period = 0;
      magic_number = 0;
      panel_width = 0;
      panel_row_height = 0;
      panel_x_offset = 0;
      panel_y_offset = 0;
      panel_bg_color = clrNONE;
      panel_text_color = clrNONE;
      show_support_resistance = false;
      enable_debug_logging = false;
   }
   
   // Symbol selection
   string            symbols_string;           // Input symbols as comma-separated string
   string            symbols[];                // Parsed symbols array
   int               symbols_count;            // Number of symbols
   
   // Strategy selection
   bool              use_trend_strategy;       // Use trend strategy
   double            trend_threshold;          // Threshold for trend strategy (0-100)
   double            scalping_min_score;       // Min score for scalping strategy (0-100)
   
   // S&R detection parameters
   int               sr_lookback_daily;        // Daily lookback bars for S&R
   int               sr_lookback_h4;           // H4 lookback bars for S&R
   int               sr_lookback_h1;           // H1 lookback bars for S&R
   double            sr_proximity_pips;        // Max distance in pips for "touch"
   int               sr_min_touches;           // Min touches for valid level
   int               sr_strength_multiplier_daily; // Weight for Daily levels
   int               sr_strength_multiplier_h4;    // Weight for H4 levels
   int               sr_strength_multiplier_h1;    // Weight for H1 levels
   double            sr_min_combined_strength; // Min combined strength for entry
   
   // Currency strength parameters
   bool              use_currency_strength_filter; // Use currency strength filter
   double            min_currency_strength_difference; // Min strength difference
   int               currency_strength_period; // Bars for strength calculation
   
   // AI parameters
   bool              use_ai_estimation;        // Enable AI estimation

   // Filter parameters
   bool              use_market_structure_filter; // Use market structure filter
   bool              use_volatility_filter;    // Use volatility filter
   double            min_volatility_pips;      // Min volatility in pips
   double            max_volatility_pips;      // Max volatility in pips
   bool              use_spread_filter;        // Use spread filter
   double            max_spread_pips;          // Max spread in pips
   
   // Scoring parameters
   double            sr_weight;                // S&R quality weight
   double            volatility_weight;        // Volatility weight
   double            currency_strength_weight; // Currency strength weight
   double            trend_clarity_weight;     // Trend clarity weight

   int               ai_query_interval_minutes; // AI query interval
   double            ai_weight;                // AI weight in combined strength
   
   // Filter parameters
   int               atr_period;               // ATR period for filters
   int               ema_fast_period;          // Fast EMA for trend confirmation
   int               ema_slow_period;          // Slow EMA for trend confirmation
   
   // Scoring parameters
   double            scoring_weight_sr;        // S&R quality weight (%)
   double            scoring_weight_volatility; // Volatility weight (%)
   double            scoring_weight_strength;  // Currency strength weight (%)
   double            scoring_weight_trend;     // Trend clarity weight (%)
   double            min_trading_score;        // Minimum score for trading
   int               max_trading_pairs;        // Max pairs to trade simultaneously
   
   // Position management
   double            fixed_lot;                // Fixed lot size for each trade
   double            sl_atr_multiplier;        // Stop Loss = ATR x multiplier
   double            tp_rr_ratio;              // Take Profit = SL x R:R ratio
   bool              use_sr_based_sl;          // Use S&R levels for SL placement
   bool              use_sr_based_tp;          // Use S&R levels for TP placement
   double            sr_sl_buffer;             // Buffer pips beyond S&R level for SL
   double            sr_tp_buffer;             // Buffer pips before S&R level for TP
   
   // Trailing stop
   bool              use_trailing_stop;        // Enable/disable Trailing Stop
   double            ts_activation_pips;       // Profit pips to activate trailing stop
   double            ts_distance_pips;         // Trailing stop distance in pips
   bool              use_sr_trailing_stop;     // Use S&R levels for trailing stop
   
   // Risk management
   int               magic_number;             // Unique EA magic number
   int               max_positions_per_symbol; // Max positions per symbol
   int               max_total_positions;      // Max total positions
   double            max_risk_percent;         // Max risk per trade (%)
   double            max_daily_loss;           // Max daily loss (%)
   double            min_free_margin;          // Min free margin required
   double            max_risk_per_trade;       // Max risk per trade as percentage
   double            max_daily_risk;           // Max daily risk as percentage

   // Panel display options
   bool              show_support_resistance;  // Show support/resistance levels
   
   // Panel visual settings
   color             panel_bg_color;           // Panel background color
   color             panel_text_color;         // Panel text color
   color             buy_signal_color;         // Buy signal color
   color             sell_signal_color;        // Sell signal color
   color             neutral_color;            // Neutral signal color
   int               panel_font_size;          // Panel font size
   string            panel_font_name;          // Panel font name
   
   // Panel position and dimensions
   int               panel_x_pos;              // Panel X position
   int               panel_y_pos;              // Panel Y position
   int               panel_width;              // Panel width
   int               panel_row_height;         // Panel row height

   // Panel position parameters
   int               panel_x_offset;           // Panel X offset from corner
   int               panel_y_offset;           // Panel Y offset from corner

   // Support/Resistance calculation
   int               sr_lookback_bars;         // Lookback bars for S/R calculation
   ENUM_TIMEFRAMES   sr_timeframe;            // Timeframe for S/R calculation
   
   // Logging settings
   bool              enable_debug_logging;     // Enable debug logging
   string            log_prefix;               // Log message prefix
};

// Signal information for each symbol
struct SSignalInfo
{
   // Default constructor
   SSignalInfo()
   {
      Reset();
   }

   // Copy constructor
   SSignalInfo(const SSignalInfo &other)
   {
      symbol = other.symbol;
      score = other.score;
      rsi_signal = other.rsi_signal;
      bb_signal = other.bb_signal;
      stoch_signal = other.stoch_signal;
      final_signal = other.final_signal;
      strategy_type = other.strategy_type;
      grid_status = other.grid_status;
      support_level = other.support_level;
      resistance_level = other.resistance_level;
      ai_strength = other.ai_strength;
      last_update = other.last_update;
   }
   
   void Reset()
   {
      symbol = "";
      score = 0.0;
      rsi_signal = SIGNAL_NONE;
      bb_signal = SIGNAL_NONE;
      stoch_signal = SIGNAL_NONE;
      final_signal = SIGNAL_NONE;
      strategy_type = STRATEGY_TREND; // Default or some initial value
      grid_status = GRID_NONE;
      support_level = 0.0;
      resistance_level = 0.0;
      ai_strength = 0;
      last_update = 0;
   }

   string                  symbol;             // Symbol name
   double                  score;              // Overall score (0-100)
   ENUM_SIGNAL_DIRECTION   rsi_signal;         // RSI signal
   ENUM_SIGNAL_DIRECTION   bb_signal;          // Bollinger Bands signal  
   ENUM_SIGNAL_DIRECTION   stoch_signal;       // Stochastic signal
   ENUM_SIGNAL_DIRECTION   final_signal;       // Final combined signal
   ENUM_STRATEGY_TYPE      strategy_type;      // Applied strategy type
   ENUM_GRID_STATUS        grid_status;        // Grid status
   double                  support_level;      // Support level
   double                  resistance_level;   // Resistance level
   int                     ai_strength;        // AI trend strength (-100 to +100)
   datetime                last_update;        // Last update time
};

// Market status information
struct SMarketStatusInfo
{
   ENUM_MARKET_STATUS   status;                // Current market status
   string               status_text;           // Status description
   color                status_color;          // Status color for display
   datetime             last_update;           // Last status update
   int                  symbols_processed;     // Number of symbols processed
   int                  symbols_total;         // Total symbols to process
};

// Individual indicator snapshot
struct SIndicatorSnapshot
{
   // Default constructor
   SIndicatorSnapshot()
   {
      Reset();
   }

   // Copy constructor
   SIndicatorSnapshot(const SIndicatorSnapshot &other)
   {
      symbol = other.symbol;
      rsi_value = other.rsi_value;
      bb_upper = other.bb_upper;
      bb_middle = other.bb_middle;
      bb_lower = other.bb_lower;
      stoch_main = other.stoch_main;
      stoch_signal = other.stoch_signal;
      atr_value = other.atr_value;
      atr_percent = other.atr_percent;
      adx_value = other.adx_value;
      ema_fast = other.ema_fast;
      ema_50 = other.ema_50;
      ema_200 = other.ema_200;
      timestamp = other.timestamp;
   }
   
   void Reset()
   {
      symbol = "";
      rsi_value = 0.0;
      bb_upper = 0.0;
      bb_middle = 0.0;
      bb_lower = 0.0;
      stoch_main = 0.0;
      stoch_signal = 0.0;
      atr_value = 0.0;
      atr_percent = 0.0;
      adx_value = 0.0;
      ema_fast = 0.0;
      ema_50 = 0.0;
      ema_200 = 0.0;
      timestamp = 0;
   }
   
   string               symbol;                // Symbol name
   double               rsi_value;             // Current RSI value
   double               bb_upper;              // BB upper band
   double               bb_middle;             // BB middle band
   double               bb_lower;              // BB lower band
   double               stoch_main;            // Stochastic main line
   double               stoch_signal;          // Stochastic signal line
   double               atr_value;             // ATR value
   double               atr_percent;           // ATR as percentage
   double               adx_value;             // ADX value
   double               ema_fast;              // Fast EMA value
   double               ema_50;                // 50 EMA value
   double               ema_200;               // 200 EMA value
   datetime             timestamp;             // Snapshot timestamp
};

// Trade management information
struct STradeInfo
{
   string               symbol;                // Symbol
   int                  ticket;                // Position ticket
   ENUM_POSITION_TYPE   position_type;         // Position type (buy/sell)
   double               entry_price;           // Entry price
   double               volume;                // Position volume
   double               sl_price;              // Stop Loss price
   double               tp_price;              // Take Profit price
   double               trailing_sl;           // Trailing Stop Loss price
   bool                 trailing_active;       // Is trailing active
   datetime             open_time;             // Position open time
   double               current_profit;        // Current profit
   string               comment;               // Position comment
};

//+------------------------------------------------------------------+
//| Constants                                                        |
//+------------------------------------------------------------------+

// Panel layout constants
#define PANEL_PREFIX           "SuppResist_Panel_"
#define PANEL_DEFAULT_WIDTH    800
#define PANEL_DEFAULT_HEIGHT   25
#define PANEL_MARGIN          10

// Column positions (will be calculated based on panel width)
#define COL_SYMBOL_X          20
#define COL_SCORE_X           120
#define COL_RSI_X             220
#define COL_BB_X              280
#define COL_STOCH_X           340
#define COL_SR_X              400
#define COL_AI_X              500
#define COL_FINAL_X           560
#define COL_GRID_X            620

// Default colors
#define DEFAULT_PANEL_BG_COLOR     C'240,240,240'
#define DEFAULT_PANEL_TEXT_COLOR   clrBlack
#define DEFAULT_BUY_COLOR          clrGreen
#define DEFAULT_SELL_COLOR         clrRed
#define DEFAULT_NEUTRAL_COLOR      clrGray

// Signal thresholds
#define RSI_OVERSOLD_LEVEL        30.0
#define RSI_OVERBOUGHT_LEVEL      70.0
#define STOCH_DEFAULT_OVERSOLD    20.0
#define STOCH_DEFAULT_OVERBOUGHT  80.0

// Score calculation weights
#define WEIGHT_RSI               25.0
#define WEIGHT_BOLLINGER         25.0
#define WEIGHT_STOCHASTIC        25.0
#define WEIGHT_ATR_ADX           25.0

// Maximum number of symbols
#define MAX_SYMBOLS              20

//+------------------------------------------------------------------+
