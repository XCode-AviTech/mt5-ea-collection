# User Manual

## Overview
This EA is a multi-strategy trading framework for Forex, gold, crypto, and synthetic indices. It focuses on confirmation-based entries, layered risk management, and practical live-trading controls.

## Main Controls
- `InpStrategyMode`: chooses Auto or a specific strategy family.
- `AllowNewTrades`: master switch for new entries.
- `RiskPerTradePercent`: balance-based risk sizing.
- `MaxOpenTrades`: caps simultaneous exposure.
- `UseManualNewsWindows`: blocks trading during configured time ranges.

## Dashboard Buttons
- `Start/Stop`: toggles automated entries.
- `Close All`: closes all EA-managed positions for the chart symbol.
- `Mode`: cycles through strategy modes on-chart.

## Strategy Families
- Trend Following: EMA/SMA/MACD alignment with HTF confirmation.
- Scalping: RSI and stochastic momentum alignment.
- Breakout: range break with retest confirmation.
- Mean Reversion: Bollinger and RSI extremes.
- SMC: liquidity sweep plus displacement and discount/premium logic.
- ICT: fair value gap plus OTE retracement logic.

## Risk Protections
- Daily loss stop.
- Daily target stop.
- Maximum drawdown protection.
- Margin floor protection.
- Spread filter.
- Consecutive loss pause.
- Abnormal ATR-based volatility pause.

## Notifications
- Push notifications.
- Email alerts.
- Telegram alerts through `WebRequest`.

## Practical Notes
- Grid and hedging are exposed as strategy modes, but the EA keeps conservative execution defaults and does not enable aggressive martingale behavior.
- News filtering is implemented through manual time windows so it stays portable across MT4 and MT5 without depending on broker-specific calendar feeds.
