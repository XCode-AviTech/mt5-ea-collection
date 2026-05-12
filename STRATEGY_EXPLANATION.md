# Strategy Explanation

## Core Trading Logic
The EA uses a weighted confirmation model. Each enabled strategy contributes to a buy or sell confidence score. Trades are only considered when:
- Higher timeframe trend agrees.
- ADX confirms sufficient trend strength.
- Candle confirmation supports direction.
- Liquidity/session filters permit trading.
- Risk and protection rules are all satisfied.

## Confidence Model
- HTF trend adds primary directional weight.
- Individual strategies add conditional weight.
- Volume expansion adds bonus confidence.
- Fake breakout checks remove weak breakout entries.
- Final entries require a score threshold of `65`.

## SMC / ICT Implementation
The SMC and ICT modules use practical mechanical proxies:
- Liquidity sweeps.
- Displacement candles.
- Discount/premium zones.
- Fair value gaps.
- OTE retracement bands based on Fibonacci levels.

This keeps the logic non-repainting and backtestable.

## Exit Model
- Initial stop and target use ATR multipliers.
- Break-even activates after configurable R multiple.
- Trailing stop adapts to ATR.
- Partial profits can close a configurable percentage of volume.

## Design Philosophy
The EA favors capital preservation and robustness over overfit entry frequency. It is intentionally conservative and avoids unrealistic promise mechanics.
