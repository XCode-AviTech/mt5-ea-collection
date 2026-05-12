# Installation Guide

## Files
- `ProfessionalTradingBot_MT4.mq4`
- `FBOT_MultiStrategy_MT5_v1.mq5`

## MT5 Installation
1. Open MetaTrader 5.
2. Go to `File -> Open Data Folder`.
3. Copy `FBOT_MultiStrategy_MT5_v1.mq5` into `MQL5\Experts\`.
4. Restart MT5 or refresh the Navigator.
5. Open the file in MetaEditor and compile it.
6. Attach the EA to a chart and enable Algo Trading.

## Important Terminal Settings
- Enable `Allow Algo Trading`.
- Enable `Allow WebRequest for listed URL` if using Telegram:
  - `https://api.telegram.org`
- Configure email and push notifications in terminal options before enabling them in the EA.

## First Launch Checklist
1. Set `ExpirationDate` and optionally `LockedAccountNumber`.
2. Generate your `LicenseKey` in the format `FBOT-PRO-YYYYMMDD-###`.
3. If `BindLicenseToAccount = true`, the key is tied to the current or locked account number.
4. Review session hours against your broker server time.
5. Review `NewsBlockWindows` for your trading day.
6. Start with demo or strategy tester before live deployment.
