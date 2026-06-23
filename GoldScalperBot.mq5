//+------------------------------------------------------------------+
//| Gold Scalper Bot - MQL5 Expert Advisor                           |
//| 5M/15M Breakout Scalper with Fib Retracements                    |
//| Modes: Scalp, Swing, Trend Follow                                 |
//+------------------------------------------------------------------+
#property copyright "Gold Scalper Bot"
#property link      "https://github.com/bigthreeatone/gold-scalper-bot"
#property version   "1.0"
#property strict
#property description "Aggressive 5M/15M XAUUSD scalper with control panel"

//--- Input Parameters
input group "=== TRADING MODES ==="
enum TRADING_MODE {
   SCALP_MODE = 0,      // 5M Aggressive Scalp (2-5 pips)
   SWING_MODE = 1,      // 15M Breakout (10-20 pips)
   TREND_FOLLOW_MODE = 2 // Larger moves (20+ pips)
};
input TRADING_MODE TradingMode = SCALP_MODE;

input group "=== LOT & RISK ==="
input double LotSize = 0.01;           // Manual lot size
input double RiskPercent = 1.0;        // Risk % per trade (1-2% recommended)
input bool UseAutoSizing = true;       // Auto position sizing based on risk

input group "=== SCALP MODE (5M) ==="
input int ScalpTakeProfit = 5;         // TP in pips (2-5)
input int ScalpStopLoss = 10;          // SL in pips
input double ScalpFibLevel = 0.618;    // Fib retracement level (0.382, 0.618, 0.786)

input group "=== SWING MODE (15M) ==="
input int SwingTakeProfit = 15;        // TP in pips (10-20)
input int SwingStopLoss = 25;          // SL in pips
input double SwingFibLevel = 0.50;     // Fib retracement level

input group "=== TREND MODE ==="
input int TrendTakeProfit = 30;        // TP in pips (20+)
input int TrendStopLoss = 40;          // SL in pips
input int TrendCandles = 20;           // Look back for trend

input group "=== GENERAL ==="
input bool ShowControlPanel = true;    // Display control panel on chart
input int MagicNumber = 123456;        // EA identifier
input bool EnableTrading = true;       // Master on/off switch

//--- Global Variables
double swingHigh, swingLow;
double fibLevel;
int trades_today = 0;
string panel_text = "";
bool mode_changed = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("Gold Scalper Bot Initialized");
   Print("Mode: ", GetModeName(TradingMode));
   Print("Magic Number: ", MagicNumber);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if (!EnableTrading) return;
   
   // Update control panel
   if (ShowControlPanel) {
      UpdateControlPanel();
   }
   
   // Calculate swing highs/lows
   CalculateSwingLevels();
   
   // Calculate Fib levels based on mode
   UpdateFibLevel();
   
   // Check for trading signals
   CheckTradeSignals();
   
   // Manage open positions
   ManagePositions();
}

//+------------------------------------------------------------------+
//| Calculate swing highs and lows                                   |
//+------------------------------------------------------------------+
void CalculateSwingLevels()
{
   int lookback = 10; // Candles to look back for swing
   
   swingHigh = High[iHighest(NULL, 0, MODE_HIGH, lookback, 1)];
   swingLow = Low[iLowest(NULL, 0, MODE_LOW, lookback, 1)];
}

//+------------------------------------------------------------------+
//| Update Fib level based on trading mode                           |
//+------------------------------------------------------------------+
void UpdateFibLevel()
{
   switch(TradingMode) {
      case SCALP_MODE:
         fibLevel = ScalpFibLevel;
         break;
      case SWING_MODE:
         fibLevel = SwingFibLevel;
         break;
      case TREND_FOLLOW_MODE:
         fibLevel = 0.50; // 50% for trend
         break;
   }
}

//+------------------------------------------------------------------+
//| Check for trade signals                                          |
//+------------------------------------------------------------------+
void CheckTradeSignals()
{
   // Get current price
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   
   // Calculate Fib retracement level
   double fibRetracement = swingLow + (swingHigh - swingLow) * fibLevel;
   
   // Check for breakout above swing high
   if (Close[0] > swingHigh && Close[1] <= swingHigh) {
      if (CountOpenTrades() == 0) {
         double tp, sl, lots;
         
         switch(TradingMode) {
            case SCALP_MODE:
               tp = ask + (ScalpTakeProfit * Point());
               sl = bid - (ScalpStopLoss * Point());
               break;
            case SWING_MODE:
               tp = ask + (SwingTakeProfit * Point());
               sl = bid - (SwingStopLoss * Point());
               break;
            case TREND_FOLLOW_MODE:
               tp = ask + (TrendTakeProfit * Point());
               sl = bid - (TrendStopLoss * Point());
               break;
         }
         
         // Calculate lot size
         if (UseAutoSizing) {
            lots = CalculateLotSize(RiskPercent, sl);
         } else {
            lots = LotSize;
         }
         
         // Place BUY order
         int ticket = OrderSend(Symbol(), OP_BUY, lots, ask, 10, sl, tp,
                              "Gold Scalper - Buy", MagicNumber, 0, clrGreen);
         
         if (ticket > 0) {
            Print("BUY Order Opened - Ticket: ", ticket, " Lots: ", lots);
         }
      }
   }
   
   // Check for breakout below swing low
   if (Close[0] < swingLow && Close[1] >= swingLow) {
      if (CountOpenTrades() == 0) {
         double tp, sl, lots;
         
         switch(TradingMode) {
            case SCALP_MODE:
               tp = bid - (ScalpTakeProfit * Point());
               sl = ask + (ScalpStopLoss * Point());
               break;
            case SWING_MODE:
               tp = bid - (SwingTakeProfit * Point());
               sl = ask + (SwingStopLoss * Point());
               break;
            case TREND_FOLLOW_MODE:
               tp = bid - (TrendTakeProfit * Point());
               sl = ask + (TrendStopLoss * Point());
               break;
         }
         
         // Calculate lot size
         if (UseAutoSizing) {
            lots = CalculateLotSize(RiskPercent, sl);
         } else {
            lots = LotSize;
         }
         
         // Place SELL order
         int ticket = OrderSend(Symbol(), OP_SELL, lots, bid, 10, sl, tp,
                              "Gold Scalper - Sell", MagicNumber, 0, clrRed);
         
         if (ticket > 0) {
            Print("SELL Order Opened - Ticket: ", ticket, " Lots: ", lots);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk                                 |
//+------------------------------------------------------------------+
double CalculateLotSize(double risk_percent, double stop_loss_price)
{
   double account_balance = AccountBalance();
   double risk_amount = account_balance * (risk_percent / 100.0);
   double price_range = MathAbs(SymbolInfoDouble(Symbol(), SYMBOL_ASK) - stop_loss_price);
   
   if (price_range == 0) return LotSize;
   
   double lot_size = risk_amount / (price_range / Point());
   
   // Apply min/max lot limits
   double min_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   
   if (lot_size < min_lot) lot_size = min_lot;
   if (lot_size > max_lot) lot_size = max_lot;
   
   return lot_size;
}

//+------------------------------------------------------------------+
//| Count open trades                                                |
//+------------------------------------------------------------------+
int CountOpenTrades()
{
   int count = 0;
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if (OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol()) {
            if (OrderType() == OP_BUY || OrderType() == OP_SELL) {
               count++;
            }
         }
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Manage open positions (close on TP/SL)                           |
//+------------------------------------------------------------------+
void ManagePositions()
{
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if (OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol()) {
            // Positions are managed by TP/SL set at order placement
            // This function can be expanded for trailing stops, etc.
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Get trading mode name                                            |
//+------------------------------------------------------------------+
string GetModeName(TRADING_MODE mode)
{
   switch(mode) {
      case SCALP_MODE:
         return "SCALP MODE (5M - 2-5 pips)";
      case SWING_MODE:
         return "SWING MODE (15M - 10-20 pips)";
      case TREND_FOLLOW_MODE:
         return "TREND FOLLOW MODE (20+ pips)";
      default:
         return "UNKNOWN";
   }
}

//+------------------------------------------------------------------+
//| Update Control Panel on Chart                                    |
//+------------------------------------------------------------------+
void UpdateControlPanel()
{
   string panel_info = "";
   panel_info += "\n========== GOLD SCALPER BOT ==========";
   panel_info += "\nMode: " + GetModeName(TradingMode);
   panel_info += "\nLot Size: " + DoubleToString(LotSize, 3);
   panel_info += "\nRisk: " + DoubleToString(RiskPercent, 1) + "%";
   panel_info += "\nOpen Trades: " + IntegerToString(CountOpenTrades());
   panel_info += "\n";
   panel_info += "\nSwing High: " + DoubleToString(swingHigh, 2);
   panel_info += "\nSwing Low: " + DoubleToString(swingLow, 2);
   panel_info += "\n";
   panel_info += "\nCurrent Price: " + DoubleToString(Close[0], 2);
   panel_info += "\n=====================================";
   
   // Display on chart
   Comment(panel_info);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("Gold Scalper Bot Stopped");
   Comment("");
}

//+------------------------------------------------------------------+
