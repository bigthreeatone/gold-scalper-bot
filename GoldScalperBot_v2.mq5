//+------------------------------------------------------------------+
//| Gold Scalper Bot v2.0 - MQL5 Expert Advisor                      |
//| Smart 3-Position Auto-Scaling System                              |
//| Modes: Scalp, Swing, Trend Follow                                 |
//+------------------------------------------------------------------+
#property copyright "Gold Scalper Bot v2.0"
#property link      "https://github.com/bigthreeatone/gold-scalper-bot"
#property version   "2.0"
#property strict
#property description "Auto-scaling 3-position scalper with partial TP and daily loss limit"

//--- Input Parameters
input group "=== TRADING MODES ==="
enum TRADING_MODE {
   SCALP_MODE = 0,      // 5M Aggressive Scalp (2-5 pips)
   SWING_MODE = 1,      // 15M Breakout (10-20 pips)
   TREND_FOLLOW_MODE = 2 // Larger moves (20+ pips)
};
input TRADING_MODE TradingMode = SCALP_MODE;

input group "=== LOT & RISK ==="
input double LotSize = 0.01;           // Base lot size per position
input double RiskPercent = 1.0;        // Risk % per trade (1-2% recommended)
input bool UseAutoSizing = true;       // Auto position sizing based on risk
input double DailyLossLimitPercent = 3.0; // Daily loss limit (3% = $300 on $10K)

input group "=== SCALP MODE (5M) ==="
input int ScalpTakeProfit = 5;         // TP in pips (2-5)
input int ScalpStopLoss = 10;          // SL in pips
input double ScalpFibLevel = 0.618;    // Fib retracement level

input group "=== SWING MODE (15M) ==="
input int SwingTakeProfit = 15;        // TP in pips (10-20)
input int SwingStopLoss = 25;          // SL in pips
input double SwingFibLevel = 0.50;     // Fib retracement level

input group "=== TREND MODE ==="
input int TrendTakeProfit = 30;        // TP in pips (20+)
input int TrendStopLoss = 40;          // SL in pips
input int TrendCandles = 20;           // Look back for trend

input group "=== SCALING & PARTIAL EXITS ==="
input int ScalingDistance = 5;         // Pips between entries (5 pips = Entry 1, 10 pips = Entry 2, 15 = Entry 3)
input int PartialTP1 = 5;              // Close 50% of Position 1 at X pips
input int PartialTP2 = 10;             // Close 50% of Position 2 at X pips
input bool UseTrailingStop = true;     // Trailing stop on Position 3
input int TrailingStopPips = 10;       // Trailing stop distance (pips)

input group "=== GENERAL ==="
input bool ShowControlPanel = true;    // Display control panel on chart
input int MagicNumber = 123456;        // EA identifier
input bool EnableTrading = true;       // Master on/off switch

//--- Global Variables
double swingHigh, swingLow;
double fibLevel;
string panel_text = "";
double dailyOpenBalance = 0;
double dailyLossLimit = 0;
bool dailyLimitHit = false;
datetime lastDayCheck = 0;

// Scaling tracking
struct PositionData {
   int ticket;
   double entryPrice;
   double quantity;
   int positionNumber;  // 1, 2, or 3
   bool partialClosed;
};

PositionData positions[3];
int activePositions = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("====== Gold Scalper Bot v2.0 Initialized ======");
   Print("Mode: ", GetModeName(TradingMode));
   Print("Base Lot Size: ", LotSize);
   Print("Daily Loss Limit: ", DailyLossLimitPercent, "%");
   Print("Scaling Distance: ", ScalingDistance, " pips");
   Print("Magic Number: ", MagicNumber);
   Print("==============================================");
   
   dailyOpenBalance = AccountBalance();
   dailyLossLimit = dailyOpenBalance * (DailyLossLimitPercent / 100.0);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if (!EnableTrading) return;
   
   // Check daily loss limit
   CheckDailyLossLimit();
   
   if (dailyLimitHit) {
      if (ShowControlPanel) UpdateControlPanel();
      return; // Don't trade if daily limit hit
   }
   
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
   
   // Manage open positions (scaling & partial exits)
   ManagePositions();
   
   // Manage trailing stops
   if (UseTrailingStop) {
      ManageTrailingStops();
   }
}

//+------------------------------------------------------------------+
//| Check Daily Loss Limit                                           |
//+------------------------------------------------------------------+
void CheckDailyLossLimit()
{
   datetime currentTime = TimeCurrent();
   datetime startOfDay = currentTime - (currentTime % 86400) + TimeGMTOffset() * 3600;
   
   // Reset daily limit at new day
   if (currentTime - lastDayCheck >= 86400) {
      dailyOpenBalance = AccountBalance();
      dailyLimitHit = false;
      lastDayCheck = currentTime;
      Print("Daily limit reset. Starting balance: ", dailyOpenBalance);
   }
   
   double currentBalance = AccountBalance();
   double dailyLoss = dailyOpenBalance - currentBalance;
   
   if (dailyLoss >= dailyLossLimit) {
      dailyLimitHit = true;
      Print("DAILY LOSS LIMIT HIT! Loss: $", dailyLoss, " / Limit: $", dailyLossLimit);
      Print("Trading paused for the day.");
   }
}

//+------------------------------------------------------------------+
//| Calculate swing highs and lows                                   |
//+------------------------------------------------------------------+
void CalculateSwingLevels()
{
   int lookback = 10;
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
         fibLevel = 0.50;
         break;
   }
}

//+------------------------------------------------------------------+
//| Check for trade signals & initiate first position                |
//+------------------------------------------------------------------+
void CheckTradeSignals()
{
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   
   // Check if we already have an active trade
   if (CountActivePositions() > 0) {
      return; // Already in a trade, scaling will handle additional entries
   }
   
   // Check for breakout above swing high (BUY)
   if (Close[0] > swingHigh && Close[1] <= swingHigh) {
      OpenFirstPosition(true, ask, bid); // true = BUY
   }
   
   // Check for breakout below swing low (SELL)
   if (Close[0] < swingLow && Close[1] >= swingLow) {
      OpenFirstPosition(false, ask, bid); // false = SELL
   }
}

//+------------------------------------------------------------------+
//| Open First Position                                              |
//+------------------------------------------------------------------+
void OpenFirstPosition(bool isBuy, double ask, double bid)
{
   double tp, sl, lots;
   int orderType = isBuy ? OP_BUY : OP_SELL;
   double entryPrice = isBuy ? ask : bid;
   
   // Get TP/SL based on mode
   switch(TradingMode) {
      case SCALP_MODE:
         tp = isBuy ? ask + (ScalpTakeProfit * Point()) : bid - (ScalpTakeProfit * Point());
         sl = isBuy ? bid - (ScalpStopLoss * Point()) : ask + (ScalpStopLoss * Point());
         break;
      case SWING_MODE:
         tp = isBuy ? ask + (SwingTakeProfit * Point()) : bid - (SwingTakeProfit * Point());
         sl = isBuy ? bid - (SwingStopLoss * Point()) : ask + (SwingStopLoss * Point());
         break;
      case TREND_FOLLOW_MODE:
         tp = isBuy ? ask + (TrendTakeProfit * Point()) : bid - (TrendTakeProfit * Point());
         sl = isBuy ? bid - (TrendStopLoss * Point()) : ask + (TrendStopLoss * Point());
         break;
   }
   
   // Calculate lot size
   if (UseAutoSizing) {
      lots = CalculateLotSize(RiskPercent, sl);
   } else {
      lots = LotSize;
   }
   
   // Open order
   int ticket = OrderSend(Symbol(), orderType, lots, entryPrice, 10, sl, tp,
                        "GoldScalper P1", MagicNumber, 0, isBuy ? clrGreen : clrRed);
   
   if (ticket > 0) {
      Print("=== POSITION 1 OPENED ===");
      Print("Ticket: ", ticket, " | Type: ", (isBuy ? "BUY" : "SELL"), " | Lots: ", lots);
      Print("Entry: ", entryPrice, " | TP: ", tp, " | SL: ", sl);
      
      positions[0].ticket = ticket;
      positions[0].entryPrice = entryPrice;
      positions[0].quantity = lots;
      positions[0].positionNumber = 1;
      positions[0].partialClosed = false;
      activePositions = 1;
   }
}

//+------------------------------------------------------------------+
//| Manage Positions - Scaling & Partial Exits                       |
//+------------------------------------------------------------------+
void ManagePositions()
{
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   
   for (int i = 0; i < activePositions; i++) {
      if (!OrderSelect(positions[i].ticket, SELECT_BY_TICKET)) continue;
      
      int orderType = OrderType();
      bool isBuy = (orderType == OP_BUY);
      double currentPrice = isBuy ? bid : ask;
      double pipsProfit = isBuy ? (currentPrice - positions[i].entryPrice) / Point() : 
                                   (positions[i].entryPrice - currentPrice) / Point();
      
      // Position 1: Check for partial exit at PartialTP1
      if (positions[i].positionNumber == 1 && pipsProfit >= PartialTP1 && !positions[i].partialClosed) {
         double closePrice = isBuy ? bid : ask;
         double halfQuantity = positions[i].quantity / 2.0;
         
         if (OrderClose(positions[i].ticket, halfQuantity, closePrice, 10)) {
            positions[i].partialClosed = true;
            Print("=== POSITION 1 PARTIAL CLOSE ===");
            Print("Closed 50% at ", pipsProfit, " pips profit");
         }
      }
      
      // Position 2: Check for partial exit at PartialTP2
      if (positions[i].positionNumber == 2 && pipsProfit >= PartialTP2 && !positions[i].partialClosed) {
         double closePrice = isBuy ? bid : ask;
         double halfQuantity = positions[i].quantity / 2.0;
         
         if (OrderClose(positions[i].ticket, halfQuantity, closePrice, 10)) {
            positions[i].partialClosed = true;
            Print("=== POSITION 2 PARTIAL CLOSE ===");
            Print("Closed 50% at ", pipsProfit, " pips profit");
         }
      }
      
      // Check for scaling: Open Position 2 if Position 1 has X pips profit
      if (activePositions == 1 && pipsProfit >= ScalingDistance) {
         OpenScalingPosition(2, isBuy, ask, bid);
      }
      
      // Check for scaling: Open Position 3 if Position 2 has X pips profit
      if (activePositions == 2 && positions[1].entryPrice != 0) {
         double p2Profit = isBuy ? (currentPrice - positions[1].entryPrice) / Point() :
                                   (positions[1].entryPrice - currentPrice) / Point();
         if (p2Profit >= ScalingDistance) {
            OpenScalingPosition(3, isBuy, ask, bid);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Open Scaling Position (Position 2 or 3)                          |
//+------------------------------------------------------------------+
void OpenScalingPosition(int positionNum, bool isBuy, double ask, double bid)
{
   if (activePositions >= 3) return; // Already have 3 positions
   
   double tp, sl, lots;
   int orderType = isBuy ? OP_BUY : OP_SELL;
   double entryPrice = isBuy ? ask : bid;
   
   // Get TP/SL based on mode
   switch(TradingMode) {
      case SCALP_MODE:
         tp = isBuy ? ask + (ScalpTakeProfit * Point()) : bid - (ScalpTakeProfit * Point());
         sl = isBuy ? bid - (ScalpStopLoss * Point()) : ask + (ScalpStopLoss * Point());
         break;
      case SWING_MODE:
         tp = isBuy ? ask + (SwingTakeProfit * Point()) : bid - (SwingTakeProfit * Point());
         sl = isBuy ? bid - (SwingStopLoss * Point()) : ask + (SwingStopLoss * Point());
         break;
      case TREND_FOLLOW_MODE:
         tp = isBuy ? ask + (TrendTakeProfit * Point()) : bid - (TrendTakeProfit * Point());
         sl = isBuy ? bid - (TrendStopLoss * Point()) : ask + (TrendStopLoss * Point());
         break;
   }
   
   if (UseAutoSizing) {
      lots = CalculateLotSize(RiskPercent, sl);
   } else {
      lots = LotSize;
   }
   
   int ticket = OrderSend(Symbol(), orderType, lots, entryPrice, 10, sl, tp,
                        "GoldScalper P" + IntegerToString(positionNum), MagicNumber, 0, isBuy ? clrBlue : clrOrange);
   
   if (ticket > 0) {
      Print("=== POSITION ", positionNum, " OPENED ===");
      Print("Ticket: ", ticket, " | Lots: ", lots);
      Print("Entry: ", entryPrice, " | TP: ", tp, " | SL: ", sl);
      
      positions[positionNum - 1].ticket = ticket;
      positions[positionNum - 1].entryPrice = entryPrice;
      positions[positionNum - 1].quantity = lots;
      positions[positionNum - 1].positionNumber = positionNum;
      positions[positionNum - 1].partialClosed = false;
      activePositions = positionNum;
   }
}

//+------------------------------------------------------------------+
//| Manage Trailing Stops for Position 3                             |
//+------------------------------------------------------------------+
void ManageTrailingStops()
{
   if (activePositions < 3) return; // Only trail Position 3
   
   if (!OrderSelect(positions[2].ticket, SELECT_BY_TICKET)) return;
   
   int orderType = OrderType();
   bool isBuy = (orderType == OP_BUY);
   double currentPrice = isBuy ? SymbolInfoDouble(Symbol(), SYMBOL_BID) : 
                                SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   
   double newSL = isBuy ? currentPrice - (TrailingStopPips * Point()) :
                         currentPrice + (TrailingStopPips * Point());
   
   double currentSL = OrderStopLoss();
   
   // Only move SL up (for buys) or down (for sells) if more profitable
   if (isBuy && newSL > currentSL) {
      OrderModify(positions[2].ticket, OrderOpenPrice(), newSL, OrderTakeProfit(), 0);
   } else if (!isBuy && newSL < currentSL) {
      OrderModify(positions[2].ticket, OrderOpenPrice(), newSL, OrderTakeProfit(), 0);
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
   
   double min_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   
   if (lot_size < min_lot) lot_size = min_lot;
   if (lot_size > max_lot) lot_size = max_lot;
   
   return lot_size;
}

//+------------------------------------------------------------------+
//| Count active positions                                           |
//+------------------------------------------------------------------+
int CountActivePositions()
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
//| Calculate Daily P&L                                              |
//+------------------------------------------------------------------+
double CalculateDailyPnL()
{
   return dailyOpenBalance - AccountBalance();
}

//+------------------------------------------------------------------+
//| Update Control Panel on Chart                                    |
//+------------------------------------------------------------------+
void UpdateControlPanel()
{
   double dailyPnL = CalculateDailyPnL();
   double dailyPnLPercent = (dailyPnL / dailyOpenBalance) * 100;
   double remainingDailyLimit = dailyLossLimit - MathAbs(dailyPnL);
   
   string panel_info = "";
   panel_info += "\n╔════════ GOLD SCALPER BOT v2.0 ════════╗";
   panel_info += "\n║ Mode: " + GetModeName(TradingMode);
   panel_info += "\n║ Status: " + (EnableTrading ? "ACTIVE" : "INACTIVE");
   panel_info += "\n║ Positions: " + IntegerToString(CountActivePositions()) + "/3";
   panel_info += "\n║";
   panel_info += "\n║ Account: $" + DoubleToString(AccountBalance(), 2);
   panel_info += "\n║ Daily P&L: $" + DoubleToString(dailyPnL, 2) + " (" + DoubleToString(dailyPnLPercent, 1) + "%)";
   panel_info += "\n║ Daily Limit: -$" + DoubleToString(dailyLossLimit, 2);
   panel_info += "\n║ Remaining: $" + DoubleToString(remainingDailyLimit, 2);
   
   if (dailyLimitHit) {
      panel_info += "\n║";
      panel_info += "\n║ ⚠️  DAILY LIMIT HIT - NO TRADING ⚠️";
   }
   
   panel_info += "\n║";
   panel_info += "\n║ Swing High: " + DoubleToString(swingHigh, 2);
   panel_info += "\n║ Swing Low: " + DoubleToString(swingLow, 2);
   panel_info += "\n║ Price: " + DoubleToString(Close[0], 2);
   panel_info += "\n╚═══════════════════════════════════════╝";
   
   Comment(panel_info);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("Gold Scalper Bot v2.0 Stopped");
   Comment("");
}

//+------------------------------------------------------------------+
