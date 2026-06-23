# Installation Guide - Gold Scalper Bot

## Prerequisites
- MetaTrader 5 installed
- XM Global or compatible MT5 broker account
- Demo account (recommended for testing)

## Step-by-Step Installation

### 1. Download the EA
```bash
git clone https://github.com/bigthreeatone/gold-scalper-bot.git
```

### 2. Locate MT5 Experts Folder
- Open MT5
- Go to **File → Open Data Folder**
- Navigate to: `MQL5/Experts/`

### 3. Copy EA File
- Copy `GoldScalperBot.mq5` to `MQL5/Experts/`
- Restart MetaTrader 5 (or press F5 to refresh)

### 4. Compile the EA
- In MT5, go to **Tools → MetaEditor**
- Open `GoldScalperBot.mq5`
- Press **Ctrl + Shift + F9** to compile
- Should show: "0 errors, 0 warnings"

### 5. Attach to Chart
- Open XAUUSD chart in MT5
- Set timeframe to **5 minutes** (or 15M for Swing mode)
- Drag & drop `GoldScalperBot` EA onto chart
- OR: Right-click → **Indicators & EAs → Attach EA**

### 6. Configure Settings
In the EA settings window:
- **Trading Mode**: Select SCALP_MODE / SWING_MODE / TREND_FOLLOW_MODE
- **Lot Size**: 0.01 (demo) or 0.1 (micro)
- **Risk Percent**: 1.0 - 2.0%
- **Enable Trading**: Check ✓

### 7. Allow DLL/API Access
- Right-click EA → **Expert Advisors → Allow**
- Check all required permissions

### 8. Start Trading
- Watch the control panel on your chart
- Monitor account balance and trades
- Adjust parameters as needed

## Configuration Tips

### For Scalp Mode (5M)
```
TradingMode = SCALP_MODE
ScalpTakeProfit = 5 pips
ScalpStopLoss = 10 pips
LotSize = 0.01 (demo) or 0.1 (micro)
```

### For Swing Mode (15M)
```
TradingMode = SWING_MODE
SwingTakeProfit = 15 pips
SwingStopLoss = 25 pips
LotSize = 0.01 - 0.05
```

### For Trend Mode
```
TradingMode = TREND_FOLLOW_MODE
TrendTakeProfit = 30 pips
TrendStopLoss = 40 pips
LotSize = 0.05 - 0.1
```

## Troubleshooting

**"EA not trading"**
- Check if `EnableTrading = true`
- Verify chart timeframe matches strategy (5M or 15M)
- Check account balance

**"Compilation errors"**
- Ensure MT5 is updated to latest version
- Delete *.ex5 files and recompile

**"Orders not closing"**
- Verify TP/SL values are reasonable
- Check if spread is too wide for scalping

## Support
For issues, check:
- EA logs: **Tools → Logs → Experts**
- MT5 Journal tab for error messages
- GitHub Issues: https://github.com/bigthreeatone/gold-scalper-bot/issues
