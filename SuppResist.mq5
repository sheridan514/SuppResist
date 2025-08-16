//+------------------------------------------------------------------+
//| SuppResist.mq5                                                   |
//| Copyright 2024, SuppResist                                       |
//| https://www.mql5.com                                             |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, SuppResist"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "Support/Resistance Dashboard & Filter Expert Advisor"

//+------------------------------------------------------------------+
//| Includes                                                         |
//+------------------------------------------------------------------+
#include "Engine.mqh"

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CEngine g_Engine; // Main engine instance

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize the engine
   int result = g_Engine.OnInit();
   
   if(result != INIT_SUCCEEDED)
   {
      g_Logger.Error("SuppResist: Engine initialization failed!");
      return result;
   }
   
   g_Logger.Info("SuppResist EA initialized successfully");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Deinitialize the engine
   g_Engine.OnDeinit(reason);
   
   g_Logger.Info("SuppResist EA deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Process tick through engine
   g_Engine.OnTick();
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   // Process timer events through engine
   g_Engine.OnTimer();
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   // Handle chart events for dashboard interaction
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      // Dashboard control logic could be implemented here
      // For now, we'll just handle basic panel interactions
      
      if(StringFind(sparam, PANEL_OBJECT_PREFIX) == 0)
      {
         g_Logger.Info(StringFormat("Dashboard object clicked: %s", sparam));
         
         // Example: Toggle dashboard visibility on panel click
         if(StringFind(sparam, "Background") >= 0)
         {
            g_Engine.ToggleDashboard();
         }
      }
   }
   
   // Handle keyboard shortcuts
   if(id == CHARTEVENT_KEYDOWN)
   {
      switch((int)lparam)
      {
         case 68: // 'D' key - Toggle Dashboard
            g_Engine.ToggleDashboard();
            break;
            
         case 83: // 'S' key - Force Signal Check
            g_Engine.ForceSignalCheck();
            break;
            
         case 85: // 'U' key - Force Dashboard Update
            g_Engine.ForceDashboardRefresh();
            break;
            
         case 67: // 'C' key - Close All Positions
            g_Engine.CloseAllPositions("Manual close via hotkey");
            break;
            
         case 80: // 'P' key - Print Engine Status
            g_Engine.PrintEngineStatus();
            break;
      }
   }
}

//+------------------------------------------------------------------+
//| Trade function (for trade events)                               |
//+------------------------------------------------------------------+
void OnTrade()
{
   // Handle trade events
   // The TradeManager will handle position updates automatically
   // This function can be used for additional trade-related logic
   
   static int last_positions_count = 0;
   int current_positions_count = g_Engine.GetTradeManager().GetPositionsCount();
   
   if(current_positions_count != last_positions_count)
   {
      g_Logger.Info(StringFormat("SuppResist: Position count changed from %d to %d", last_positions_count, current_positions_count));
      last_positions_count = current_positions_count;
      
      // Force dashboard update to reflect position changes
      g_Engine.ForceDashboardRefresh();
   }
}

//+------------------------------------------------------------------+
//| BookEvent function (for market depth events)                    |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
{
   // Handle market depth events if needed
   // Currently not used in our implementation
}

//+------------------------------------------------------------------+
