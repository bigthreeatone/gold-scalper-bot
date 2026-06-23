# Trading Guide - Gold Scalper Bot

## Understanding the Three Modes

### 1. SCALP MODE (5M Timeframe)
**Best For**: Aggressive traders with time to monitor

- **Entry**: Breakout of 5M swing high/low + Fib 61.8% retracement
- **Target**: 2-5 pips profit
- **Stop Loss**: 10 pips
- **Trade Duration**: 2-5 minutes average
- **Trades Per Day**: 5-15 trades
- **Risk**: HIGH (tight stops, scalps spread costs)
- **Edge**: Quick reversals, high win rate needed (70%+)

**Example**:
```
Swing High: 2050.00
Swing Low: 2048.50
Fib 61.8%: 2049.41

Price breaks above 2050.00 → BUY at 2050.05
TP: 2050.10 (5 pips) ✓
SL: 2050.15 (10 pips) ✗
```

### 2. SWING MODE (15M Timeframe)
**Best For**: Balanced traders

- **Entry**: Breakout of 15M swing high/low + Fib 50% retracement
- **Target**: 10-20 pips profit
- **Stop Loss**: 25 pips
- **Trade Duration**: 15-45 minutes average
- **Trades Per Day**: 3-8 trades
- **Risk**: MEDIUM (reasonable risk/reward)
- **Edge**: Swing structure more reliable

**Example**:
```
Swing High: 2055.00
Swing Low: 2048.00
Fib 50%: 2051.50

Price breaks above 2055.00 → BUY at 2055.10
TP: 2055.25 (15 pips) ✓
SL: 2054.85 (25 pips) ✗
Risk/Reward: 1:0.6 (reasonable)
```

### 3. TREND FOLLOW MODE
**Best For**: Directional traders, sustained moves

- **Entry**: Breakout + momentum confirmation
- **Target**: 20+ pips profit
- **Stop Loss**: 40 pips
- **Trade Duration**: 45 min - 4 hours
- **Trades Per Day**: 1-3 trades
- **Risk**: MEDIUM-HIGH (larger stops, bigger swings)
- **Edge**: Catching medium-term trends

**Example**:
```
Price breaks key level → Momentum spike
BUY at 2050.00
TP: 2051.50 (30 pips) ✓
SL: 2049.00 (40 pips) ✗
Risk/Reward: 1:0.75 (good)
```

---

## Position Sizing - Critical for $11 Account

### Risk Management Formula
```
Risk Amount = Account Balance × Risk %
Position Size (lots) = Risk Amount / (SL in pips × pip value)
```

### Example on $11 Demo
```
Account: $11
Risk per trade: 1% = $0.11
Stop Loss: 10 pips = $1 per pip per lot

Lot Size = $0.11 / $1 = 0.11 lots (mini lot)

→ If trade hits SL, you lose $0.11 (exactly 1%)
→ If trade hits TP (5 pips), you profit $0.55 (5% of account!)
```

**Always Use Auto Sizing**: `UseAutoSizing = true`

---

## Daily Workflow

### Morning (Chart Setup)
1. Open XAUUSD 5M chart
2. Attach EA with your chosen mode
3. Set `EnableTrading = true`
4. Monitor control panel

### During Trading
1. **Watch for swing breaks** on your active timeframe
2. **Let EA execute** (don't manual trade same pair)
3. **Monitor TP/SL levels** - they auto-close
4. **Take screenshots** of winning trades for analysis

### Evening (Review)
1. Check **Account Balance** - did you profit/lose?
2. Count **Win Rate** - trades won vs total
3. Analyze **Biggest Loss** - why did it lose?
4. Adjust **Parameters** if needed

---

## When to Switch Modes

### Switch TO Scalp Mode if:
- ✓ Market is choppy (no clear trend)
- ✓ Volatility is low (tight ranges)
- ✓ You have time to watch charts

### Switch TO Swing Mode if:
- ✓ 5M scalps are losing (spread too high)
- ✓ Market structure clear but slow
- ✓ You want fewer trades, higher confidence

### Switch TO Trend Mode if:
- ✓ Strong directional break happened
- ✓ Major economic news passed
- ✓ You see 4H/1D breakout on XAUUSD

---

## Red Flags - STOP Trading

⛔ **Stop trading if:**
1. **Spread > 5 pips** (market too wide, scalping impossible)
2. **Slippage > 2 pips** (execution too slow for scalping)
3. **Lost 3 trades in a row** (reassess strategy)
4. **Account drawdown > 20%** (take break, review)
5. **News event imminent** (Gold is sensitive to USD moves)

---

## Performance Goals (Realistic)

### Month 1 (Learning)
- Goal: Break even or +5-10% (focus on learning)
- Expectation: Some losses while optimizing

### Month 2-3 (Optimization)
- Goal: +10-20% per month (2-5 trades/day winning)
- Expectation: Consistent small profits

### Month 4+ (Scaling)
- Goal: +20-30% per month (scale lot size)
- Expectation: $11 → $50+ per month potential

**Reality Check**: Scalping is hard. 70%+ win rate needed. Most fail. You might lose the $11. That's OK—it's a learning investment.

---

## Example Trade Log

```
Date       | Mode   | Entry  | Exit | P&L   | Comment
-----------|--------|--------|------|-------|----------
6/23 09:15 | SCALP  | 2050.0 | 2050.05 | +0.55 | Quick win ✓
6/23 09:22 | SCALP  | 2049.8 | 2049.70 | -0.11 | Hit SL ✗
6/23 09:45 | SWING  | 2051.2 | 2051.35 | +0.75 | Nice swing ✓
6/23 10:15 | TREND  | 2050.0 | 2051.30 | +6.50 | Home run! 🏄
-----------|--------|--------|------|-------|----------
Daily: +$7.69 (+70% on $11)
```

---

## Final Tips

1. **Document every trade** (spreadsheet or notes)
2. **Review weekly** - what worked? What didn't?
3. **Don't overtrade** - quality > quantity
4. **Stick to rules** - no FOMO trades
5. **Celebrate small wins** - $0.55 on scalps compounds
6. **Accept losses** - part of the game

**Good luck! 🚀**
