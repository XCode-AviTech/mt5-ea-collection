# FBOT_MultiStrategy_MT5_v1

FBOT_MultiStrategy_MT5_v1 is a multi-strategy Expert Advisor for MetaTrader 5 designed for controlled execution, configurable risk management, and team-friendly deployment.

## Features

- Multi-strategy trading:
  - Trend
  - Scalping
  - Breakout
  - Mean Reversion
  - SMC
  - ICT
- Built-in risk management controls
- Daily loss, target, and drawdown protection
- On-chart dashboard controls
- Push, email, and Telegram notifications
- Configurable license and account binding
- Backtesting support in MT5 Strategy Tester

## Project Structure

- `src/` - source code
- `dist/` - compiled distributable files
- `docs/` - documentation
- `presets/` - saved parameter sets
- `assets/` - screenshots or branding assets

## Main Files

- `src/FBOT_MultiStrategy_MT5_v1.mq5`
- `dist/FBOT_MultiStrategy_MT5_v1.ex5`

## Installation

1. Copy the EA source file into `MQL5/Experts/`.
2. Open MetaEditor and compile the file.
3. Attach the EA to a chart in MetaTrader 5.
4. Configure trading, risk, and license inputs.
5. Enable Algo Trading.

## Sharing

Share the compiled `.ex5` file with colleagues if you do not want to expose source code.

## Notes

This repository is intended for internal collaboration, testing, and controlled deployment.

## License

Private/internal use unless stated otherwise.
