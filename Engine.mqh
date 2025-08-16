//+------------------------------------------------------------------+
//| Engine.mqh                                                       |
//| Copyright 2024, SuppResist                                       |
//| https://www.mql5.com                                             |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, SuppResist"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "SuppResist.mqh"
#include "Settings.mqh"
#include "Logger.mqh"
#include "Filter.mqh"
#include "TradeManager.mqh"
#include "Dashboard.mqh"
#include "SR_Engine.mqh"
#include "CurrencyStrength.mqh"
#include "CurrencyScoring.mqh"

//+------------------------------------------------------------------+
//| CEngine Class - Main Coordination Engine                        |
//+------------------------------------------------------------------+
class CEngine
{
private:
   // Core components
   CSettings         m_settings;                    // Settings manager
   CFilter           m_filter;                      // Market filter (legacy)
   CTradeManager     m_trade_manager;               // Trade manager
   CDashboard        m_dashboard;                   // Dashboard
   CSR_Engine        m_sr_engine;                   // Support/Resistance engine
   CCurrencyStrength m_currency_strength;           // Currency strength calculator
   CCurrencyScoring  m_currency_scoring;            // Currency pair scoring system
   
   // State management
   bool              m_initialized;                 // Engine initialization flag
   bool              m_running;                     // Engine running flag
   bool              m_error_state;                 // Error state flag
   
   // Timing and performance
   datetime          m_last_tick_time;              // Last tick processing time
   datetime          m_last_update_time;            // Last dashboard update time
   datetime          m_last_signal_check_time;      // Last signal check time
   uint              m_tick_count;                  // Total tick count
   uint              m_update_interval_ms;          // Update interval in milliseconds
   uint              m_signal_check_interval_ms;    // Signal check interval in milliseconds
   
   // Data storage
   SSignalInfo       m_signal_info[];               // Current signal information
   SMarketStatusInfo m_market_status;               // Market status
   
   // Performance monitoring
   uint              m_avg_tick_time_ms;            // Average tick processing time
   uint              m_max_tick_time_ms;            // Maximum tick processing time
   uint              m_performance_samples[];       // Performance samples for averaging
   int               m_performance_index;           // Current index in performance samples
   
   // Internal methods
   bool InitializeComponents();
   void DeinitializeComponents();
   bool ValidateComponentsHealth();
   
   // Processing methods
   void ProcessTick();
   void ProcessSignals();
   void ProcessTrades();
   void UpdateDashboard();
   void UpdateMarketStatus();
   
   // Data management
   void RefreshSignalData();
   void UpdatePositionData();
   void CheckForNewBars();
   
   // Performance monitoring
   void StartPerformanceMeasurement();
   void EndPerformanceMeasurement(uint start_time);
   void UpdatePerformanceStatistics(uint execution_time_ms);
   
   // Error handling
   void HandleError(const string error_message, const string function_name);
   bool RecoverFromError();
   void EnterSafeMode();
   
   // Timer management
   bool ShouldUpdateDashboard();
   bool ShouldCheckSignals();
   void ResetTimers();
   
   // Utility methods
   string GetEngineStatus();
   void LogPerformanceStatistics();
   
public:
   // Constructor/Destructor
   CEngine();
   ~CEngine();
   
   // Main interface methods (called from EA)
   int OnInit();
   void OnTick();
   void OnDeinit(const int reason);
   void OnTimer();
   
   // Control methods
   bool Start();
   bool Stop();
   bool Pause();
   bool Resume();
   bool Restart();
   
   // Status methods
   bool IsInitialized() const { return m_initialized; }
   bool IsRunning() const { return m_running; }
   bool IsInErrorState() const { return m_error_state; }
   
   // Configuration methods
   bool UpdateSettings();
   void SetUpdateInterval(uint interval_ms);
   void SetSignalCheckInterval(uint interval_ms);
   
   // Component access (for debugging)
   CSettings* GetSettings() { return &m_settings; }
   CFilter* GetFilter() { return &m_filter; }
   CTradeManager* GetTradeManager() { return &m_trade_manager; }
   CDashboard* GetDashboard() { return &m_dashboard; }
   CSR_Engine* GetSREngine() { return &m_sr_engine; }
   CCurrencyStrength* GetCurrencyStrength() { return &m_currency_strength; }
   CCurrencyScoring* GetCurrencyScoring() { return &m_currency_scoring; }
   
   // Information methods
   string GetStatistics();
   string GetPerformanceInfo();
   SMarketStatusInfo GetMarketStatus() const { return m_market_status; }
   
   // Dashboard control
   void ShowDashboard();
   void HideDashboard();
   void ToggleDashboard();
   
   // Manual operations
   void ForceSignalCheck();
   void ForcePositionUpdate();
   void ForceDashboardRefresh();
   void CloseAllPositions(const string reason = "Manual close");
   
   // Debug methods
   void PrintEngineStatus();
   void PrintPerformanceReport();
   void EnableDebugMode(bool enable);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CEngine::CEngine() : m_initialized(false),
                     m_running(false),
                     m_error_state(false),
                     m_last_tick_time(0),
                     m_last_update_time(0),
                     m_last_signal_check_time(0),
                     m_tick_count(0),
                     m_update_interval_ms(UPDATE_INTERVAL_MS),
                     m_signal_check_interval_ms(SIGNAL_CHECK_INTERVAL_MS),
                     m_avg_tick_time_ms(0),
                     m_max_tick_time_ms(0),
                     m_performance_index(0)
{
   ZeroMemory(m_market_status);
   ArrayResize(m_performance_samples, 100); // Keep 100 samples for averaging
   ArrayInitialize(m_performance_samples, 0);
   
   m_market_status.status = MARKET_LOADING;
   m_market_status.status_text = "Inicializace...";
   m_market_status.status_color = clrBlue;
   m_market_status.symbols_total = 0;
   m_market_status.symbols_processed = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CEngine::~CEngine()
{
   if(m_initialized)
      OnDeinit(REASON_PROGRAM);
}

//+------------------------------------------------------------------+
//| Initialize engine                                                |
//+------------------------------------------------------------------+
int CEngine::OnInit()
{
   LogInfo("SuppResist Engine initialization started", "OnInit");
   
   // Initialize global logger first
   g_Logger.Initialize("SuppResist", InpEnableDebugLogging, InpLogToFile, true);
   
   if(!InitializeComponents())
   {
      LogError("Failed to initialize engine components", "OnInit");
      return INIT_FAILED;
   }
   
   // Start performance monitoring
   ArrayResize(m_performance_samples, 100);
   ArrayInitialize(m_performance_samples, 0);
   m_performance_index = 0;
   
   m_initialized = true;
   m_running = true;
   m_error_state = false;
   
   // Reset timers
   ResetTimers();
   
   // Set timer for periodic updates
   EventSetTimer(1); // 1 second timer
   
   LogInfo("SuppResist Engine initialized successfully", "OnInit");
   LogInfo(GetEngineStatus(), "OnInit");
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Process tick                                                     |
//+------------------------------------------------------------------+
void CEngine::OnTick()
{
   if(!m_initialized || !m_running || m_error_state)
      return;
   
   uint start_time = GetTickCount();
   
   ProcessTick();
   m_tick_count++;
   m_last_tick_time = TimeCurrent();
   
   EndPerformanceMeasurement(start_time);
}

//+------------------------------------------------------------------+
//| Deinitialize engine                                              |
//+------------------------------------------------------------------+
void CEngine::OnDeinit(const int reason)
{
   if(!m_initialized)
      return;
   
   LogInfo(StringFormat("SuppResist Engine deinitialization (reason: %d)", reason), "OnDeinit");
   
   // Stop timer
   EventKillTimer();
   
   // Stop engine
   Stop();
   
   // Print final statistics
   if(m_tick_count > 0)
   {
      LogPerformanceStatistics();
      PrintPerformanceReport();
   }
   
   // Deinitialize components
   DeinitializeComponents();
   
   m_initialized = false;
   
   LogInfo("SuppResist Engine deinitialized", "OnDeinit");
   
   // Deinitialize logger last
   g_Logger.Deinitialize();
}

//+------------------------------------------------------------------+
//| Timer event handler                                              |
//+------------------------------------------------------------------+
void CEngine::OnTimer()
{
   if(!m_initialized || !m_running || m_error_state)
      return;
   
   // Check if we should update dashboard
   if(ShouldUpdateDashboard())
   {
      UpdateDashboard();
      m_last_update_time = TimeCurrent();
   }
   
   // Check if we should process signals
   if(ShouldCheckSignals())
   {
      ProcessSignals();
      m_last_signal_check_time = TimeCurrent();
   }
   
   // Update market status
   UpdateMarketStatus();
   
   // Validate components health
   if(!ValidateComponentsHealth())
   {
      LogWarning("Component health check failed", "OnTimer");
   }
   
   // Log performance statistics periodically
   static datetime last_stats_log = 0;
   if(TimeCurrent() - last_stats_log > 300) // Every 5 minutes
   {
      LogPerformanceStatistics();
      last_stats_log = TimeCurrent();
   }
}

//+------------------------------------------------------------------+
//| Initialize all components                                        |
//+------------------------------------------------------------------+
bool CEngine::InitializeComponents()
{
   LogInfo("Initializing engine components...", "InitializeComponents");
   
   // Initialize settings first
   if(!m_settings.Initialize())
   {
      LogError("Failed to initialize settings", "InitializeComponents");
      return false;
   }
   
   SSettings settings = m_settings.GetSettings();
   
   // Initialize S&R engine
   if(!m_sr_engine.Initialize(settings))
   {
      LogError("Failed to initialize S&R engine", "InitializeComponents");
      return false;
   }
   
   // Initialize currency strength
   if(!m_currency_strength.Initialize(settings))
   {
      LogError("Failed to initialize currency strength", "InitializeComponents");
      return false;
   }
   
   // Initialize currency scoring
   if(!m_currency_scoring.Initialize(settings, &m_sr_engine, &m_currency_strength))
   {
      LogError("Failed to initialize currency scoring", "InitializeComponents");
      return false;
   }
   
   // Initialize trade manager
   if(!m_trade_manager.Initialize(settings))
   {
      LogError("Failed to initialize trade manager", "InitializeComponents");
      return false;
   }
   
   // Set SR engine reference in trade manager
   m_trade_manager.SetSREngine(&m_sr_engine);
   
   // Initialize dashboard
   if(InpShowPanel && !m_dashboard.Initialize(settings, settings.symbols))
   {
      LogError("Failed to initialize dashboard", "InitializeComponents");
      return false;
   }
   
   // Initialize legacy filter (for backward compatibility)
   if(!m_filter.Initialize(settings))
   {
      LogError("Failed to initialize filter", "InitializeComponents");
      return false;
   }
   
   // Initialize signal data array
   ArrayResize(m_signal_info, settings.symbols_count);
   for(int i = 0; i < settings.symbols_count; i++)
   {
      ZeroMemory(m_signal_info[i]);
      m_signal_info[i].symbol = settings.symbols[i];
   }
   
   // Set market status
   m_market_status.symbols_total = settings.symbols_count;
   m_market_status.symbols_processed = 0;
   m_market_status.status = MARKET_LOADING;
   m_market_status.status_text = "Komponenty inicializovány";
   m_market_status.status_color = clrBlue;
   m_market_status.last_update = TimeCurrent();
   
   LogInfo("All engine components initialized successfully", "InitializeComponents");
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize all components                                      |
//+------------------------------------------------------------------+
void CEngine::DeinitializeComponents()
{
   LogInfo("Deinitializing engine components...", "DeinitializeComponents");
   
   m_dashboard.Deinitialize();
   m_trade_manager.Deinitialize();
   m_currency_scoring.Deinitialize();
   m_currency_strength.Deinitialize();
   m_sr_engine.Deinitialize();
   m_filter.Deinitialize();
   m_settings.Deinitialize();
   
   ArrayFree(m_signal_info);
   
   LogInfo("All engine components deinitialized", "DeinitializeComponents");
}

//+------------------------------------------------------------------+
//| Validate components health                                       |
//+------------------------------------------------------------------+
bool CEngine::ValidateComponentsHealth()
{
   bool all_healthy = true;
   
   if(!m_settings.IsInitialized())
   {
      LogError("Settings component is not healthy", "ValidateComponentsHealth");
      all_healthy = false;
   }
   
   if(!m_filter.IsSymbolSupported(_Symbol))
   {
      LogWarning("Filter component health check failed", "ValidateComponentsHealth");
   }
   
   // Add more health checks as needed
   
   return all_healthy;
}

//+------------------------------------------------------------------+
//| Process tick event                                               |
//+------------------------------------------------------------------+
void CEngine::ProcessTick()
{
   MEASURE_PERFORMANCE("ProcessTick");
   
   // Check for new bars on any symbols
   CheckForNewBars();
   
   // Update position data
   UpdatePositionData();
   
   // Process trailing stops
   m_trade_manager.ProcessTrailingStops();
   
   // Process trades if we have new signals
   ProcessTrades();
}

//+------------------------------------------------------------------+
//| Process signals for all symbols                                 |
//+------------------------------------------------------------------+
void CEngine::ProcessSignals()
{
   MEASURE_PERFORMANCE("ProcessSignals");
   
   LogDebug("Processing signals for all symbols", "ProcessSignals");
   
   SSettings settings = m_settings.GetSettings();
   int processed_count = 0;
   
   // Update currency strength and scoring
   m_currency_strength.CalculateAllStrengths();
   m_currency_scoring.CalculateAllScores();
   
   // Get tradeable pairs based on scoring
   string tradeable_symbols[];
   double tradeable_scores[];
   m_currency_scoring.GetTradeablePairs(tradeable_symbols, tradeable_scores);
   
   LogDebug(StringFormat("Found %d tradeable pairs out of %d", ArraySize(tradeable_symbols), settings.symbols_count), "ProcessSignals");
   
   for(int i = 0; i < settings.symbols_count; i++)
   {
      string symbol = settings.symbols[i];
      
      // Initialize signal info
      ZeroMemory(m_signal_info[i]);
      m_signal_info[i].symbol = symbol;
      m_signal_info[i].last_update = TimeCurrent();
      
      // Update S&R levels for this symbol
      m_sr_engine.ScanAndUpdateLevels(symbol);
      
      // Get S&R signal
      ENUM_SIGNAL_DIRECTION sr_signal = m_sr_engine.CheckSRSignal(symbol);
      m_signal_info[i].final_signal = sr_signal;
      
      // Get currency scoring data
      CurrencyScore currency_score = m_currency_scoring.GetSymbolScore(symbol);
      m_signal_info[i].score = currency_score.total_score;
      
      // Determine strategy type based on score
      if(currency_score.total_score >= settings.min_trading_score)
      {
         m_signal_info[i].strategy_type = STRATEGY_RANGE; // S&R based strategy
      }
      else
      {
         m_signal_info[i].strategy_type = STRATEGY_TREND; // Fallback to trend
      }
      
      // Get S&R levels if enabled
      if(settings.show_support_resistance)
      {
         SRLevel nearest_support, nearest_resistance;
         double current_price = SymbolInfoDouble(symbol, SYMBOL_BID);
         
         if(m_sr_engine.GetNearestSRLevels(symbol, current_price, nearest_support, nearest_resistance))
         {
            m_signal_info[i].support_level = nearest_support.is_active ? nearest_support.price : 0.0;
            m_signal_info[i].resistance_level = nearest_resistance.is_active ? nearest_resistance.price : 0.0;
         }
      }
      
      // Calculate AI strength if enabled
      if(settings.use_ai_estimation)
      {
         // Placeholder for AI integration
         m_signal_info[i].ai_strength = 0;
      }
      
      // Update grid status from trade manager
      m_signal_info[i].grid_status = m_trade_manager.GetGridStatus(symbol);
      
      processed_count++;
      
      LogDebug(StringFormat("%s: Signal=%s, Score=%.1f, S=%.5f, R=%.5f", 
                           symbol, GetSignalText(sr_signal), currency_score.total_score,
                           m_signal_info[i].support_level, m_signal_info[i].resistance_level), "ProcessSignals");
   }
   
   // Update market status
   m_market_status.symbols_processed = processed_count;
   
   if(processed_count > 0)
   {
      m_market_status.status = MARKET_CONSOLIDATION; // This would be determined by analysis
      m_market_status.status_text = StringFormat("Signály zpracovány (%d/%d)", processed_count, settings.symbols_count);
      m_market_status.status_color = clrGreen;
   }
   
   LogDebug(StringFormat("Processed signals for %d/%d symbols", processed_count, settings.symbols_count), "ProcessSignals");
}

//+------------------------------------------------------------------+
//| Process trades based on current signals                         |
//+------------------------------------------------------------------+
void CEngine::ProcessTrades()
{
   MEASURE_PERFORMANCE("ProcessTrades");
   
   SSettings settings = m_settings.GetSettings();
   
   for(int i = 0; i < ArraySize(m_signal_info); i++)
   {
      if(m_signal_info[i].final_signal != SIGNAL_NONE)
      {
         // Process the signal through trade manager
         bool result = m_trade_manager.ProcessSignal(m_signal_info[i].symbol, m_signal_info[i]);
         
         if(result)
         {
            LogInfo(StringFormat("Processed signal for %s: %s", 
                               m_signal_info[i].symbol, 
                               GetSignalText(m_signal_info[i].final_signal)), "ProcessTrades");
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Update dashboard with current data                              |
//+------------------------------------------------------------------+
void CEngine::UpdateDashboard()
{
   if(!InpShowPanel || !m_dashboard.IsVisible())
      return;
   
   MEASURE_PERFORMANCE("UpdateDashboard");
   
   SSettings settings = m_settings.GetSettings();
   
   // Update dashboard with current signal info and market status
   bool result = m_dashboard.Update(settings, m_signal_info, m_market_status);
   
   if(!result)
   {
      LogWarning("Failed to update dashboard", "UpdateDashboard");
   }
   
   LogDebug("Dashboard updated", "UpdateDashboard");
}

//+------------------------------------------------------------------+
//| Update market status                                             |
//+------------------------------------------------------------------+
void CEngine::UpdateMarketStatus()
{
   m_market_status.last_update = TimeCurrent();
   
   // Analyze overall market conditions
   int trending_count = 0;
   int consolidation_count = 0;
   int total_signals = ArraySize(m_signal_info);
   
   for(int i = 0; i < total_signals; i++)
   {
      if(m_signal_info[i].strategy_type == STRATEGY_TREND)
         trending_count++;
      else if(m_signal_info[i].strategy_type == STRATEGY_RANGE)
         consolidation_count++;
   }
   
   if(trending_count > consolidation_count)
   {
      m_market_status.status = MARKET_TRENDING;
      m_market_status.status_text = StringFormat("Trend dominuje (%d/%d)", trending_count, total_signals);
      m_market_status.status_color = clrOrange;
   }
   else if(consolidation_count > 0)
   {
      m_market_status.status = MARKET_CONSOLIDATION;
      m_market_status.status_text = StringFormat("Konsolidace (%d/%d)", consolidation_count, total_signals);
      m_market_status.status_color = clrGreen;
   }
   else
   {
      m_market_status.status = MARKET_LOADING;
      m_market_status.status_text = "Čekání na signály...";
      m_market_status.status_color = clrBlue;
   }
}

//+------------------------------------------------------------------+
//| Refresh signal data for all symbols                             |
//+------------------------------------------------------------------+
void CEngine::RefreshSignalData()
{
   ProcessSignals();
}

//+------------------------------------------------------------------+
//| Update position data                                             |
//+------------------------------------------------------------------+
void CEngine::UpdatePositionData()
{
   m_trade_manager.UpdatePositions();
}

//+------------------------------------------------------------------+
//| Check for new bars on monitored symbols                         |
//+------------------------------------------------------------------+
void CEngine::CheckForNewBars()
{
   SSettings settings = m_settings.GetSettings();
   
   for(int i = 0; i < settings.symbols_count; i++)
   {
      string symbol = settings.symbols[i];
      
      if(IsNewBar(symbol, PERIOD_CURRENT))
      {
         LogDebug(StringFormat("New bar detected on %s", symbol), "CheckForNewBars");
         // Force signal recalculation for this symbol
         // This could trigger immediate signal processing for the specific symbol
      }
   }
}

//+------------------------------------------------------------------+
//| Start performance measurement                                    |
//+------------------------------------------------------------------+
void CEngine::StartPerformanceMeasurement()
{
   // This is handled by MEASURE_PERFORMANCE macro
}

//+------------------------------------------------------------------+
//| End performance measurement                                      |
//+------------------------------------------------------------------+
void CEngine::EndPerformanceMeasurement(uint start_time)
{
   uint execution_time = GetTickCount() - start_time;
   UpdatePerformanceStatistics(execution_time);
}

//+------------------------------------------------------------------+
//| Update performance statistics                                    |
//+------------------------------------------------------------------+
void CEngine::UpdatePerformanceStatistics(uint execution_time_ms)
{
   // Store sample
   m_performance_samples[m_performance_index] = execution_time_ms;
   m_performance_index = (m_performance_index + 1) % ArraySize(m_performance_samples);
   
   // Update max time
   if(execution_time_ms > m_max_tick_time_ms)
      m_max_tick_time_ms = execution_time_ms;
   
   // Calculate average
   uint sum = 0;
   int samples_count = ArraySize(m_performance_samples);
   
   for(int i = 0; i < samples_count; i++)
   {
      sum += m_performance_samples[i];
   }
   
   m_avg_tick_time_ms = sum / samples_count;
}

//+------------------------------------------------------------------+
//| Handle error                                                     |
//+------------------------------------------------------------------+
void CEngine::HandleError(const string error_message, const string function_name)
{
   LogError(error_message, function_name);
   
   // Try to recover from error
   if(!RecoverFromError())
   {
      LogCritical("Cannot recover from error, entering safe mode", function_name);
      EnterSafeMode();
   }
}

//+------------------------------------------------------------------+
//| Recover from error                                               |
//+------------------------------------------------------------------+
bool CEngine::RecoverFromError()
{
   LogInfo("Attempting error recovery...", "RecoverFromError");
   
   // Reset error state
   m_error_state = false;
   
   // Validate components
   if(!ValidateComponentsHealth())
   {
      LogError("Component health validation failed during recovery", "RecoverFromError");
      return false;
   }
   
   LogInfo("Error recovery successful", "RecoverFromError");
   return true;
}

//+------------------------------------------------------------------+
//| Enter safe mode                                                  |
//+------------------------------------------------------------------+
void CEngine::EnterSafeMode()
{
   LogCritical("Entering safe mode", "EnterSafeMode");
   
   m_error_state = true;
   m_running = false;
   
   // Close all positions
   m_trade_manager.CloseAllPositions("Safe mode activation");
   
   // Hide dashboard
   m_dashboard.Hide();
   
   m_market_status.status = MARKET_ERROR;
   m_market_status.status_text = "CHYBA - Bezpečný režim";
   m_market_status.status_color = clrRed;
}

//+------------------------------------------------------------------+
//| Check if should update dashboard                                |
//+------------------------------------------------------------------+
bool CEngine::ShouldUpdateDashboard()
{
   return ((TimeCurrent() - m_last_update_time) * 1000 >= m_update_interval_ms);
}

//+------------------------------------------------------------------+
//| Check if should check signals                                   |
//+------------------------------------------------------------------+
bool CEngine::ShouldCheckSignals()
{
   return ((TimeCurrent() - m_last_signal_check_time) * 1000 >= m_signal_check_interval_ms);
}

//+------------------------------------------------------------------+
//| Reset timers                                                     |
//+------------------------------------------------------------------+
void CEngine::ResetTimers()
{
   datetime current_time = TimeCurrent();
   m_last_tick_time = current_time;
   m_last_update_time = current_time;
   m_last_signal_check_time = current_time;
}

//+------------------------------------------------------------------+
//| Get engine status string                                         |
//+------------------------------------------------------------------+
string CEngine::GetEngineStatus()
{
   return StringFormat("Engine Status: %s, Components: Settings=%s Filter=%s TradeManager=%s Dashboard=%s",
                      m_running ? "RUNNING" : "STOPPED",
                      m_settings.IsInitialized() ? "OK" : "ERROR",
                      "OK", // Filter doesn't have IsInitialized method
                      "OK", // TradeManager doesn't have IsInitialized method  
                      m_dashboard.IsVisible() ? "VISIBLE" : "HIDDEN");
}

//+------------------------------------------------------------------+
//| Log performance statistics                                       |
//+------------------------------------------------------------------+
void CEngine::LogPerformanceStatistics()
{
   if(m_tick_count > 0)
   {
      LogInfo(StringFormat("Performance: Ticks=%d, AvgTime=%dms, MaxTime=%dms", 
                          m_tick_count, m_avg_tick_time_ms, m_max_tick_time_ms), "PerformanceStats");
   }
}

//+------------------------------------------------------------------+
//| Start engine                                                     |
//+------------------------------------------------------------------+
bool CEngine::Start()
{
   if(!m_initialized)
   {
      LogError("Cannot start engine - not initialized", "Start");
      return false;
   }
   
   m_running = true;
   m_error_state = false;
   
   LogInfo("Engine started", "Start");
   return true;
}

//+------------------------------------------------------------------+
//| Stop engine                                                      |
//+------------------------------------------------------------------+
bool CEngine::Stop()
{
   m_running = false;
   LogInfo("Engine stopped", "Stop");
   return true;
}

//+------------------------------------------------------------------+
//| Pause engine                                                     |
//+------------------------------------------------------------------+
bool CEngine::Pause()
{
   m_running = false;
   LogInfo("Engine paused", "Pause");
   return true;
}

//+------------------------------------------------------------------+
//| Resume engine                                                    |
//+------------------------------------------------------------------+
bool CEngine::Resume()
{
   if(!m_initialized)
      return false;
   
   m_running = true;
   m_error_state = false;
   
   LogInfo("Engine resumed", "Resume");
   return true;
}

//+------------------------------------------------------------------+
//| Restart engine                                                   |
//+------------------------------------------------------------------+
bool CEngine::Restart()
{
   LogInfo("Restarting engine...", "Restart");
   
   Stop();
   DeinitializeComponents();
   
   bool result = InitializeComponents();
   if(result)
   {
      Start();
      LogInfo("Engine restarted successfully", "Restart");
   }
   else
   {
      LogError("Failed to restart engine", "Restart");
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| Update settings                                                  |
//+------------------------------------------------------------------+
bool CEngine::UpdateSettings()
{
   LogInfo("Updating engine settings...", "UpdateSettings");
   
   // This would reload settings and reinitialize components if needed
   // For now, just log the action
   
   LogInfo("Settings updated", "UpdateSettings");
   return true;
}

//+------------------------------------------------------------------+
//| Set update interval                                              |
//+------------------------------------------------------------------+
void CEngine::SetUpdateInterval(uint interval_ms)
{
   m_update_interval_ms = MathMax(1000, interval_ms); // Minimum 1 second
   LogInfo(StringFormat("Update interval set to %d ms", m_update_interval_ms), "SetUpdateInterval");
}

//+------------------------------------------------------------------+
//| Set signal check interval                                       |
//+------------------------------------------------------------------+
void CEngine::SetSignalCheckInterval(uint interval_ms)
{
   m_signal_check_interval_ms = MathMax(1000, interval_ms); // Minimum 1 second
   LogInfo(StringFormat("Signal check interval set to %d ms", m_signal_check_interval_ms), "SetSignalCheckInterval");
}

//+------------------------------------------------------------------+
//| Get statistics                                                   |
//+------------------------------------------------------------------+
string CEngine::GetStatistics()
{
   string stats = "Engine Statistics:\n";
   stats += StringFormat("- Ticks processed: %d\n", m_tick_count);
   stats += StringFormat("- Average tick time: %d ms\n", m_avg_tick_time_ms);
   stats += StringFormat("- Maximum tick time: %d ms\n", m_max_tick_time_ms);
   stats += StringFormat("- Positions: %d\n", m_trade_manager.GetPositionsCount());
   stats += StringFormat("- Total profit: %.2f\n", m_trade_manager.GetTotalProfit());
   stats += StringFormat("- Market status: %s\n", m_market_status.status_text);
   
   return stats;
}

//+------------------------------------------------------------------+
//| Get performance info                                             |
//+------------------------------------------------------------------+
string CEngine::GetPerformanceInfo()
{
   return StringFormat("Performance: Ticks=%d, Avg=%dms, Max=%dms, Status=%s",
                      m_tick_count, 
                      m_avg_tick_time_ms, 
                      m_max_tick_time_ms,
                      m_running ? "RUNNING" : "STOPPED");
}

//+------------------------------------------------------------------+
//| Show dashboard                                                   |
//+------------------------------------------------------------------+
void CEngine::ShowDashboard()
{
   m_dashboard.Show();
   LogInfo("Dashboard shown", "ShowDashboard");
}

//+------------------------------------------------------------------+
//| Hide dashboard                                                   |
//+------------------------------------------------------------------+
void CEngine::HideDashboard()
{
   m_dashboard.Hide();
   LogInfo("Dashboard hidden", "HideDashboard");
}

//+------------------------------------------------------------------+
//| Toggle dashboard                                                 |
//+------------------------------------------------------------------+
void CEngine::ToggleDashboard()
{
   m_dashboard.Toggle();
   LogInfo(StringFormat("Dashboard %s", m_dashboard.IsVisible() ? "shown" : "hidden"), "ToggleDashboard");
}

//+------------------------------------------------------------------+
//| Force signal check                                               |
//+------------------------------------------------------------------+
void CEngine::ForceSignalCheck()
{
   LogInfo("Forcing signal check...", "ForceSignalCheck");
   ProcessSignals();
   m_last_signal_check_time = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Force position update                                            |
//+------------------------------------------------------------------+
void CEngine::ForcePositionUpdate()
{
   LogInfo("Forcing position update...", "ForcePositionUpdate");
   UpdatePositionData();
}

//+------------------------------------------------------------------+
//| Force dashboard refresh                                          |
//+------------------------------------------------------------------+
void CEngine::ForceDashboardRefresh()
{
   LogInfo("Forcing dashboard refresh...", "ForceDashboardRefresh");
   UpdateDashboard();
   m_last_update_time = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CEngine::CloseAllPositions(const string reason = "Manual close")
{
   LogInfo(StringFormat("Closing all positions: %s", reason), "CloseAllPositions");
   m_trade_manager.CloseAllPositions(reason);
}

//+------------------------------------------------------------------+
//| Print engine status                                              |
//+------------------------------------------------------------------+
void CEngine::PrintEngineStatus()
{
   g_Logger.Info("=== SuppResist Engine Status ===");
   g_Logger.Info(GetEngineStatus());
   g_Logger.Info(GetPerformanceInfo());
   g_Logger.Info(StringFormat("Market Status: %s", m_market_status.status_text));
   g_Logger.Info(StringFormat("Symbols: %d/%d", m_market_status.symbols_processed, m_market_status.symbols_total));
   g_Logger.Info("================================");
}

//+------------------------------------------------------------------+
//| Print performance report                                         |
//+------------------------------------------------------------------+
void CEngine::PrintPerformanceReport()
{
   g_Logger.Info("=== Performance Report ===");
   g_Logger.Info(StringFormat("Total Ticks: %d", m_tick_count));
   g_Logger.Info(StringFormat("Average Time: %d ms", m_avg_tick_time_ms));
   g_Logger.Info(StringFormat("Maximum Time: %d ms", m_max_tick_time_ms));
   g_Logger.Info(StringFormat("Update Interval: %d ms", m_update_interval_ms));
   g_Logger.Info(StringFormat("Signal Check Interval: %d ms", m_signal_check_interval_ms));
   g_Logger.Info("==========================");
}

//+------------------------------------------------------------------+
//| Enable debug mode                                                |
//+------------------------------------------------------------------+
void CEngine::EnableDebugMode(bool enable)
{
   g_Logger.SetDebugMode(enable);
   LogInfo(StringFormat("Debug mode %s", enable ? "enabled" : "disabled"), "EnableDebugMode");
}

//+------------------------------------------------------------------+
