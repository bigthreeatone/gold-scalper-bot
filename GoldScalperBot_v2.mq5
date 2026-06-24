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
input int ScalingDistance = 5;         // Pips between entries
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
double dailyOpenBalance = 0;
double dailyLossLimit = 0;
bool dailyLimitHit = false;

struct PositionData {
   int ticket;
   double entryPrice;
   double quantity;
   int positionNumber;
   bool partialClosed;
};

PositionData positions[3];
int activePositions = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("====== Gold Scalper Bot v2.0 Initialized ======" );
   Print("Mode: ", GetModeName(TradingMode));
   Print("Base Lot Size: ", LotSize);
   Print("Daily Loss Limit: ", DailyLossLimitPercent, "%");
   Print("Scaling Distance: ", ScalingDistance, " pips");
   
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
   
   CheckDailyLossLimit();
   
   if (dailyLimitHit) {
      if (ShowControlPanel) UpdateControlPanel();
      return;
   }
   
   if (ShowControlPanel) {
      UpdateControlPanel();
   }
   
   CalculateSwingLevels();
   UpdateFibLevel();
   CheckTradeSignals();
   ManagePositions();
   
   if (UseTrailingStop) {
      ManageTrailingStops();
   }
}

//+------------------------------------------------------------------+
//| Check Daily Loss Limit                                           |
//+------------------------------------------------------------------+
void CheckDailyLossLimit()
{
   if (Hour() == 0 && Minute() < 1 && dailyLimitHit) {
      dailyOpenBalance = AccountBalance();
      dailyLimitHit = false;
      Print("Daily limit reset. Balance: $", dailyOpenBalance);
   }
   
   double currentBalance = AccountBalance();
   double dailyLoss = dailyOpenBalance - currentBalance;
   
   if (dailyLoss >= dailyLossLimit && dailyLoss > 0) {
      dailyLimitHit = true;
      Print("DAILY LOSS LIMIT HIT! Loss: $", dailyLoss);
   }
}

//+------------------------------------------------------------------+
//| Calculate swing highs and lows                                   |
//+------------------------------------------------------------------+
void CalculateSwingLevels()
{
   swingHigh = High[iHighest(NULL, 0, MODE_HIGH, 10, 1)];
   swingLow = Low[iLowest(NULL, 0, MODE_LOW, 10, 1)];
}

//+------------------------------------------------------------------+
//| Update Fib level based on mode                                   |
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
//| Check for trade signals                                          |
//+------------------------------------------------------------------+
void CheckTradeSignals()
{
   if (CountActivePositions() > 0) return;
   
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   
   if (Close[0] > swingHigh && Close[1] <= swingHigh) {
      OpenFirstPosition(true, ask, bid);
   }
   
   if (Close[0] < swingLow && Close[1] >= swingLow) {
      OpenFirstPosition(false, ask, bid);
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
   
   lots = UseAutoSizing ? CalculateLotSize(RiskPercent, sl) : LotSize;
   
   int ticket = OrderSend(Symbol(), orderType, lots, entryPrice, 10, sl, tp,
                        "GoldScalper P1", MagicNumber, 0, isBuy ? clrGreen : clrRed);
   
   if (ticket > 0) {
      Print("POSITION 1 OPENED - Ticket: ", ticket);
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
      
      // Partial exits
      if (positions[i].positionNumber == 1 && pipsProfit >= PartialTP1 && !positions[i].partialClosed) {
         double closePrice = isBuy ? bid : ask;
         if (OrderClose(positions[i].ticket, positions[i].quantity / 2.0, closePrice, 10)) {
            positions[i].partialClosed = true;
            Print("Position 1 partial close at ", pipsProfit, " pips");
         }
      }
      
      if (positions[i].positionNumber == 2 && pipsProfit >= PartialTP2 && !positions[i].partialClosed) {
         double closePrice = isBuy ? bid : ask;
         if (OrderClose(positions[i].ticket, positions[i].quantity / 2.0, closePrice, 10)) {
            positions[i].partialClosed = true;
            Print("Position 2 partial close at ", pipsProfit, " pips");
         }
      }
      
      // Scaling
      if (activePositions == 1 && pipsProfit >= ScalingDistance) {
         OpenScalingPosition(2, isBuy, ask, bid);
      }
      
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
//| Open Scaling Position                                            |
//+------------------------------------------------------------------+
void OpenScalingPosition(int positionNum, bool isBuy, double ask, double bid)
{
   if (activePositions >= 3) return;
   
   double tp, sl, lots;
   int orderType = isBuy ? OP_BUY : OP_SELL;
   double entryPrice = isBuy ? ask : bid;
   
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
   
   lots = UseAutoSizing ? CalculateLotSize(RiskPercent, sl) : LotSize;
   
   int ticket = OrderSend(Symbol(), orderType, lots, entryPrice, 10, sl, tp,
                        "GoldScalper P" + IntegerToString(positionNum), MagicNumber, 0, clrBlue);
   
   if (ticket > 0) {
      Print("POSITION ", positionNum, " OPENED - Ticket: ", ticket);
      positions[positionNum - 1].ticket = ticket;
      positions[positionNum - 1].entryPrice = entryPrice;
      positions[positionNum - 1].quantity = lots;
      positions[positionNum - 1].positionNumber = positionNum;
      positions[positionNum - 1].partialClosed = false;
      activePositions = positionNum;
   }
}

//+------------------------------------------------------------------+
//| Manage Trailing Stops                                            |
//+------------------------------------------------------------------+
void ManageTrailingStops()
{
   if (activePositions < 3) return;
   if (!OrderSelect(positions[2].ticket, SELECT_BY_TICKET)) return;
   
   int orderType = OrderType();
   bool isBuy = (orderType == OP_BUY);
   double currentPrice = isBuy ? SymbolInfoDouble(Symbol(), SYMBOL_BID) : 
                                SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   
   double newSL = isBuy ? currentPrice - (TrailingStopPips * Point()) :
                         currentPrice + (TrailingStopPips * Point());
   
   double currentSL = OrderStopLoss();
   
   if (isBuy && newSL > currentSL) {
      OrderModify(positions[2].ticket, OrderOpenPrice(), newSL, OrderTakeProfit(), 0);
   } else if (!isBuy && newSL < currentSL) {
      OrderModify(positions[2].ticket, OrderOpenPrice(), newSL, OrderTakeProfit(), 0);
   }
}

//+------------------------------------------------------------------+
//| Calculate lot size                                               |
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
         return "SCALP (5M)";
      case SWING_MODE:
         return "SWING (15M)";
      case TREND_FOLLOW_MODE:
         return "TREND";
      default:
         return "UNKNOWN";
   }
}

//+------------------------------------------------------------------+
//| Update Control Panel                                             |
//+------------------------------------------------------------------+
void UpdateControlPanel()
{
   double dailyPnL = dailyOpenBalance - AccountBalance();
   double dailyPnLPercent = (dailyPnL / dailyOpenBalance) * 100;
   
   string panel = "";
   panel += "\n╔════ GOLD SCALPER v2.0 ════╗";
   panel += "\n║ Mode: " + GetModeName(TradingMode);
   panel += "\n║ Positions: " + IntegerToString(CountActivePositions()) + "/3";
   panel += "\n║ Account: $" + DoubleToString(AccountBalance(), 2);
   panel += "\n║ Daily P&L: $" + DoubleToString(dailyPnL, 2);
   panel += "\n║ Limit: -$" + DoubleToString(dailyLossLimit, 2);
   
   if (dailyLimitHit) {
      panel += "\n║ ⚠️ DAILY LIMIT HIT";
   }
   
   panel += "\n║ Price: " + DoubleToString(Close[0], 2);
   panel += "\n╚═══════════════════════════╝";
   
   Comment(panel);
}

//+------------------------------------------------------------------+
//| Expert deinit                                                    |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("Gold Scalper Bot v2.0 Stopped");
   Comment("");
}

//+------------------------------------------------------------------+
