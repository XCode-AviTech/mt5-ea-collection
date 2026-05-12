# Recommended Settings

## Conservative Forex Swing
- Timeframe: `M15` or `H1`
- Mode: `Auto` or `Trend`
- RiskPerTradePercent: `0.5 - 1.0`
- MaxOpenTrades: `1 - 2`
- DailyLossLimitPercent: `2.0`
- DailyTargetPercent: `3.0`
- ADXMinimum: `22`

## Intraday Scalping
- Timeframe: `M5`
- Mode: `Scalping`
- RiskPerTradePercent: `0.25 - 0.75`
- MaxSpreadPoints: tighten for your broker
- TradeLondonSession: `true`
- TradeNewYorkSession: `true`
- TradeAsianSession: `false`

## Breakout Indices / Gold
- Timeframe: `M15`
- Mode: `Breakout`
- ATR multiplier for SL: `1.8`
- ATR multiplier for TP: `3.0`
- VolumeLookback: `30`
- ConsecutiveLossLimit: `2`

## SMC / ICT Filtering
- Timeframe: `M15` or `H1`
- Mode: `SMC` or `ICT`
- EnableTrendFollowing: `true`
- EnableBreakout: `true`
- ADXMinimum: `18 - 22`

## Live Deployment Advice
- Start with one symbol.
- Use VPS hosting.
- Keep Telegram and email alerts on.
- Update `NewsBlockWindows` daily around red-folder events.
- Re-optimize per asset class, not one preset for every market.
