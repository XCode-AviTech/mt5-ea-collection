# Backtesting Instructions

## MT4
1. Open `View -> Strategy Tester`.
2. Select `ProfessionalTradingBot_MT4`.
3. Choose symbol, timeframe, and test date range.
4. Use high-quality data where possible.
5. Enable optimization for parameters like:
   - `RiskPerTradePercent`
   - `FastEMA`
   - `SlowEMA`
   - `ADXMinimum`
   - `StopLossATRMultiplierX10`
   - `TakeProfitATRMultiplierX10`

## MT5
1. Open `View -> Strategy Tester`.
2. Select `FBOT_MultiStrategy_MT5_v1`.
3. Use `Every tick based on real ticks` when available.
4. Run single tests first, then genetic optimization.

## Metrics To Watch
- Net profit
- Profit factor
- Expected payoff
- Drawdown
- Recovery factor
- Sharpe ratio
- Win rate
- Average R multiple

## Optimization Guidance
- Optimize per symbol and session.
- Keep walk-forward validation separate from in-sample optimization.
- Reject parameter sets with unstable equity curves or excessive spread sensitivity.
- Prioritize low drawdown and recovery factor, not only total return.

## Logging
The EA writes trade and control-flow messages to the Experts log. Review logs for:
- spread blocks
- news/session blocks
- margin or drawdown protection triggers
- order execution failures
