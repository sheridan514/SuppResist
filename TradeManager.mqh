//+------------------------------------------------------------------+
//| TradeManager.mqh                                                 |
//| Copyright 2024, SuppResist                                       |
//| https://www.mql5.com                                             |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, SuppResist"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Trade/Trade.mqh>
#include "SuppResist.mqh"
#include "Logger.mqh"
#include "SR_Engine.mqh"

//+------------------------------------------------------------------+
//| CTradeManager Class                                              |
//+------------------------------------------------------------------+
class CTradeManager
{
private:
   SSettings         m_settings;                    // Trade settings
   bool              m_initialized;                 // Initialization flag
   CTrade            m_trade;                       // Trade execution object
   CSR_Engine*       m_sr_engine;                   // Reference to S&R engine
   
   // Position tracking
   STradeInfo        m_positions[];                 // Active positions
   int               m_positions_count;             // Number of active positions
   
   // Risk management
   double            m_max_lot_size;                // Maximum lot size
   double            m_min_lot_size;                // Minimum lot size
   double            m_account_balance;             // Current account balance
   double            m_risk_percent;                // Risk percentage per trade
   
   // Internal methods
   bool ValidateTradeRequest(const string symbol, ENUM_ORDER_TYPE order_type, double volume);
   double CalculatePositionSize(const string symbol, double sl_distance);
   double CalculateStopLoss(const string symbol, ENUM_ORDER_TYPE order_type, double entry_price);
   double CalculateTakeProfit(const string symbol, ENUM_ORDER_TYPE order_type, double entry_price, double sl_distance);
   
   // Position management
   bool OpenPosition(const string symbol, ENUM_ORDER_TYPE order_type, double volume, 
                     double entry_price, double sl_price, double tp_price, const string comment);
   bool ModifyPosition(ulong ticket, double new_sl, double new_tp);
   bool ClosePosition(ulong ticket, const string reason = "");
   
   // Position tracking
   int FindPositionIndex(ulong ticket);
   int FindPositionBySymbol(const string symbol);
   bool UpdatePositionsArray();
   
   // Trailing stop logic
   bool ProcessTrailingStop(STradeInfo& position);
   bool ShouldActivateTrailing(const STradeInfo& position);
   double CalculateTrailingStopLevel(const STradeInfo& position);
   
   // Risk management
   bool ValidateRiskManagement(const string symbol, double volume);
   double GetMaxAllowedVolume(const string symbol);
   bool CheckMaxPositions(const string symbol);
   
   // Utility methods
   string GenerateComment(const string symbol, ENUM_SIGNAL_DIRECTION signal, ENUM_STRATEGY_TYPE strategy);
   int GetMagicNumber(ENUM_STRATEGY_TYPE strategy);
   ENUM_GRID_STATUS DetermineGridStatus(const string symbol);
   
public:
   // Constructor/Destructor
   CTradeManager();
   ~CTradeManager();
   
   // Initialization
   bool Initialize(const SSettings& settings);
   void Deinitialize();
   void SetSREngine(CSR_Engine* sr_engine) { m_sr_engine = sr_engine; }
   
   // Main trading methods
   bool ProcessSignal(const string symbol, const SSignalInfo& signal_info);
   bool ExecuteTrade(const string symbol, ENUM_SIGNAL_DIRECTION signal, ENUM_STRATEGY_TYPE strategy);
   
   // Position management
   void UpdatePositions();
   void ProcessTrailingStops();
   void CloseAllPositions(const string reason = "");
   void ClosePositionsBySymbol(const string symbol, const string reason = "");
   
   // Information methods
   int GetPositionsCount() const { return m_positions_count; }
   int GetPositionsCountBySymbol(const string symbol);
   double GetTotalProfit();
   double GetSymbolProfit(const string symbol);
   
   // Position info
   STradeInfo GetPositionInfo(int index);
   STradeInfo GetPositionBySymbol(const string symbol);
   bool HasPosition(const string symbol);
   
   // Grid management
   ENUM_GRID_STATUS GetGridStatus(const string symbol);
   bool UpdateGridStatus(const string symbol, ENUM_GRID_STATUS new_status);
   
   // Risk management getters
   double GetCurrentRisk() const { return m_risk_percent; }
   double GetMaxLotSize() const { return m_max_lot_size; }
   double GetAccountBalance() const { return m_account_balance; }
   
   // Settings
   void SetRiskPercent(double risk_percent);
   void SetMaxLotSize(double max_lot);
   
   // Debug methods
   void PrintPositions();
   string GetTradeStatistics();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTradeManager::CTradeManager() : m_initialized(false), 
                                 m_positions_count(0),
                                 m_risk_percent(2.0),
                                 m_account_balance(0.0),
                                 m_sr_engine(NULL)
{
   ZeroMemory(m_settings);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTradeManager::~CTradeManager()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize trade manager                                         |
//+------------------------------------------------------------------+
bool CTradeManager::Initialize(const SSettings& settings)
{
   if(m_initialized)
      return true;
   
   m_settings = settings;
   
   // Initialize trade object
   m_trade.SetExpertMagicNumber(m_settings.magic_number);
   
   // Set trade parameters
   m_trade.SetDeviationInPoints(10);
   m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   
   // Initialize risk management
   m_account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   m_max_lot_size = 10.0; // Default max lot size
   m_min_lot_size = 0.01;
   
   // Get symbol limits
   string symbol = _Symbol;
   m_min_lot_size = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   if(max_lot > 0 && max_lot < m_max_lot_size)
      m_max_lot_size = max_lot;
   
   // Initialize positions array
   ArrayResize(m_positions, 100); // Initial capacity
   m_positions_count = 0;
   
   // Load existing positions
   UpdatePositionsArray();
   
   m_initialized = true;
   
   LogInfo(StringFormat("TradeManager initialized - Balance: %.2f, Risk: %.1f%%, MaxLot: %.2f", 
                       m_account_balance, m_risk_percent, m_max_lot_size), "CTradeManager::Initialize");
   
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize trade manager                                       |
//+------------------------------------------------------------------+
void CTradeManager::Deinitialize()
{
   if(!m_initialized)
      return;
   
   ArrayFree(m_positions);
   m_positions_count = 0;
   m_initialized = false;
   
   LogInfo("TradeManager deinitialized", "CTradeManager::Deinitialize");
}

//+------------------------------------------------------------------+
//| Process trading signal                                           |
//+------------------------------------------------------------------+
bool CTradeManager::ProcessSignal(const string symbol, const SSignalInfo& signal_info)
{
   if(!m_initialized)
   {
      LogError("TradeManager not initialized", "ProcessSignal");
      return false;
   }
   
   if(signal_info.final_signal == SIGNAL_NONE)
      return true; // No signal, nothing to do
   
   // Check if we already have a position for this symbol
   if(HasPosition(symbol))
   {
      LogDebug(StringFormat("Position already exists for %s", symbol), "ProcessSignal");
      return true;
   }
   
   // Check maximum positions per symbol
   if(!CheckMaxPositions(symbol))
   {
      LogWarning(StringFormat("Maximum positions reached for %s", symbol), "ProcessSignal");
      return false;
   }
   
   // Execute the trade
   return ExecuteTrade(symbol, signal_info.final_signal, signal_info.strategy_type);
}

//+------------------------------------------------------------------+
//| Execute trade based on signal                                   |
//+------------------------------------------------------------------+
bool CTradeManager::ExecuteTrade(const string symbol, ENUM_SIGNAL_DIRECTION signal, ENUM_STRATEGY_TYPE strategy)
{
   if(signal == SIGNAL_NONE)
      return false;
   
   ENUM_ORDER_TYPE order_type = (signal == SIGNAL_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   
   // Get current price
   double current_price = (signal == SIGNAL_BUY) ? 
                          SymbolInfoDouble(symbol, SYMBOL_ASK) : 
                          SymbolInfoDouble(symbol, SYMBOL_BID);
   
   if(current_price == 0.0)
   {
      LogError(StringFormat("Cannot get current price for %s", symbol), "ExecuteTrade");
      return false;
   }
   
   // Calculate stop loss
   double sl_price = CalculateStopLoss(symbol, order_type, current_price);
   if(sl_price == 0.0)
   {
      LogError(StringFormat("Cannot calculate stop loss for %s", symbol), "ExecuteTrade");
      return false;
   }
   
   // Use fixed lot size (as per S&R system specification)
   double volume = m_settings.fixed_lot;
   
   // Validate volume
   volume = NormalizeVolume(symbol, volume);
   if(volume < m_min_lot_size)
   {
      LogWarning(StringFormat("Volume too small for %s: %.2f < %.2f", symbol, volume, m_min_lot_size), "ExecuteTrade");
      return false;
   }
   
   // Calculate SL distance for TP calculation
   double sl_distance = MathAbs(current_price - sl_price);
   
   // Calculate take profit
   double tp_price = CalculateTakeProfit(symbol, order_type, current_price, sl_distance);
   
   // Validate trade request
   if(!ValidateTradeRequest(symbol, order_type, volume))
   {
      LogError(StringFormat("Trade validation failed for %s", symbol), "ExecuteTrade");
      return false;
   }
   
   // Generate comment
   string comment = GenerateComment(symbol, signal, strategy);
   
   // Set magic number based on strategy
   int magic_number = GetMagicNumber(strategy);
   m_trade.SetExpertMagicNumber(magic_number);
   
   // Execute trade
   bool success = false;
   if(order_type == ORDER_TYPE_BUY)
   {
      success = m_trade.Buy(volume, symbol, current_price, sl_price, tp_price, comment);
   }
   else
   {
      success = m_trade.Sell(volume, symbol, current_price, sl_price, tp_price, comment);
   }
   
   if(success)
   {
      ulong ticket = m_trade.ResultOrder();
      LogInfo(StringFormat("TRADE OPENED: %s %s %.2f @ %.5f, SL: %.5f, TP: %.5f, Ticket: %I64u", 
                          symbol, 
                          (signal == SIGNAL_BUY) ? "BUY" : "SELL",
                          volume, current_price, sl_price, tp_price, ticket), "ExecuteTrade");
      
      // Update positions array
      UpdatePositionsArray();
      
      return true;
   }
   else
   {
      LogError(StringFormat("Failed to open position for %s: %s", symbol, m_trade.ResultComment()), "ExecuteTrade");
      return false;
   }
}

//+------------------------------------------------------------------+
//| Calculate position size based on risk                           |
//+------------------------------------------------------------------+
double CTradeManager::CalculatePositionSize(const string symbol, double sl_distance)
{
   if(sl_distance <= 0.0)
      return m_min_lot_size;
   
   // Update account balance
   m_account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   
   double risk_amount = m_account_balance * (m_risk_percent / 100.0);
   
   // Get point value
   double point_value = GetPointValue(symbol);
   double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   
   if(tick_value == 0.0)
      tick_value = point_value * 10.0; // Fallback calculation
   
   // Calculate position size
   double position_size = risk_amount / (sl_distance * tick_value * 100000); // Assuming standard lot is 100,000
   
   // Apply limits
   position_size = MathMax(position_size, m_min_lot_size);
   position_size = MathMin(position_size, m_max_lot_size);
   position_size = MathMin(position_size, GetMaxAllowedVolume(symbol));
   
   LogDebug(StringFormat("Position size calculated: %s, Risk: %.2f, SL Distance: %.5f, Size: %.2f", 
                        symbol, risk_amount, sl_distance, position_size), "CalculatePositionSize");
   
   return position_size;
}

//+------------------------------------------------------------------+
//| Calculate stop loss level                                        |
//+------------------------------------------------------------------+
double CTradeManager::CalculateStopLoss(const string symbol, ENUM_ORDER_TYPE order_type, double entry_price)
{
   double sl_price = 0.0;
   
   // Use S&R based SL if enabled and SR engine is available
   if(m_settings.use_sr_based_sl && m_sr_engine != NULL)
   {
      ENUM_SIGNAL_DIRECTION direction = (order_type == ORDER_TYPE_BUY) ? SIGNAL_BUY : SIGNAL_SELL;
      sl_price = m_sr_engine.GetOptimalSL(symbol, entry_price, direction);
      
      if(sl_price > 0.0)
      {
         // Add buffer beyond S&R level
         double buffer = GetPointValue(symbol) * m_settings.sr_sl_buffer * 10; // Convert pips to points
         
         if(order_type == ORDER_TYPE_BUY)
            sl_price -= buffer;
         else
            sl_price += buffer;
         
         sl_price = NormalizePrice(symbol, sl_price);
         
         LogDebug(StringFormat("S&R based SL calculated for %s: SL=%.5f (with buffer=%.1f pips)", 
                              symbol, sl_price, m_settings.sr_sl_buffer), "CalculateStopLoss");
         return sl_price;
      }
   }
   
   // Fallback to ATR-based SL
   int atr_handle = iATR(symbol, PERIOD_CURRENT, m_settings.atr_period);
   if(atr_handle == INVALID_HANDLE)
   {
      LogError(StringFormat("Cannot get ATR handle for %s", symbol), "CalculateStopLoss");
      return 0.0;
   }
   
   double atr_buffer[];
   if(CopyBuffer(atr_handle, 0, 0, 1, atr_buffer) <= 0)
   {
      IndicatorRelease(atr_handle);
      LogError(StringFormat("Cannot get ATR value for %s", symbol), "CalculateStopLoss");
      return 0.0;
   }
   
   double atr_value = atr_buffer[0];
   IndicatorRelease(atr_handle);
   
   if(atr_value == 0.0)
      return 0.0;
   
   double sl_distance = atr_value * m_settings.sl_atr_multiplier;
   
   if(order_type == ORDER_TYPE_BUY)
   {
      sl_price = entry_price - sl_distance;
   }
   else
   {
      sl_price = entry_price + sl_distance;
   }
   
   // Normalize price
   sl_price = NormalizePrice(symbol, sl_price);
   
   LogDebug(StringFormat("ATR based SL calculated for %s: ATR=%.5f, Distance=%.5f, SL=%.5f", 
                        symbol, atr_value, sl_distance, sl_price), "CalculateStopLoss");
   
   return sl_price;
}

//+------------------------------------------------------------------+
//| Calculate take profit level                                      |
//+------------------------------------------------------------------+
double CTradeManager::CalculateTakeProfit(const string symbol, ENUM_ORDER_TYPE order_type, 
                                          double entry_price, double sl_distance)
{
   double tp_price = 0.0;
   
   // Use S&R based TP if enabled and SR engine is available
   if(m_settings.use_sr_based_tp && m_sr_engine != NULL)
   {
      ENUM_SIGNAL_DIRECTION direction = (order_type == ORDER_TYPE_BUY) ? SIGNAL_BUY : SIGNAL_SELL;
      tp_price = m_sr_engine.GetOptimalTP(symbol, entry_price, direction);
      
      if(tp_price > 0.0)
      {
         // Add buffer before S&R level
         double buffer = GetPointValue(symbol) * m_settings.sr_tp_buffer * 10; // Convert pips to points
         
         if(order_type == ORDER_TYPE_BUY)
            tp_price -= buffer;
         else
            tp_price += buffer;
         
         tp_price = NormalizePrice(symbol, tp_price);
         
         LogDebug(StringFormat("S&R based TP calculated for %s: TP=%.5f (with buffer=%.1f pips)", 
                              symbol, tp_price, m_settings.sr_tp_buffer), "CalculateTakeProfit");
         return tp_price;
      }
   }
   
   // Fallback to R:R based TP
   if(sl_distance <= 0.0)
      return 0.0;
   
   double tp_distance = sl_distance * m_settings.tp_rr_ratio;
   
   if(order_type == ORDER_TYPE_BUY)
   {
      tp_price = entry_price + tp_distance;
   }
   else
   {
      tp_price = entry_price - tp_distance;
   }
   
   // Normalize price
   tp_price = NormalizePrice(symbol, tp_price);
   
   LogDebug(StringFormat("R:R based TP calculated for %s: TP Distance=%.5f, TP=%.5f, R:R=%.1f", 
                        symbol, tp_distance, tp_price, m_settings.tp_rr_ratio), "CalculateTakeProfit");
   
   return tp_price;
}

//+------------------------------------------------------------------+
//| Update positions array from terminal                            |
//+------------------------------------------------------------------+
bool CTradeManager::UpdatePositionsArray()
{
   int terminal_positions = PositionsTotal();
   m_positions_count = 0;
   
   for(int i = 0; i < terminal_positions; i++)
   {
      if(PositionGetSymbol(i) == "")
         continue;
      
      ulong ticket = PositionGetInteger(POSITION_TICKET);
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      
      // Check if position belongs to our EA
      if(magic != MAGIC_TREND_STRATEGY && magic != MAGIC_RANGE_STRATEGY)
         continue;
      
      // Resize array if needed
      if(m_positions_count >= ArraySize(m_positions))
      {
         ArrayResize(m_positions, ArraySize(m_positions) + 50);
      }
      
      // Fill position info
      
      m_positions[m_positions_count].symbol = PositionGetString(POSITION_SYMBOL);
      m_positions[m_positions_count].ticket = (int)ticket;
      m_positions[m_positions_count].position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      m_positions[m_positions_count].entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
      m_positions[m_positions_count].volume = PositionGetDouble(POSITION_VOLUME);
      m_positions[m_positions_count].sl_price = PositionGetDouble(POSITION_SL);
      m_positions[m_positions_count].tp_price = PositionGetDouble(POSITION_TP);
      m_positions[m_positions_count].open_time = (datetime)PositionGetInteger(POSITION_TIME);
      m_positions[m_positions_count].current_profit = PositionGetDouble(POSITION_PROFIT);
      m_positions[m_positions_count].comment = PositionGetString(POSITION_COMMENT);
      
      // Calculate trailing stop info
      m_positions[m_positions_count].trailing_active = ShouldActivateTrailing(m_positions[m_positions_count]);
      m_positions[m_positions_count].trailing_sl = CalculateTrailingStopLevel(m_positions[m_positions_count]);
      
      m_positions_count++;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Process trailing stops for all positions                        |
//+------------------------------------------------------------------+
void CTradeManager::ProcessTrailingStops()
{
   if(!m_initialized)
      return;
   
   UpdatePositionsArray();
   
   for(int i = 0; i < m_positions_count; i++)
   {
      ProcessTrailingStop(m_positions[i]);
   }
}

//+------------------------------------------------------------------+
//| Process trailing stop for single position                       |
//+------------------------------------------------------------------+
bool CTradeManager::ProcessTrailingStop(STradeInfo& position)
{
   if(!ShouldActivateTrailing(position))
      return true;
   
   double new_trailing_sl = CalculateTrailingStopLevel(position);
   if(new_trailing_sl == 0.0)
      return false;
   
   // Check if we should update the stop loss
   bool should_update = false;
   
   if(position.position_type == POSITION_TYPE_BUY)
   {
      // For buy positions, only move SL up
      if(new_trailing_sl > position.sl_price)
         should_update = true;
   }
   else
   {
      // For sell positions, only move SL down
      if(new_trailing_sl < position.sl_price)
         should_update = true;
   }
   
   if(should_update)
   {
      if(ModifyPosition(position.ticket, new_trailing_sl, position.tp_price))
      {
         LogInfo(StringFormat("TRAILING STOP updated for %s: Ticket=%d, New SL=%.5f", 
                             position.symbol, position.ticket, new_trailing_sl), "ProcessTrailingStop");
         position.sl_price = new_trailing_sl;
         position.trailing_sl = new_trailing_sl;
         return true;
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check if trailing stop should be activated                      |
//+------------------------------------------------------------------+
bool CTradeManager::ShouldActivateTrailing(const STradeInfo& position)
{
   if(position.entry_price == 0.0)
      return false;
   
   // Get current price
   double current_price = (position.position_type == POSITION_TYPE_BUY) ? 
                          SymbolInfoDouble(position.symbol, SYMBOL_BID) : 
                          SymbolInfoDouble(position.symbol, SYMBOL_ASK);
   
   if(current_price == 0.0)
      return false;
   
   // Get ATR for activation threshold
   int atr_handle = iATR(position.symbol, PERIOD_CURRENT, m_settings.atr_period);
   if(atr_handle == INVALID_HANDLE)
      return false;
   
   double atr_buffer[];
   if(CopyBuffer(atr_handle, 0, 0, 1, atr_buffer) <= 0)
   {
      IndicatorRelease(atr_handle);
      return false;
   }
   
   double atr_value = atr_buffer[0];
   IndicatorRelease(atr_handle);
   
   if(atr_value == 0.0)
      return false;
   
   double activation_distance = m_settings.ts_activation_pips * GetPointValue(position.symbol) * 10;
   double profit_distance = 0.0;
   
   if(position.position_type == POSITION_TYPE_BUY)
   {
      profit_distance = current_price - position.entry_price;
   }
   else
   {
      profit_distance = position.entry_price - current_price;
   }
   
   return (profit_distance >= activation_distance);
}

//+------------------------------------------------------------------+
//| Calculate trailing stop level                                   |
//+------------------------------------------------------------------+
double CTradeManager::CalculateTrailingStopLevel(const STradeInfo& position)
{
   // Get current price
   double current_price = (position.position_type == POSITION_TYPE_BUY) ? 
                          SymbolInfoDouble(position.symbol, SYMBOL_BID) : 
                          SymbolInfoDouble(position.symbol, SYMBOL_ASK);
   
   if(current_price == 0.0)
      return 0.0;
   
   // Get ATR for trailing distance
   int atr_handle = iATR(position.symbol, PERIOD_CURRENT, m_settings.atr_period);
   if(atr_handle == INVALID_HANDLE)
      return 0.0;
   
   double atr_buffer[];
   if(CopyBuffer(atr_handle, 0, 0, 1, atr_buffer) <= 0)
   {
      IndicatorRelease(atr_handle);
      return 0.0;
   }
   
   double atr_value = atr_buffer[0];
   IndicatorRelease(atr_handle);
   
   if(atr_value == 0.0)
      return 0.0;
   
   double trailing_distance = m_settings.ts_distance_pips * GetPointValue(position.symbol) * 10;
   double trailing_sl = 0.0;
   
   if(position.position_type == POSITION_TYPE_BUY)
   {
      trailing_sl = current_price - trailing_distance;
   }
   else
   {
      trailing_sl = current_price + trailing_distance;
   }
   
   return NormalizePrice(position.symbol, trailing_sl);
}

//+------------------------------------------------------------------+
//| Modify position SL and TP                                       |
//+------------------------------------------------------------------+
bool CTradeManager::ModifyPosition(ulong ticket, double new_sl, double new_tp)
{
   if(!PositionSelectByTicket(ticket))
      return false;
   
   string symbol = PositionGetString(POSITION_SYMBOL);
   
   // Normalize prices
   new_sl = NormalizePrice(symbol, new_sl);
   new_tp = NormalizePrice(symbol, new_tp);
   
   bool result = m_trade.PositionModify(ticket, new_sl, new_tp);
   
   if(!result)
   {
      LogError(StringFormat("Failed to modify position %I64u: %s", ticket, m_trade.ResultComment()), "ModifyPosition");
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| Close position                                                   |
//+------------------------------------------------------------------+
bool CTradeManager::ClosePosition(ulong ticket, const string reason = "")
{
   if(!PositionSelectByTicket(ticket))
      return false;
   
   string symbol = PositionGetString(POSITION_SYMBOL);
   double volume = PositionGetDouble(POSITION_VOLUME);
   
   bool result = m_trade.PositionClose(ticket);
   
   if(result)
   {
      LogInfo(StringFormat("POSITION CLOSED: %s Ticket=%I64u Volume=%.2f Reason=%s", 
                          symbol, ticket, volume, 
                          (reason == "") ? "Manual" : reason), "ClosePosition");
      UpdatePositionsArray();
   }
   else
   {
      LogError(StringFormat("Failed to close position %I64u: %s", ticket, m_trade.ResultComment()), "ClosePosition");
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| Get positions count by symbol                                   |
//+------------------------------------------------------------------+
int CTradeManager::GetPositionsCountBySymbol(const string symbol)
{
   int count = 0;
   
   for(int i = 0; i < m_positions_count; i++)
   {
      if(m_positions[i].symbol == symbol)
         count++;
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Check if position exists for symbol                             |
//+------------------------------------------------------------------+
bool CTradeManager::HasPosition(const string symbol)
{
   return (GetPositionsCountBySymbol(symbol) > 0);
}

//+------------------------------------------------------------------+
//| Get total profit from all positions                             |
//+------------------------------------------------------------------+
double CTradeManager::GetTotalProfit()
{
   double total_profit = 0.0;
   
   for(int i = 0; i < m_positions_count; i++)
   {
      total_profit += m_positions[i].current_profit;
   }
   
   return total_profit;
}

//+------------------------------------------------------------------+
//| Get profit for specific symbol                                  |
//+------------------------------------------------------------------+
double CTradeManager::GetSymbolProfit(const string symbol)
{
   double symbol_profit = 0.0;
   
   for(int i = 0; i < m_positions_count; i++)
   {
      if(m_positions[i].symbol == symbol)
         symbol_profit += m_positions[i].current_profit;
   }
   
   return symbol_profit;
}

//+------------------------------------------------------------------+
//| Get position info by index                                      |
//+------------------------------------------------------------------+
STradeInfo CTradeManager::GetPositionInfo(int index)
{
   STradeInfo empty_info;
   ZeroMemory(empty_info);
   
   if(index >= 0 && index < m_positions_count)
      return m_positions[index];
   
   return empty_info;
}

//+------------------------------------------------------------------+
//| Get position by symbol                                           |
//+------------------------------------------------------------------+
STradeInfo CTradeManager::GetPositionBySymbol(const string symbol)
{
   STradeInfo empty_info;
   ZeroMemory(empty_info);
   
   for(int i = 0; i < m_positions_count; i++)
   {
      if(m_positions[i].symbol == symbol)
         return m_positions[i];
   }
   
   return empty_info;
}

//+------------------------------------------------------------------+
//| Validate trade request                                           |
//+------------------------------------------------------------------+
bool CTradeManager::ValidateTradeRequest(const string symbol, ENUM_ORDER_TYPE order_type, double volume)
{
   // Check if trading is allowed
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
   {
      LogError("Trading is not allowed in terminal", "ValidateTradeRequest");
      return false;
   }
   
   // Check if symbol is tradeable
   if(!SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE))
   {
      LogError(StringFormat("Trading is not allowed for %s", symbol), "ValidateTradeRequest");
      return false;
   }
   
   // Check volume limits
   double min_volume = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double max_volume = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   
   if(volume < min_volume || volume > max_volume)
   {
      LogError(StringFormat("Invalid volume for %s: %.2f (min: %.2f, max: %.2f)", 
                           symbol, volume, min_volume, max_volume), "ValidateTradeRequest");
      return false;
   }
   
   // Check risk management
   if(!ValidateRiskManagement(symbol, volume))
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Validate risk management                                         |
//+------------------------------------------------------------------+
bool CTradeManager::ValidateRiskManagement(const string symbol, double volume)
{
   // Check account balance
   if(AccountInfoDouble(ACCOUNT_BALANCE) <= 0)
   {
      LogError("Account balance is zero or negative", "ValidateRiskManagement");
      return false;
   }
   
   // Check margin requirements
   double margin_required = 0.0;
   if(!OrderCalcMargin(ORDER_TYPE_BUY, symbol, volume, 
                       SymbolInfoDouble(symbol, SYMBOL_ASK), margin_required))
   {
      LogError(StringFormat("Cannot calculate margin for %s", symbol), "ValidateRiskManagement");
      return false;
   }
   
   double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(margin_required > free_margin * 0.8) // Use only 80% of free margin
   {
      LogWarning(StringFormat("Insufficient margin: Required=%.2f, Available=%.2f", 
                             margin_required, free_margin), "ValidateRiskManagement");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Get maximum allowed volume                                       |
//+------------------------------------------------------------------+
double CTradeManager::GetMaxAllowedVolume(const string symbol)
{
   double max_volume = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   
   // Limit based on account balance
   double balance_limit = AccountInfoDouble(ACCOUNT_BALANCE) / 10000.0; // Conservative limit
   
   return MathMin(max_volume, balance_limit);
}

//+------------------------------------------------------------------+
//| Check maximum positions limit                                   |
//+------------------------------------------------------------------+
bool CTradeManager::CheckMaxPositions(const string symbol)
{
   int current_positions = GetPositionsCountBySymbol(symbol);
   return (current_positions < m_settings.max_positions_per_symbol);
}

//+------------------------------------------------------------------+
//| Generate trade comment                                           |
//+------------------------------------------------------------------+
string CTradeManager::GenerateComment(const string symbol, ENUM_SIGNAL_DIRECTION signal, ENUM_STRATEGY_TYPE strategy)
{
   string strategy_text = (strategy == STRATEGY_TREND) ? "T" : "R";
   string signal_text = (signal == SIGNAL_BUY) ? "B" : "S";
   
   return StringFormat("SR_%s_%s_%s", strategy_text, signal_text, symbol);
}

//+------------------------------------------------------------------+
//| Get magic number for strategy                                   |
//+------------------------------------------------------------------+
int CTradeManager::GetMagicNumber(ENUM_STRATEGY_TYPE strategy)
{
   return (strategy == STRATEGY_TREND) ? MAGIC_TREND_STRATEGY : MAGIC_RANGE_STRATEGY;
}

//+------------------------------------------------------------------+
//| Update positions                                                 |
//+------------------------------------------------------------------+
void CTradeManager::UpdatePositions()
{
   UpdatePositionsArray();
}

//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CTradeManager::CloseAllPositions(const string reason = "")
{
   UpdatePositionsArray();
   
   for(int i = m_positions_count - 1; i >= 0; i--)
   {
      ClosePosition(m_positions[i].ticket, reason);
   }
}

//+------------------------------------------------------------------+
//| Close positions by symbol                                        |
//+------------------------------------------------------------------+
void CTradeManager::ClosePositionsBySymbol(const string symbol, const string reason = "")
{
   UpdatePositionsArray();
   
   for(int i = m_positions_count - 1; i >= 0; i--)
   {
      if(m_positions[i].symbol == symbol)
         ClosePosition(m_positions[i].ticket, reason);
   }
}

//+------------------------------------------------------------------+
//| Determine grid status                                            |
//+------------------------------------------------------------------+
ENUM_GRID_STATUS CTradeManager::DetermineGridStatus(const string symbol)
{
   int positions_count = GetPositionsCountBySymbol(symbol);
   
   if(positions_count == 0)
      return GRID_NONE;
   else if(positions_count == 1)
   {
      // Check if position is in profit
      double symbol_profit = GetSymbolProfit(symbol);
      return (symbol_profit >= 0) ? GRID_ACTIVE : GRID_RECOVERY;
   }
   else
      return GRID_RECOVERY; // Multiple positions indicate recovery mode
}

//+------------------------------------------------------------------+
//| Get grid status                                                  |
//+------------------------------------------------------------------+
ENUM_GRID_STATUS CTradeManager::GetGridStatus(const string symbol)
{
   return DetermineGridStatus(symbol);
}

//+------------------------------------------------------------------+
//| Update grid status                                               |
//+------------------------------------------------------------------+
bool CTradeManager::UpdateGridStatus(const string symbol, ENUM_GRID_STATUS new_status)
{
   // This method can be used to manually set grid status if needed
   // For now, grid status is determined automatically
   return true;
}

//+------------------------------------------------------------------+
//| Set risk percentage                                              |
//+------------------------------------------------------------------+
void CTradeManager::SetRiskPercent(double risk_percent)
{
   m_risk_percent = MathMax(0.1, MathMin(10.0, risk_percent)); // Limit between 0.1% and 10%
   LogInfo(StringFormat("Risk percentage set to %.1f%%", m_risk_percent), "SetRiskPercent");
}

//+------------------------------------------------------------------+
//| Set maximum lot size                                             |
//+------------------------------------------------------------------+
void CTradeManager::SetMaxLotSize(double max_lot)
{
   m_max_lot_size = MathMax(m_min_lot_size, max_lot);
   LogInfo(StringFormat("Max lot size set to %.2f", m_max_lot_size), "SetMaxLotSize");
}

//+------------------------------------------------------------------+
//| Print all positions                                              |
//+------------------------------------------------------------------+
void CTradeManager::PrintPositions()
{
   UpdatePositionsArray();
   
   g_Logger.Info(StringFormat("=== Active Positions (%d) ===", m_positions_count));
   
   for(int i = 0; i < m_positions_count; i++)
   {
      g_Logger.Info(StringFormat("%d: %s %s %.2f @ %.5f, SL: %.5f, TP: %.5f, Profit: %.2f", 
                        i + 1,
                        m_positions[i].symbol,
                        (m_positions[i].position_type == POSITION_TYPE_BUY) ? "BUY" : "SELL",
                        m_positions[i].volume,
                        m_positions[i].entry_price,
                        m_positions[i].sl_price,
                        m_positions[i].tp_price,
                        m_positions[i].current_profit));
   }
   
   g_Logger.Info(StringFormat("Total Profit: %s", DoubleToString(GetTotalProfit(), 2)));
   g_Logger.Info("=============================");
}

//+------------------------------------------------------------------+
//| Get trade statistics                                             |
//+------------------------------------------------------------------+
string CTradeManager::GetTradeStatistics()
{
   UpdatePositionsArray();
   
   double total_profit = GetTotalProfit();
   
   return StringFormat("Positions: %d, Total Profit: %.2f, Balance: %.2f, Risk: %.1f%%",
                      m_positions_count,
                      total_profit,
                      m_account_balance,
                      m_risk_percent);
}

//+------------------------------------------------------------------+
