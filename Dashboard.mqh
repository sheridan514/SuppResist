//+------------------------------------------------------------------+
//| Dashboard.mqh                                                    |
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
//| CDashboard Class                                                 |
//+------------------------------------------------------------------+
class CDashboard
{
private:
   SSettings         m_settings;                    // Dashboard settings
   bool              m_initialized;                 // Initialization flag
   bool              m_visible;                     // Panel visibility
   
   // Panel layout
   int               m_panel_height;                // Calculated panel height
   int               m_rows_count;                  // Number of symbol rows
   
   // Object tracking
   string            m_created_objects[];           // Created object names
   int               m_objects_count;               // Number of created objects
   
   // Internal methods
   void CalculatePanelDimensions();
   bool CreatePanelBackground();
   bool CreateStatusRow();
   bool CreatePanelHeader();
   bool CreateSymbolRows();
   
   // Object management
   bool CreateTextObject(const string name, const string text, int x, int y, 
                         color text_color = clrBlack, int font_size = 9, 
                         const string font = "Arial");
   bool CreateRectangleObject(const string name, int x1, int y1, int x2, int y2, 
                              color bg_color = clrWhite, color border_color = clrBlack);
   bool CreateScoreBar(const string name, int x, int y, int width, int height, 
                       double score, color bar_color);
   
   void AddObjectToTracking(const string name);
   void RemoveAllObjects();
   
   // Drawing methods
   void DrawSymbolRow(int row_index, const string symbol);
   void UpdateSymbolRow(int row_index, SSignalInfo &signal_info);
   void UpdateStatusRow(SMarketStatusInfo &status_info);
   
   // Support/Resistance methods
   bool DrawSupportResistance(const string symbol, double support, double resistance);
   void CalculateSR(const string symbol, ENUM_TIMEFRAMES tf, int lookback_bars, double& support, double& resistance);
   
   // AI methods
   int CalculateAIStrength(const string symbol);
   
   // Layout helpers
   int GetRowY(int row_index);
   string GetObjectName(const string base_name, int row_index = -1, const string suffix = "");
   
   // Color helpers
   color GetScoreColor(double score);
   color GetStatusColor(ENUM_MARKET_STATUS status);
   
public:
   // Constructor/Destructor
   CDashboard();
   ~CDashboard();
   
   // Initialization
   bool Initialize(SSettings &settings, string &symbols[]);
   void Deinitialize();
   
   // Main interface
   bool Update(SSettings &settings, SSignalInfo &signal_info[], 
               SMarketStatusInfo &status_info);
   
   // Panel management
   void Show();
   void Hide();
   void Toggle();
   bool IsVisible() const { return m_visible; }
   
   // Update methods
   void UpdateAllRows(SSignalInfo &signal_info[]);
   void UpdateSingleRow(int row_index, SSignalInfo &signal_info);
   void ForceRedraw();
   
   // Layout methods
   void UpdatePanelSize(int width, int height);
   void MovePanelTo(int x, int y);
   
   // Debug methods
   void PrintObjectsList();
   string GetDebugInfo();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CDashboard::CDashboard() : m_initialized(false), 
                           m_visible(true),
                           m_panel_height(0),
                           m_rows_count(0),
                           m_objects_count(0)
{
   ZeroMemory(m_settings);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CDashboard::~CDashboard()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize dashboard                                             |
//+------------------------------------------------------------------+
bool CDashboard::Initialize(SSettings &settings, string &symbols[])
{
   if(m_initialized)
      return true;
   
   m_settings = settings;
   m_rows_count = ArraySize(symbols);
   
   if(m_rows_count <= 0)
   {
      LogError("No symbols provided for dashboard", "CDashboard::Initialize");
      return false;
   }
   
   // Calculate panel dimensions
   CalculatePanelDimensions();
   
   // Remove any existing objects
   RemoveAllObjects();
   
   // Create panel components
   if(!CreatePanelBackground())
   {
      LogError("Failed to create panel background", "CDashboard::Initialize");
      return false;
   }
   
   if(!CreateStatusRow())
   {
      LogError("Failed to create status row", "CDashboard::Initialize");
      return false;
   }
   
   if(!CreatePanelHeader())
   {
      LogError("Failed to create panel header", "CDashboard::Initialize");
      return false;
   }
   
   if(!CreateSymbolRows())
   {
      LogError("Failed to create symbol rows", "CDashboard::Initialize");
      return false;
   }
   
   m_initialized = true;
   m_visible = true;
   
   LogInfo(StringFormat("Dashboard initialized for %d symbols", m_rows_count), "CDashboard::Initialize");
   
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize dashboard                                           |
//+------------------------------------------------------------------+
void CDashboard::Deinitialize()
{
   if(!m_initialized)
      return;
   
   RemoveAllObjects();
   
   ArrayFree(m_created_objects);
   m_objects_count = 0;
   m_initialized = false;
   
   LogInfo("Dashboard deinitialized", "CDashboard::Deinitialize");
}

//+------------------------------------------------------------------+
//| Calculate panel dimensions                                       |
//+------------------------------------------------------------------+
void CDashboard::CalculatePanelDimensions()
{
   // Calculate total height: status row + header + symbol rows + margins
   m_panel_height = m_settings.panel_row_height * (2 + m_rows_count) + (PANEL_MARGIN * 2);
   
   LogDebug(StringFormat("Panel dimensions: %dx%d (%d rows)", 
                         m_settings.panel_width, m_panel_height, m_rows_count), "CalculatePanelDimensions");
}

//+------------------------------------------------------------------+
//| Create panel background                                          |
//+------------------------------------------------------------------+
bool CDashboard::CreatePanelBackground()
{
   string bg_name = GetObjectName("Background");
   
   return CreateRectangleObject(bg_name, 
                                m_settings.panel_x_pos,
                                m_settings.panel_y_pos,
                                m_settings.panel_x_pos + m_settings.panel_width,
                                m_settings.panel_y_pos + m_panel_height,
                                m_settings.panel_bg_color,
                                clrBlack);
}

//+------------------------------------------------------------------+
//| Create status row                                                |
//+------------------------------------------------------------------+
bool CDashboard::CreateStatusRow()
{
   int status_y = m_settings.panel_y_pos + PANEL_MARGIN;
   
   string status_name = GetObjectName("Status");
   
   return CreateTextObject(status_name, 
                           "Načítání stavu trhu...",
                           m_settings.panel_x_pos + PANEL_MARGIN,
                           status_y,
                           m_settings.panel_text_color,
                           m_settings.panel_font_size,
                           m_settings.panel_font_name);
}

//+------------------------------------------------------------------+
//| Create panel header                                              |
//+------------------------------------------------------------------+
bool CDashboard::CreatePanelHeader()
{
   int header_y = m_settings.panel_y_pos + PANEL_MARGIN + m_settings.panel_row_height;
   
   // Create header labels
   struct SHeaderColumn
   {
      string text;
      int x_pos;
   };
   
   SHeaderColumn headers[];
   ArrayResize(headers, 9);
   
   headers[0].text = "Symbol";     headers[0].x_pos = COL_SYMBOL_X;
   headers[1].text = "Score";      headers[1].x_pos = COL_SCORE_X;
   headers[2].text = "RSI";        headers[2].x_pos = COL_RSI_X;
   headers[3].text = "BB";         headers[3].x_pos = COL_BB_X;
   headers[4].text = "Stoch";      headers[4].x_pos = COL_STOCH_X;
   
   if(m_settings.show_support_resistance)
   {
      headers[5].text = "S/R";     headers[5].x_pos = COL_SR_X;
   }
   else
   {
      headers[5].text = "";        headers[5].x_pos = COL_SR_X;
   }
   
   if(m_settings.use_ai_estimation)
   {
      headers[6].text = "AI";      headers[6].x_pos = COL_AI_X;
   }
   else
   {
      headers[6].text = "";        headers[6].x_pos = COL_AI_X;
   }
   
   headers[7].text = "Signal";     headers[7].x_pos = COL_FINAL_X;
   headers[8].text = "Grid";       headers[8].x_pos = COL_GRID_X;
   
   bool success = true;
   
   for(int i = 0; i < ArraySize(headers); i++)
   {
      if(headers[i].text == "") continue;
      
      string header_name = GetObjectName("Header", i);
      
      if(!CreateTextObject(header_name,
                           headers[i].text,
                           m_settings.panel_x_pos + headers[i].x_pos,
                           header_y,
                           m_settings.panel_text_color,
                           m_settings.panel_font_size,
                           m_settings.panel_font_name))
      {
         success = false;
      }
   }
   
   return success;
}

//+------------------------------------------------------------------+
//| Create symbol rows                                               |
//+------------------------------------------------------------------+
bool CDashboard::CreateSymbolRows()
{
   for(int i = 0; i < m_rows_count; i++)
   {
      DrawSymbolRow(i, "");
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Draw symbol row                                                  |
//+------------------------------------------------------------------+
void CDashboard::DrawSymbolRow(int row_index, const string symbol)
{
   int row_y = GetRowY(row_index);
   
   // Symbol name
   string symbol_name = GetObjectName("Symbol", row_index);
   CreateTextObject(symbol_name, symbol,
                    m_settings.panel_x_pos + COL_SYMBOL_X, row_y,
                    m_settings.panel_text_color);
   
   // Score bar background
   string score_bg_name = GetObjectName("ScoreBG", row_index);
   CreateRectangleObject(score_bg_name,
                         m_settings.panel_x_pos + COL_SCORE_X, row_y - 2,
                         m_settings.panel_x_pos + COL_SCORE_X + 80, row_y + m_settings.panel_row_height - 8,
                         clrWhite, clrGray);
   
   // Score bar
   string score_bar_name = GetObjectName("ScoreBar", row_index);
   CreateScoreBar(score_bar_name,
                  m_settings.panel_x_pos + COL_SCORE_X + 1, row_y - 1,
                  78, m_settings.panel_row_height - 10,
                  0.0, clrGray);
   
   // Score text
   string score_text_name = GetObjectName("ScoreText", row_index);
   CreateTextObject(score_text_name, "0%",
                    m_settings.panel_x_pos + COL_SCORE_X + 85, row_y,
                    m_settings.panel_text_color);
   
   // RSI signal
   string rsi_name = GetObjectName("RSI", row_index);
   CreateTextObject(rsi_name, "—",
                    m_settings.panel_x_pos + COL_RSI_X, row_y,
                    m_settings.neutral_color);
   
   // Bollinger Bands signal
   string bb_name = GetObjectName("BB", row_index);
   CreateTextObject(bb_name, "—",
                    m_settings.panel_x_pos + COL_BB_X, row_y,
                    m_settings.neutral_color);
   
   // Stochastic signal
   string stoch_name = GetObjectName("Stoch", row_index);
   CreateTextObject(stoch_name, "—",
                    m_settings.panel_x_pos + COL_STOCH_X, row_y,
                    m_settings.neutral_color);
   
   // Support/Resistance (if enabled)
   if(m_settings.show_support_resistance)
   {
      string sr_name = GetObjectName("SR", row_index);
      CreateTextObject(sr_name, "—",
                       m_settings.panel_x_pos + COL_SR_X, row_y,
                       m_settings.panel_text_color);
   }
   
   // AI strength (if enabled)
   if(m_settings.use_ai_estimation)
   {
      string ai_name = GetObjectName("AI", row_index);
      CreateTextObject(ai_name, "—",
                       m_settings.panel_x_pos + COL_AI_X, row_y,
                       m_settings.panel_text_color);
   }
   
   // Final signal
   string final_name = GetObjectName("Final", row_index);
   CreateTextObject(final_name, "—",
                    m_settings.panel_x_pos + COL_FINAL_X, row_y,
                    m_settings.neutral_color);
   
   // Grid status
   string grid_name = GetObjectName("Grid", row_index);
   CreateTextObject(grid_name, "None",
                    m_settings.panel_x_pos + COL_GRID_X, row_y,
                    m_settings.panel_text_color);
}

//+------------------------------------------------------------------+
//| Update symbol row with signal info                              |
//+------------------------------------------------------------------+
void CDashboard::UpdateSymbolRow(int row_index, SSignalInfo &signal_info)
{
   int row_y = GetRowY(row_index);
   
   // Update symbol name
   string symbol_name = GetObjectName("Symbol", row_index);
   ObjectSetString(0, symbol_name, OBJPROP_TEXT, signal_info.symbol);
   
   // Update score bar
   string score_bar_name = GetObjectName("ScoreBar", row_index);
   color score_color = GetScoreColor(signal_info.score);
   
   // Calculate bar width based on score
   int bar_width = (int)(78.0 * signal_info.score / 100.0);
   
   // Recreate score bar with new width and color
   ObjectDelete(0, score_bar_name);
   CreateScoreBar(score_bar_name,
                  m_settings.panel_x_pos + COL_SCORE_X + 1, row_y - 1,
                  bar_width, m_settings.panel_row_height - 10,
                  signal_info.score, score_color);
   
   // Update score text
   string score_text_name = GetObjectName("ScoreText", row_index);
   ObjectSetString(0, score_text_name, OBJPROP_TEXT, 
                   StringFormat("%.0f%%", signal_info.score));
   
   // Update RSI signal
   string rsi_name = GetObjectName("RSI", row_index);
   ObjectSetString(0, rsi_name, OBJPROP_TEXT, GetSignalText(signal_info.rsi_signal));
   ObjectSetInteger(0, rsi_name, OBJPROP_COLOR, GetSignalColor(signal_info.rsi_signal));
   
   // Update BB signal
   string bb_name = GetObjectName("BB", row_index);
   ObjectSetString(0, bb_name, OBJPROP_TEXT, GetSignalText(signal_info.bb_signal));
   ObjectSetInteger(0, bb_name, OBJPROP_COLOR, GetSignalColor(signal_info.bb_signal));
   
   // Update Stochastic signal
   string stoch_name = GetObjectName("Stoch", row_index);
   ObjectSetString(0, stoch_name, OBJPROP_TEXT, GetSignalText(signal_info.stoch_signal));
   ObjectSetInteger(0, stoch_name, OBJPROP_COLOR, GetSignalColor(signal_info.stoch_signal));
   
   // Update Support/Resistance (if enabled)
   if(m_settings.show_support_resistance)
   {
      string sr_name = GetObjectName("SR", row_index);
      if(signal_info.support_level > 0 && signal_info.resistance_level > 0)
      {
         string sr_text = StringFormat("S:%.5f R:%.5f", 
                                      signal_info.support_level, 
                                      signal_info.resistance_level);
         ObjectSetString(0, sr_name, OBJPROP_TEXT, sr_text);
      }
      else
      {
         ObjectSetString(0, sr_name, OBJPROP_TEXT, "—");
      }
   }
   
   // Update AI strength (if enabled)
   if(m_settings.use_ai_estimation)
   {
      string ai_name = GetObjectName("AI", row_index);
      if(signal_info.ai_strength != 0)
      {
         ObjectSetString(0, ai_name, OBJPROP_TEXT, IntegerToString(signal_info.ai_strength));
         ObjectSetInteger(0, ai_name, OBJPROP_COLOR, 
                          (signal_info.ai_strength > 0) ? clrGreen : clrRed);
      }
      else
      {
         ObjectSetString(0, ai_name, OBJPROP_TEXT, "—");
         ObjectSetInteger(0, ai_name, OBJPROP_COLOR, m_settings.neutral_color);
      }
   }
   
   // Update final signal
   string final_name = GetObjectName("Final", row_index);
   ObjectSetString(0, final_name, OBJPROP_TEXT, GetSignalText(signal_info.final_signal));
   ObjectSetInteger(0, final_name, OBJPROP_COLOR, GetSignalColor(signal_info.final_signal));
   
   // Update grid status
   string grid_name = GetObjectName("Grid", row_index);
   ObjectSetString(0, grid_name, OBJPROP_TEXT, GetGridStatusText(signal_info.grid_status));
   
   color grid_color = m_settings.panel_text_color;
   if(signal_info.grid_status == GRID_ACTIVE)
      grid_color = clrGreen;
   else if(signal_info.grid_status == GRID_RECOVERY)
      grid_color = clrOrange;
   
   ObjectSetInteger(0, grid_name, OBJPROP_COLOR, grid_color);
}

//+------------------------------------------------------------------+
//| Update status row                                                |
//+------------------------------------------------------------------+
void CDashboard::UpdateStatusRow(SMarketStatusInfo &status_info)
{
   string status_name = GetObjectName("Status");
   
   string status_text = StringFormat("%s (%d/%d)", 
                                    status_info.status_text,
                                    status_info.symbols_processed,
                                    status_info.symbols_total);
   
   ObjectSetString(0, status_name, OBJPROP_TEXT, status_text);
   ObjectSetInteger(0, status_name, OBJPROP_COLOR, status_info.status_color);
}

//+------------------------------------------------------------------+
//| Update dashboard with new data                                  |
//+------------------------------------------------------------------+
bool CDashboard::Update(SSettings &settings, SSignalInfo &signal_info[], 
                        SMarketStatusInfo &status_info)
{
   if(!m_initialized || !m_visible)
      return true;
   
   // Update status row
   UpdateStatusRow(status_info);
   
   // Update symbol rows
   int signals_count = ArraySize(signal_info);
   int rows_to_update = MathMin(m_rows_count, signals_count);
   
   for(int i = 0; i < rows_to_update; i++)
   {
      UpdateSymbolRow(i, signal_info[i]);
   }
   
   // Redraw chart to show updates
   ChartRedraw();
   
   return true;
}

//+------------------------------------------------------------------+
//| Create text object                                               |
//+------------------------------------------------------------------+
bool CDashboard::CreateTextObject(const string name, const string text, int x, int y,
                                  color text_color = clrBlack, int font_size = 9,
                                  const string font = "Arial")
{
   if(ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
   {
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetString(0, name, OBJPROP_FONT, font);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size);
      ObjectSetInteger(0, name, OBJPROP_COLOR, text_color);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      
      AddObjectToTracking(name);
      return true;
   }
   
   LogError(StringFormat("Failed to create text object: %s", name), "CreateTextObject");
   return false;
}

//+------------------------------------------------------------------+
//| Create rectangle object                                          |
//+------------------------------------------------------------------+
bool CDashboard::CreateRectangleObject(const string name, int x1, int y1, int x2, int y2,
                                       color bg_color = clrWhite, color border_color = clrBlack)
{
   if(ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
   {
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x1);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y1);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, x2 - x1);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, y2 - y1);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg_color);
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, border_color);
      ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      
      AddObjectToTracking(name);
      return true;
   }
   
   LogError(StringFormat("Failed to create rectangle object: %s", name), "CreateRectangleObject");
   return false;
}

//+------------------------------------------------------------------+
//| Create score bar                                                 |
//+------------------------------------------------------------------+
bool CDashboard::CreateScoreBar(const string name, int x, int y, int width, int height,
                                double score, color bar_color)
{
   if(width <= 0) return true; // Skip empty bars
   
   if(ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
   {
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bar_color);
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, bar_color);
      ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 0);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      
      AddObjectToTracking(name);
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Add object to tracking array                                    |
//+------------------------------------------------------------------+
void CDashboard::AddObjectToTracking(const string name)
{
   // Resize array if needed
   if(m_objects_count >= ArraySize(m_created_objects))
   {
      ArrayResize(m_created_objects, ArraySize(m_created_objects) + 100);
   }
   
   m_created_objects[m_objects_count] = name;
   m_objects_count++;
}

//+------------------------------------------------------------------+
//| Remove all objects                                               |
//+------------------------------------------------------------------+
void CDashboard::RemoveAllObjects()
{
   for(int i = 0; i < m_objects_count; i++)
   {
      ObjectDelete(0, m_created_objects[i]);
   }
   
   // Also remove any objects with our prefix that might exist
   int total_objects = ObjectsTotal(0);
   for(int i = total_objects - 1; i >= 0; i--)
   {
      string obj_name = ObjectName(0, i);
      if(StringFind(obj_name, PANEL_OBJECT_PREFIX) == 0)
      {
         ObjectDelete(0, obj_name);
      }
   }
   
   m_objects_count = 0;
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Get row Y coordinate                                             |
//+------------------------------------------------------------------+
int CDashboard::GetRowY(int row_index)
{
   return m_settings.panel_y_pos + PANEL_MARGIN + 
          (2 + row_index) * m_settings.panel_row_height; // Status + header + rows
}

//+------------------------------------------------------------------+
//| Generate object name                                             |
//+------------------------------------------------------------------+
string CDashboard::GetObjectName(const string base_name, int row_index = -1, const string suffix = "")
{
   string name = PANEL_OBJECT_PREFIX + base_name;
   
   if(row_index >= 0)
      name += "_" + IntegerToString(row_index);
   
   if(suffix != "")
      name += "_" + suffix;
   
   return name;
}

//+------------------------------------------------------------------+
//| Get color for score value                                        |
//+------------------------------------------------------------------+
color CDashboard::GetScoreColor(double score)
{
   if(score >= 80.0)
      return clrRed;          // High score - strong signal
   else if(score >= 60.0)
      return clrOrange;       // Medium-high score
   else if(score >= 40.0)
      return clrYellow;       // Medium score
   else if(score >= 20.0)
      return clrLightBlue;    // Low-medium score
   else
      return clrGray;         // Low score
}

//+------------------------------------------------------------------+
//| Get color for market status                                      |
//+------------------------------------------------------------------+
color CDashboard::GetStatusColor(ENUM_MARKET_STATUS status)
{
   switch(status)
   {
      case MARKET_LOADING:       return clrBlue;
      case MARKET_CONSOLIDATION: return clrGreen;
      case MARKET_TRENDING:      return clrOrange;
      case MARKET_ERROR:         return clrRed;
      default:                   return clrGray;
   }
}

//+------------------------------------------------------------------+
//| Calculate support and resistance levels                         |
//+------------------------------------------------------------------+
void CDashboard::CalculateSR(const string symbol, ENUM_TIMEFRAMES tf, int lookback_bars, 
                             double& support, double& resistance)
{
   support = 0.0;
   resistance = 0.0;
   
   // Get price data
   double high[], low[], close[];
   
   if(CopyHigh(symbol, tf, 0, lookback_bars, high) <= 0 ||
      CopyLow(symbol, tf, 0, lookback_bars, low) <= 0 ||
      CopyClose(symbol, tf, 0, lookback_bars, close) <= 0)
   {
      return;
   }
   
   double current_price = close[0];
   double min_distance = (current_price * 0.001); // 0.1% minimum distance
   
   // Find support (highest low below current price)
   for(int i = 1; i < lookback_bars; i++)
   {
      if(low[i] < current_price && low[i] > support)
      {
         // Check if this level has been tested multiple times
         int touch_count = 0;
         for(int j = MathMax(0, i-10); j < MathMin(lookback_bars, i+10); j++)
         {
            if(MathAbs(low[j] - low[i]) < min_distance)
               touch_count++;
         }
         
         if(touch_count >= 2) // Level tested at least twice
            support = low[i];
      }
   }
   
   // Find resistance (lowest high above current price)
   resistance = 999999.0;
   for(int i = 1; i < lookback_bars; i++)
   {
      if(high[i] > current_price && high[i] < resistance)
      {
         // Check if this level has been tested multiple times
         int touch_count = 0;
         for(int j = MathMax(0, i-10); j < MathMin(lookback_bars, i+10); j++)
         {
            if(MathAbs(high[j] - high[i]) < min_distance)
               touch_count++;
         }
         
         if(touch_count >= 2) // Level tested at least twice
            resistance = high[i];
      }
   }
   
   if(resistance >= 999999.0)
      resistance = 0.0;
}

//+------------------------------------------------------------------+
//| Draw support and resistance lines                               |
//+------------------------------------------------------------------+
bool CDashboard::DrawSupportResistance(const string symbol, double support, double resistance)
{
   if(support <= 0.0 && resistance <= 0.0)
      return false;
   
   // Draw support line
   if(support > 0.0)
   {
      string support_name = SR_LINE_PREFIX + symbol + "_Support";
      
      if(ObjectCreate(0, support_name, OBJ_HLINE, 0, 0, support))
      {
         ObjectSetInteger(0, support_name, OBJPROP_COLOR, clrBlue);
         ObjectSetInteger(0, support_name, OBJPROP_STYLE, STYLE_DOT);
         ObjectSetInteger(0, support_name, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, support_name, OBJPROP_BACK, true);
         ObjectSetInteger(0, support_name, OBJPROP_SELECTABLE, false);
         ObjectSetString(0, support_name, OBJPROP_TEXT, "Support: " + DoubleToString(support, 5));
         
         AddObjectToTracking(support_name);
      }
   }
   
   // Draw resistance line
   if(resistance > 0.0)
   {
      string resistance_name = SR_LINE_PREFIX + symbol + "_Resistance";
      
      if(ObjectCreate(0, resistance_name, OBJ_HLINE, 0, 0, resistance))
      {
         ObjectSetInteger(0, resistance_name, OBJPROP_COLOR, clrRed);
         ObjectSetInteger(0, resistance_name, OBJPROP_STYLE, STYLE_DOT);
         ObjectSetInteger(0, resistance_name, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, resistance_name, OBJPROP_BACK, true);
         ObjectSetInteger(0, resistance_name, OBJPROP_SELECTABLE, false);
         ObjectSetString(0, resistance_name, OBJPROP_TEXT, "Resistance: " + DoubleToString(resistance, 5));
         
         AddObjectToTracking(resistance_name);
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Calculate AI strength (placeholder for future implementation)   |
//+------------------------------------------------------------------+
int CDashboard::CalculateAIStrength(const string symbol)
{
   // This is a placeholder for AI integration
   // In real implementation, this would call an external API
   // or use a trained model to estimate trend strength
   
   // For now, return a random value between -100 and +100
   // to demonstrate the functionality
   
   if(!m_settings.use_ai_estimation)
      return 0;
   
   // Simple mock implementation based on symbol hash
   int hash = 0;
   for(int i = 0; i < StringLen(symbol); i++)
   {
      hash += StringGetCharacter(symbol, i);
   }
   
   // Generate pseudo-random value based on hash and current time
   int seed = hash + (int)(TimeCurrent() % 1000);
   MathSrand(seed);
   
   return (MathRand() % 201) - 100; // -100 to +100
}

//+------------------------------------------------------------------+
//| Show panel                                                       |
//+------------------------------------------------------------------+
void CDashboard::Show()
{
   if(!m_initialized) return;
   
   for(int i = 0; i < m_objects_count; i++)
   {
      ObjectSetInteger(0, m_created_objects[i], OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   }
   
   m_visible = true;
   ChartRedraw();
   
   LogDebug("Dashboard shown", "Show");
}

//+------------------------------------------------------------------+
//| Hide panel                                                       |
//+------------------------------------------------------------------+
void CDashboard::Hide()
{
   if(!m_initialized) return;
   
   for(int i = 0; i < m_objects_count; i++)
   {
      ObjectSetInteger(0, m_created_objects[i], OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
   }
   
   m_visible = false;
   ChartRedraw();
   
   LogDebug("Dashboard hidden", "Hide");
}

//+------------------------------------------------------------------+
//| Toggle panel visibility                                          |
//+------------------------------------------------------------------+
void CDashboard::Toggle()
{
   if(m_visible)
      Hide();
   else
      Show();
}

//+------------------------------------------------------------------+
//| Update all rows                                                  |
//+------------------------------------------------------------------+
void CDashboard::UpdateAllRows(SSignalInfo &signal_info[])
{
   int signals_count = ArraySize(signal_info);
   int rows_to_update = MathMin(m_rows_count, signals_count);
   
   for(int i = 0; i < rows_to_update; i++)
   {
      UpdateSymbolRow(i, signal_info[i]);
   }
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Update single row                                                |
//+------------------------------------------------------------------+
void CDashboard::UpdateSingleRow(int row_index, SSignalInfo &signal_info)
{
   if(row_index >= 0 && row_index < m_rows_count)
   {
      UpdateSymbolRow(row_index, signal_info);
      ChartRedraw();
   }
}

//+------------------------------------------------------------------+
//| Force redraw                                                     |
//+------------------------------------------------------------------+
void CDashboard::ForceRedraw()
{
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Update panel size                                                |
//+------------------------------------------------------------------+
void CDashboard::UpdatePanelSize(int width, int height)
{
   m_settings.panel_width = width;
   // Height is calculated based on row count
   
   // Update background object
   string bg_name = GetObjectName("Background");
   ObjectSetInteger(0, bg_name, OBJPROP_XSIZE, width);
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Move panel to new position                                       |
//+------------------------------------------------------------------+
void CDashboard::MovePanelTo(int x, int y)
{
   int delta_x = x - m_settings.panel_x_pos;
   int delta_y = y - m_settings.panel_y_pos;
   
   m_settings.panel_x_pos = x;
   m_settings.panel_y_pos = y;
   
   // Move all objects
   for(int i = 0; i < m_objects_count; i++)
   {
      string obj_name = m_created_objects[i];
      int obj_x = (int)ObjectGetInteger(0, obj_name, OBJPROP_XDISTANCE);
      int obj_y = (int)ObjectGetInteger(0, obj_name, OBJPROP_YDISTANCE);
      
      ObjectSetInteger(0, obj_name, OBJPROP_XDISTANCE, obj_x + delta_x);
      ObjectSetInteger(0, obj_name, OBJPROP_YDISTANCE, obj_y + delta_y);
   }
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Print objects list for debugging                                |
//+------------------------------------------------------------------+
void CDashboard::PrintObjectsList()
{
   g_Logger.Info(StringFormat("=== Dashboard Objects (%d) ===", m_objects_count));
   
   for(int i = 0; i < m_objects_count; i++)
   {
      g_Logger.Info(StringFormat("%d: %s", i + 1, m_created_objects[i]));
   }
   
   g_Logger.Info("=============================");
}

//+------------------------------------------------------------------+
//| Get debug information                                            |
//+------------------------------------------------------------------+
string CDashboard::GetDebugInfo()
{
   return StringFormat("Dashboard: %s, Objects: %d, Rows: %d, Size: %dx%d, Pos: %dx%d",
                      m_visible ? "Visible" : "Hidden",
                      m_objects_count,
                      m_rows_count,
                      m_settings.panel_width,
                      m_panel_height,
                      m_settings.panel_x_pos,
                      m_settings.panel_y_pos);
}

//+------------------------------------------------------------------+
