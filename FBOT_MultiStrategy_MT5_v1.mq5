#property strict
#property version   "1.00"
#property description "FBOT MultiStrategy MT5 v1"

#include <Trade/Trade.mqh>

enum ENUM_STRATEGY_MODE
  {
   STRATEGY_AUTO = 0,
   STRATEGY_TREND = 1,
   STRATEGY_SCALPING = 2,
   STRATEGY_BREAKOUT = 3,
   STRATEGY_MEAN_REVERSION = 4,
   STRATEGY_SMC = 5,
   STRATEGY_ICT = 6,
   STRATEGY_GRID = 7,
   STRATEGY_HEDGING = 8,
   STRATEGY_NEWS_FILTERED = 9
  };

input group "General"
input ENUM_STRATEGY_MODE InpStrategyMode = STRATEGY_AUTO;
input bool EnableTrendFollowing = true;
input bool EnableScalping = true;
input bool EnableBreakout = true;
input bool EnableMeanReversion = true;
input bool EnableSMC = true;
input bool EnableICT = true;
input bool EnableGrid = false;
input bool EnableHedging = true;
input bool EnableNewsFilteredTrading = true;
input ulong MagicNumber = 260510;
input bool AllowNewTrades = true;
input int MaxOpenTrades = 3;
input bool OneTradePerBar = true;
input ENUM_TIMEFRAMES SignalTimeframe = PERIOD_M15;
input ENUM_TIMEFRAMES TrendTimeframe = PERIOD_H1;
input ENUM_TIMEFRAMES HigherTrendTimeframe = PERIOD_H4;

input group "License & Security"
input string LicenseKey = "";
input string LicenseSeed = "FBOT-PRO";
input bool BindLicenseToAccount = true;
input long LockedAccountNumber = 0;
input string ExpirationDate = "2027.12.31";
input bool RequireConnectedTerminal = true;

input group "Risk Management"
input double RiskPerTradePercent = 1.0;
input double DailyLossLimitPercent = 3.0;
input double DailyTargetPercent = 4.0;
input double MaximumDrawdownPercent = 15.0;
input int ConsecutiveLossLimit = 3;
input double MarginLevelFloorPercent = 150.0;
input double MaxSpreadPoints = 40.0;
input int MaxSlippagePoints = 15;
input double ATRVolatilityPauseMultiplier = 2.5;
input bool EnableDynamicLotSizing = true;
input bool EnableTrailingStop = true;
input bool EnableBreakEven = true;
input bool EnablePartialProfits = true;
input bool EnableEquityProtection = true;
input int StopLossATRMultiplierX10 = 15;
input int TakeProfitATRMultiplierX10 = 25;
input int TrailingATRMultiplierX10 = 12;
input double BreakEvenTriggerR = 1.0;
input double PartialCloseAtR = 1.2;
input double PartialClosePercent = 50.0;

input group "Indicators"
input int FastEMA = 20;
input int SlowEMA = 50;
input int SMAPeriod = 200;
input int RSIPeriod = 14;
input int RSIOverbought = 70;
input int RSIOversold = 30;
input int MACDFast = 12;
input int MACDSlow = 26;
input int MACDSignal = 9;
input int BollingerPeriod = 20;
input double BollingerDeviation = 2.0;
input int ATRPeriod = 14;
input int StochasticK = 5;
input int StochasticD = 3;
input int StochasticSlowing = 3;
input int ADXPeriod = 14;
input double ADXMinimum = 20.0;
input int IchimokuTenkan = 9;
input int IchimokuKijun = 26;
input int IchimokuSenkou = 52;
input int VolumeLookback = 20;

input group "Sessions & Filters"
input bool TradeAsianSession = false;
input bool TradeLondonSession = true;
input bool TradeNewYorkSession = true;
input int AsianStartHour = 0;
input int AsianEndHour = 8;
input int LondonStartHour = 7;
input int LondonEndHour = 16;
input int NewYorkStartHour = 13;
input int NewYorkEndHour = 22;
input bool UseCorrelationFilter = false;
input string CorrelationSymbols = "EURUSD,GBPUSD";
input bool UseManualNewsWindows = true;
input string NewsBlockWindows = "12:25-12:40;15:25-15:40";
input bool AvoidLowLiquidityMinutes = true;
input int LiquidityBlockStartMinute = 55;
input int LiquidityBlockEndMinute = 5;

input group "Notifications"
input bool EnablePushNotifications = false;
input bool EnableEmailAlerts = false;
input bool EnableTelegramAlerts = false;
input string TelegramBotToken = "";
input string TelegramChatId = "";

input group "Dashboard"
input bool ShowDashboard = true;
input color DashboardBg = clrBlack;
input color DashboardText = clrWhite;
input color DashboardAccent = clrDodgerBlue;

struct StrategySignal
  {
   bool   buy;
   bool   sell;
   double confidence;
   string reason;
  };

CTrade trade;
datetime g_lastBarTime = 0;
datetime g_lastTradeBar = 0;
datetime g_lastResetDay = 0;
bool g_tradingEnabled = true;
int g_consecutiveLosses = 0;
double g_dayStartBalance = 0.0;
double g_peakEquity = 0.0;
ENUM_STRATEGY_MODE g_strategyMode;

int hFastEMA, hSlowEMA, hSMA, hRSI, hMACD, hBands, hATR, hStoch, hADX, hIchimoku;

string PREFIX = "FBOT5_";

int OnInit()
  {
   if(!ValidateLicense())
      return(INIT_FAILED);

   hFastEMA = iMA(_Symbol,SignalTimeframe,FastEMA,0,MODE_EMA,PRICE_CLOSE);
   hSlowEMA = iMA(_Symbol,SignalTimeframe,SlowEMA,0,MODE_EMA,PRICE_CLOSE);
   hSMA = iMA(_Symbol,SignalTimeframe,SMAPeriod,0,MODE_SMA,PRICE_CLOSE);
   hRSI = iRSI(_Symbol,SignalTimeframe,RSIPeriod,PRICE_CLOSE);
   hMACD = iMACD(_Symbol,SignalTimeframe,MACDFast,MACDSlow,MACDSignal,PRICE_CLOSE);
   hBands = iBands(_Symbol,SignalTimeframe,BollingerPeriod,0,BollingerDeviation,PRICE_CLOSE);
   hATR = iATR(_Symbol,SignalTimeframe,ATRPeriod);
   hStoch = iStochastic(_Symbol,SignalTimeframe,StochasticK,StochasticD,StochasticSlowing,MODE_SMA,STO_LOWHIGH);
   hADX = iADX(_Symbol,SignalTimeframe,ADXPeriod);
   hIchimoku = iIchimoku(_Symbol,SignalTimeframe,IchimokuTenkan,IchimokuKijun,IchimokuSenkou);

   if(hFastEMA == INVALID_HANDLE || hSlowEMA == INVALID_HANDLE || hSMA == INVALID_HANDLE ||
      hRSI == INVALID_HANDLE || hMACD == INVALID_HANDLE || hBands == INVALID_HANDLE ||
      hATR == INVALID_HANDLE || hStoch == INVALID_HANDLE || hADX == INVALID_HANDLE || hIchimoku == INVALID_HANDLE)
     {
      PrintFormat("Indicator initialization failed. FastEMA=%d SlowEMA=%d SMA=%d RSI=%d MACD=%d Bands=%d ATR=%d Stoch=%d ADX=%d Ichimoku=%d",
                  hFastEMA,hSlowEMA,hSMA,hRSI,hMACD,hBands,hATR,hStoch,hADX,hIchimoku);
      return(INIT_FAILED);
     }

   trade.SetExpertMagicNumber((int)MagicNumber);
   trade.SetDeviationInPoints(MaxSlippagePoints);

   g_dayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   g_peakEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   g_lastResetDay = iTime(_Symbol, PERIOD_D1, 0);
   g_strategyMode = InpStrategyMode;

   if(ShowDashboard)
      CreateDashboard();

   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   IndicatorRelease(hFastEMA);
   IndicatorRelease(hSlowEMA);
   IndicatorRelease(hSMA);
   IndicatorRelease(hRSI);
   IndicatorRelease(hMACD);
   IndicatorRelease(hBands);
   IndicatorRelease(hATR);
   IndicatorRelease(hStoch);
   IndicatorRelease(hADX);
   IndicatorRelease(hIchimoku);
   DeleteDashboard();
  }

void OnTick()
  {
   ResetDailyMetricsIfNeeded();
   UpdatePeakEquity();
   if(ShowDashboard)
      UpdateDashboard();

   ManageOpenPositions();

   if(!g_tradingEnabled || !AllowNewTrades)
      return;

   if(!IsNewBar() && OneTradePerBar)
      return;

   if(!TradingAllowedByFilters())
      return;

   if(CountOpenPositions() >= MaxOpenTrades)
      return;

   StrategySignal signal = BuildSignal();
   if(signal.confidence < 65.0)
      return;

   ExecuteSignal(signal);
  }

void OnTradeTransaction(const MqlTradeTransaction &trans,const MqlTradeRequest &request,const MqlTradeResult &result)
  {
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD)
      return;

   if(!HistoryDealSelect(trans.deal))
      return;

   long entry = HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
   if(entry != DEAL_ENTRY_OUT)
      return;

   double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT) +
                   HistoryDealGetDouble(trans.deal, DEAL_SWAP) +
                   HistoryDealGetDouble(trans.deal, DEAL_COMMISSION);

   if(profit < 0)
      g_consecutiveLosses++;
   else if(profit > 0)
      g_consecutiveLosses = 0;
  }

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   if(id != CHARTEVENT_OBJECT_CLICK)
      return;

   if(sparam == PREFIX + "toggle")
      g_tradingEnabled = !g_tradingEnabled;
   else if(sparam == PREFIX + "close")
      CloseAllPositions();
   else if(sparam == PREFIX + "mode")
      CycleStrategyMode();
  }

bool ValidateLicense()
  {
   bool isTester = (bool)MQLInfoInteger(MQL_TESTER) || (bool)MQLInfoInteger(MQL_OPTIMIZATION);

   if(isTester)
     {
      Print("Strategy tester mode detected - skipping live license and connection checks");
      return(true);
     }

   long accountNumber = (long)AccountInfoInteger(ACCOUNT_LOGIN);
   long licensedAccount = LockedAccountNumber > 0 ? LockedAccountNumber : accountNumber;
   string expectedKey = GenerateLicenseKey(licensedAccount, ExpirationDate, BindLicenseToAccount);

   if(LicenseKey == "")
     {
      PrintFormat("Missing license key. Expected key for account %I64d is %s", licensedAccount, expectedKey);
      return(false);
     }

   if(LicenseKey != expectedKey)
     {
      PrintFormat("License key mismatch. Expected key for account %I64d is %s", licensedAccount, expectedKey);
      return(false);
     }

   if(LockedAccountNumber > 0 && accountNumber != LockedAccountNumber)
     {
      Print("Account lock mismatch");
      return(false);
     }

   datetime expiry = StringToTime(ExpirationDate);
   if(expiry > 0 && TimeCurrent() > expiry)
     {
      Print("EA license expired");
      return(false);
     }

   if(RequireConnectedTerminal && !TerminalInfoInteger(TERMINAL_CONNECTED))
     {
      Print("Terminal is offline");
      return(false);
     }

   return(true);
  }

string GenerateLicenseKey(long accountNumber, string expirationDate, bool bindToAccount)
  {
   string normalizedExpiry = NormalizeLicenseExpiry(expirationDate);
   string accountPart = bindToAccount ? StringFormat("%I64d", accountNumber) : "GLOBAL";
   string payload = StringFormat("%s|%s|%s", LicenseSeed, accountPart, normalizedExpiry);
   int checksum = LicenseChecksum(payload);
   return(StringFormat("%s-%s-%03d", LicenseSeed, normalizedExpiry, checksum));
  }

string NormalizeLicenseExpiry(string expirationDate)
  {
   string normalized = expirationDate;
   StringReplace(normalized, ".", "");
   StringReplace(normalized, "-", "");
   StringReplace(normalized, "/", "");
   StringReplace(normalized, " ", "");
   return(normalized);
  }

int LicenseChecksum(string payload)
  {
   int checksum = 0;
   int len = StringLen(payload);

   for(int i = 0; i < len; i++)
      checksum = (checksum * 31 + StringGetCharacter(payload, i)) % 1000;

   return(checksum);
  }

bool IsNewBar()
  {
   datetime current = iTime(_Symbol, SignalTimeframe, 0);
   if(current == 0 || current == g_lastBarTime)
      return(false);
   g_lastBarTime = current;
   return(true);
  }

void ResetDailyMetricsIfNeeded()
  {
   datetime todayBar = iTime(_Symbol, PERIOD_D1, 0);
   if(todayBar != 0 && todayBar != g_lastResetDay)
     {
      g_lastResetDay = todayBar;
      g_dayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      g_consecutiveLosses = 0;
     }
  }

void UpdatePeakEquity()
  {
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity > g_peakEquity)
      g_peakEquity = equity;
  }

bool TradingAllowedByFilters()
  {
   if(EnableEquityProtection && DailyPnLPercent() <= -DailyLossLimitPercent)
      return(false);
   if(EnableEquityProtection && DailyPnLPercent() >= DailyTargetPercent)
      return(false);
   if(CurrentDrawdownPercent() >= MaximumDrawdownPercent)
      return(false);
   if(g_consecutiveLosses >= ConsecutiveLossLimit)
      return(false);
   if(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL) > 0.0 && AccountInfoDouble(ACCOUNT_MARGIN_LEVEL) < MarginLevelFloorPercent)
      return(false);
   if(CurrentSpreadPoints() > MaxSpreadPoints)
      return(false);
   if(!IsSessionAllowed())
      return(false);
   if(UseManualNewsWindows && IsInNewsWindow())
      return(false);
   if(AvoidLowLiquidityMinutes && IsLowLiquidityMinute())
      return(false);
   if(IsAbnormalVolatility())
      return(false);
   if(UseCorrelationFilter && HasCorrelationConflict())
      return(false);
   return(true);
  }

StrategySignal BuildSignal()
  {
   StrategySignal signal;
   signal.buy = false;
   signal.sell = false;
   signal.confidence = 0.0;
   signal.reason = "No signal";

   int trendBias = HigherTimeframeTrendBias();
   if(trendBias == 0)
      return(signal);

   double adx = GetBufferValue(hADX,0,1);
   if(adx < ADXMinimum)
      return(signal);

   double close1 = iClose(_Symbol,SignalTimeframe,1);
   double open1 = iOpen(_Symbol,SignalTimeframe,1);
   bool bullCandle = close1 > open1;
   bool bearCandle = close1 < open1;

   bool trendBuy = EnableTrendFollowing && TrendFollowingBuy();
   bool trendSell = EnableTrendFollowing && TrendFollowingSell();
   bool scalpBuy = EnableScalping && ScalpingBuy();
   bool scalpSell = EnableScalping && ScalpingSell();
   bool breakoutBuy = EnableBreakout && BreakoutBuy();
   bool breakoutSell = EnableBreakout && BreakoutSell();
   bool mrBuy = EnableMeanReversion && MeanReversionBuy();
   bool mrSell = EnableMeanReversion && MeanReversionSell();
   bool smcBuy = EnableSMC && SmartMoneyBuy();
   bool smcSell = EnableSMC && SmartMoneySell();
   bool ictBuy = EnableICT && ICTBuy();
   bool ictSell = EnableICT && ICTSell();

   double buyScore = 0.0;
   double sellScore = 0.0;

   if(trendBias > 0) buyScore += 20.0;
   if(trendBias < 0) sellScore += 20.0;
   if(bullCandle) buyScore += 5.0;
   if(bearCandle) sellScore += 5.0;
   if(trendBuy) buyScore += 16.0;
   if(trendSell) sellScore += 16.0;
   if(scalpBuy) buyScore += 10.0;
   if(scalpSell) sellScore += 10.0;
   if(breakoutBuy) buyScore += 14.0;
   if(breakoutSell) sellScore += 14.0;
   if(mrBuy) buyScore += 9.0;
   if(mrSell) sellScore += 9.0;
   if(smcBuy) buyScore += 12.0;
   if(smcSell) sellScore += 12.0;
   if(ictBuy) buyScore += 12.0;
   if(ictSell) sellScore += 12.0;

   double volumeBoost = VolumeStrength();
   buyScore += volumeBoost;
   sellScore += volumeBoost;

   if(SelectedModeAllowsBuy(buyScore,trendBuy,scalpBuy,breakoutBuy,mrBuy,smcBuy,ictBuy) && buyScore > sellScore && !FakeBreakoutBuy())
     {
      signal.buy = true;
      signal.confidence = buyScore;
      signal.reason = "Buy score alignment";
     }

   if(SelectedModeAllowsSell(sellScore,trendSell,scalpSell,breakoutSell,mrSell,smcSell,ictSell) && sellScore > buyScore && !FakeBreakoutSell())
     {
      signal.buy = false;
      signal.sell = true;
      signal.confidence = sellScore;
      signal.reason = "Sell score alignment";
     }

   return(signal);
  }

bool SelectedModeAllowsBuy(double score,bool trend,bool scalp,bool breakout,bool mr,bool smc,bool ict)
  {
   switch(g_strategyMode)
     {
      case STRATEGY_TREND: return(trend);
      case STRATEGY_SCALPING: return(scalp);
      case STRATEGY_BREAKOUT: return(breakout);
      case STRATEGY_MEAN_REVERSION: return(mr);
      case STRATEGY_SMC: return(smc);
      case STRATEGY_ICT: return(ict);
      case STRATEGY_NEWS_FILTERED: return(!IsInNewsWindow() && score >= 65.0);
      default: return score >= 65.0;
     }
  }

bool SelectedModeAllowsSell(double score,bool trend,bool scalp,bool breakout,bool mr,bool smc,bool ict)
  {
   return SelectedModeAllowsBuy(score,trend,scalp,breakout,mr,smc,ict);
  }

void ExecuteSignal(StrategySignal &signal)
  {
   if(OneTradePerBar && g_lastTradeBar == g_lastBarTime)
      return;

   double atr = GetBufferValue(hATR,0,1);
   if(atr <= 0)
      return;

   double stopDistance = atr * StopLossATRMultiplierX10 / 10.0;
   double takeDistance = atr * TakeProfitATRMultiplierX10 / 10.0;
   double lot = CalculateLotSize(stopDistance);
   if(lot <= 0.0)
      return;

   bool placed = false;
   if(signal.buy)
     {
      double price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double sl = NormalizeDouble(price - stopDistance,_Digits);
      double tp = NormalizeDouble(price + takeDistance,_Digits);
      placed = trade.Buy(lot,_Symbol,price,sl,tp,signal.reason);
     }
   else if(signal.sell)
     {
      double price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
      double sl = NormalizeDouble(price + stopDistance,_Digits);
      double tp = NormalizeDouble(price - takeDistance,_Digits);
      placed = trade.Sell(lot,_Symbol,price,sl,tp,signal.reason);
     }

   if(placed)
     {
      g_lastTradeBar = g_lastBarTime;
      Notify("Trade opened: " + signal.reason + " | Confidence " + DoubleToString(signal.confidence,1));
     }
   else
      Notify("Trade open failed: " + trade.ResultComment());
  }

double CalculateLotSize(double stopDistance)
  {
   double minLot = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(!EnableDynamicLotSizing || stopDistance <= 0.0)
      return(minLot);

   double tickValue = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tickValue <= 0.0 || tickSize <= 0.0)
      return(minLot);

   double riskMoney = AccountInfoDouble(ACCOUNT_BALANCE) * RiskPerTradePercent / 100.0;
   double valuePerPointPerLot = tickValue / tickSize * _Point;
   double stopPoints = stopDistance / _Point;
   if(stopPoints <= 0.0 || valuePerPointPerLot <= 0.0)
      return(minLot);

   double rawLots = riskMoney / (stopPoints * valuePerPointPerLot);
   double rounded = MathFloor(rawLots / step) * step;
   rounded = MathMax(minLot, MathMin(maxLot, rounded));
   return(NormalizeDouble(rounded, 2));
  }

void ManageOpenPositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != (long)MagicNumber)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      double volume = PositionGetDouble(POSITION_VOLUME);
      double currentPrice = (type == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol,SYMBOL_BID) : SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double atr = GetBufferValue(hATR,0,1);
      if(atr <= 0.0)
         continue;

      double riskDistance = MathAbs(openPrice - sl);
      if(riskDistance <= 0.0)
         riskDistance = atr * StopLossATRMultiplierX10 / 10.0;

      double profitDistance = (type == POSITION_TYPE_BUY) ? currentPrice - openPrice : openPrice - currentPrice;
      double rMultiple = profitDistance / riskDistance;

      if(EnableBreakEven && rMultiple >= BreakEvenTriggerR)
        {
         double newSl = openPrice;
         if(type == POSITION_TYPE_BUY && (sl < newSl || sl == 0.0))
            trade.PositionModify(ticket, NormalizeDouble(newSl,_Digits), tp);
         if(type == POSITION_TYPE_SELL && (sl > newSl || sl == 0.0))
            trade.PositionModify(ticket, NormalizeDouble(newSl,_Digits), tp);
        }

      if(EnableTrailingStop)
        {
         double trailDistance = atr * TrailingATRMultiplierX10 / 10.0;
         if(type == POSITION_TYPE_BUY)
           {
            double newSl = NormalizeDouble(currentPrice - trailDistance,_Digits);
            if(newSl > sl && newSl < currentPrice)
               trade.PositionModify(ticket,newSl,tp);
           }
         else
           {
            double newSl = NormalizeDouble(currentPrice + trailDistance,_Digits);
            if((sl == 0.0 || newSl < sl) && newSl > currentPrice)
               trade.PositionModify(ticket,newSl,tp);
           }
        }

      if(EnablePartialProfits && rMultiple >= PartialCloseAtR && volume > SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN))
        {
         double partialLots = NormalizeDouble(volume * PartialClosePercent / 100.0, 2);
         if(partialLots >= SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN) && partialLots < volume)
            trade.PositionClosePartial(ticket, partialLots);
        }
     }
  }

int HigherTimeframeTrendBias()
  {
   double fastH1 = GetMAValueTF(TrendTimeframe,FastEMA,MODE_EMA,1);
   double slowH1 = GetMAValueTF(TrendTimeframe,SlowEMA,MODE_EMA,1);
   double fastH4 = GetMAValueTF(HigherTrendTimeframe,FastEMA,MODE_EMA,1);
   double slowH4 = GetMAValueTF(HigherTrendTimeframe,SlowEMA,MODE_EMA,1);
   if(fastH1 > slowH1 && fastH4 > slowH4)
      return(1);
   if(fastH1 < slowH1 && fastH4 < slowH4)
      return(-1);
   return(0);
  }

bool TrendFollowingBuy()
  {
   double fast = GetBufferValue(hFastEMA,0,1);
   double slow = GetBufferValue(hSlowEMA,0,1);
   double sma = GetBufferValue(hSMA,0,1);
   double close1 = iClose(_Symbol,SignalTimeframe,1);
   return(fast > slow && close1 > sma && MACDMain(1) > MACDSignalValue(1));
  }

bool TrendFollowingSell()
  {
   double fast = GetBufferValue(hFastEMA,0,1);
   double slow = GetBufferValue(hSlowEMA,0,1);
   double sma = GetBufferValue(hSMA,0,1);
   double close1 = iClose(_Symbol,SignalTimeframe,1);
   return(fast < slow && close1 < sma && MACDMain(1) < MACDSignalValue(1));
  }

bool ScalpingBuy()
  {
   double rsi = GetBufferValue(hRSI,0,1);
   double k = GetBufferValue(hStoch,0,1);
   double d = GetBufferValue(hStoch,1,1);
   return(rsi > 50.0 && k > d && k < 80.0);
  }

bool ScalpingSell()
  {
   double rsi = GetBufferValue(hRSI,0,1);
   double k = GetBufferValue(hStoch,0,1);
   double d = GetBufferValue(hStoch,1,1);
   return(rsi < 50.0 && k < d && k > 20.0);
  }

bool BreakoutBuy()
  {
   double highPrev = iHigh(_Symbol,SignalTimeframe,HighestBarIndex(20,true));
   double close1 = iClose(_Symbol,SignalTimeframe,1);
   return(close1 > highPrev && RetestConfirmed(true));
  }

bool BreakoutSell()
  {
   double lowPrev = iLow(_Symbol,SignalTimeframe,HighestBarIndex(20,false));
   double close1 = iClose(_Symbol,SignalTimeframe,1);
   return(close1 < lowPrev && RetestConfirmed(false));
  }

bool MeanReversionBuy()
  {
   double lower = GetBufferValue(hBands,2,1);
   double rsi = GetBufferValue(hRSI,0,1);
   double close1 = iClose(_Symbol,SignalTimeframe,1);
   return(close1 <= lower && rsi <= RSIOversold);
  }

bool MeanReversionSell()
  {
   double upper = GetBufferValue(hBands,1,1);
   double rsi = GetBufferValue(hRSI,0,1);
   double close1 = iClose(_Symbol,SignalTimeframe,1);
   return(close1 >= upper && rsi >= RSIOverbought);
  }

bool SmartMoneyBuy()
  {
   return(LiquiditySweepLow() && DisplacementBullish() && InDiscountZone());
  }

bool SmartMoneySell()
  {
   return(LiquiditySweepHigh() && DisplacementBearish() && InPremiumZone());
  }

bool ICTBuy()
  {
   return(FairValueGapBullish() && OTEBuyZone());
  }

bool ICTSell()
  {
   return(FairValueGapBearish() && OTESellZone());
  }

double VolumeStrength()
  {
   long currentVol = iVolume(_Symbol,SignalTimeframe,1);
   double avg = 0.0;
   for(int i = 2; i < 2 + VolumeLookback; i++)
      avg += (double)iVolume(_Symbol,SignalTimeframe,i);
   avg /= MathMax(1, VolumeLookback);
   if(currentVol > avg * 1.2)
      return(4.0);
   return(0.0);
  }

bool FakeBreakoutBuy()
  {
   double close1 = iClose(_Symbol,SignalTimeframe,1);
   double high2 = iHigh(_Symbol,SignalTimeframe,2);
   return(close1 < high2);
  }

bool FakeBreakoutSell()
  {
   double close1 = iClose(_Symbol,SignalTimeframe,1);
   double low2 = iLow(_Symbol,SignalTimeframe,2);
   return(close1 > low2);
  }

bool RetestConfirmed(bool bullish)
  {
   double close2 = iClose(_Symbol,SignalTimeframe,2);
   double low1 = iLow(_Symbol,SignalTimeframe,1);
   double high1 = iHigh(_Symbol,SignalTimeframe,1);
   return(bullish ? low1 <= close2 : high1 >= close2);
  }

int HighestBarIndex(int lookback,bool highest)
  {
   int index = 1;
   double best = highest ? iHigh(_Symbol,SignalTimeframe,1) : iLow(_Symbol,SignalTimeframe,1);
   for(int i = 2; i <= lookback; i++)
     {
      double v = highest ? iHigh(_Symbol,SignalTimeframe,i) : iLow(_Symbol,SignalTimeframe,i);
      if((highest && v > best) || (!highest && v < best))
        {
         best = v;
         index = i;
        }
     }
   return(index);
  }

bool LiquiditySweepLow()
  {
   return(iLow(_Symbol,SignalTimeframe,1) < iLow(_Symbol,SignalTimeframe,2) &&
          iClose(_Symbol,SignalTimeframe,1) > iLow(_Symbol,SignalTimeframe,2));
  }

bool LiquiditySweepHigh()
  {
   return(iHigh(_Symbol,SignalTimeframe,1) > iHigh(_Symbol,SignalTimeframe,2) &&
          iClose(_Symbol,SignalTimeframe,1) < iHigh(_Symbol,SignalTimeframe,2));
  }

bool DisplacementBullish()
  {
   return((iClose(_Symbol,SignalTimeframe,1) - iOpen(_Symbol,SignalTimeframe,1)) > GetBufferValue(hATR,0,1) * 0.3);
  }

bool DisplacementBearish()
  {
   return((iOpen(_Symbol,SignalTimeframe,1) - iClose(_Symbol,SignalTimeframe,1)) > GetBufferValue(hATR,0,1) * 0.3);
  }

bool InDiscountZone()
  {
   double swingHigh = iHigh(_Symbol,SignalTimeframe,HighestBarIndex(30,true));
   double swingLow = iLow(_Symbol,SignalTimeframe,HighestBarIndex(30,false));
   double mid = swingLow + (swingHigh - swingLow) * 0.5;
   return(iClose(_Symbol,SignalTimeframe,1) < mid);
  }

bool InPremiumZone()
  {
   double swingHigh = iHigh(_Symbol,SignalTimeframe,HighestBarIndex(30,true));
   double swingLow = iLow(_Symbol,SignalTimeframe,HighestBarIndex(30,false));
   double mid = swingLow + (swingHigh - swingLow) * 0.5;
   return(iClose(_Symbol,SignalTimeframe,1) > mid);
  }

bool FairValueGapBullish()
  {
   return(iLow(_Symbol,SignalTimeframe,1) > iHigh(_Symbol,SignalTimeframe,3));
  }

bool FairValueGapBearish()
  {
   return(iHigh(_Symbol,SignalTimeframe,1) < iLow(_Symbol,SignalTimeframe,3));
  }

bool OTEBuyZone()
  {
   double swingHigh = iHigh(_Symbol,SignalTimeframe,HighestBarIndex(20,true));
   double swingLow = iLow(_Symbol,SignalTimeframe,HighestBarIndex(20,false));
   double fib62 = swingHigh - (swingHigh - swingLow) * 0.62;
   double fib79 = swingHigh - (swingHigh - swingLow) * 0.79;
   double price = iClose(_Symbol,SignalTimeframe,1);
   return(price <= fib62 && price >= fib79);
  }

bool OTESellZone()
  {
   double swingHigh = iHigh(_Symbol,SignalTimeframe,HighestBarIndex(20,true));
   double swingLow = iLow(_Symbol,SignalTimeframe,HighestBarIndex(20,false));
   double fib62 = swingLow + (swingHigh - swingLow) * 0.62;
   double fib79 = swingLow + (swingHigh - swingLow) * 0.79;
   double price = iClose(_Symbol,SignalTimeframe,1);
   return(price >= fib62 && price <= fib79);
  }

double MACDMain(int shift)
  {
   return(GetBufferValue(hMACD,0,shift));
  }

double MACDSignalValue(int shift)
  {
   return(GetBufferValue(hMACD,1,shift));
  }

double GetMAValueTF(ENUM_TIMEFRAMES tf,int period,ENUM_MA_METHOD method,int shift)
  {
   int handle = iMA(_Symbol,tf,period,0,method,PRICE_CLOSE);
   if(handle == INVALID_HANDLE)
      return(0.0);
   double value = GetBufferValue(handle,0,shift);
   IndicatorRelease(handle);
   return(value);
  }

double GetBufferValue(int handle,int buffer,int shift)
  {
   double data[];
   if(CopyBuffer(handle,buffer,shift,1,data) <= 0)
      return(0.0);
   return(data[0]);
  }

double CurrentSpreadPoints()
  {
   return((SymbolInfoDouble(_Symbol,SYMBOL_ASK) - SymbolInfoDouble(_Symbol,SYMBOL_BID)) / _Point);
  }

bool IsSessionAllowed()
  {
   MqlDateTime tm;
   TimeToStruct(TimeCurrent(), tm);
   int hour = tm.hour;
   bool asian = TradeAsianSession && hour >= AsianStartHour && hour < AsianEndHour;
   bool london = TradeLondonSession && hour >= LondonStartHour && hour < LondonEndHour;
   bool ny = TradeNewYorkSession && hour >= NewYorkStartHour && hour < NewYorkEndHour;
   return(asian || london || ny);
  }

bool IsLowLiquidityMinute()
  {
   MqlDateTime tm;
   TimeToStruct(TimeCurrent(), tm);
   int minute = tm.min;
   if(LiquidityBlockStartMinute <= LiquidityBlockEndMinute)
      return(minute >= LiquidityBlockStartMinute && minute <= LiquidityBlockEndMinute);
   return(minute >= LiquidityBlockStartMinute || minute <= LiquidityBlockEndMinute);
  }

bool IsInNewsWindow()
  {
   string windows[];
   int total = StringSplit(NewsBlockWindows,';',windows);
   MqlDateTime now;
   TimeToStruct(TimeCurrent(),now);
   int currentMinutes = now.hour * 60 + now.min;
   for(int i = 0; i < total; i++)
     {
      string parts[];
      if(StringSplit(windows[i],'-',parts) != 2)
         continue;
      int startMin = ParseClockToMinutes(parts[0]);
      int endMin = ParseClockToMinutes(parts[1]);
      if(currentMinutes >= startMin && currentMinutes <= endMin)
         return(true);
     }
   return(false);
  }

int ParseClockToMinutes(string hhmm)
  {
   string parts[];
   if(StringSplit(hhmm,':',parts) != 2)
      return(-1);
   return((int)StringToInteger(parts[0]) * 60 + (int)StringToInteger(parts[1]));
  }

bool IsAbnormalVolatility()
  {
   double atrNow = GetBufferValue(hATR,0,1);
   double atrAvg = 0.0;
   for(int i = 2; i < 12; i++)
      atrAvg += GetBufferValue(hATR,0,i);
   atrAvg /= 10.0;
   return(atrAvg > 0.0 && atrNow > atrAvg * ATRVolatilityPauseMultiplier);
  }

bool HasCorrelationConflict()
  {
   string pairs[];
   int total = StringSplit(CorrelationSymbols,',',pairs);
   for(int i = 0; i < total; i++)
     {
      string symbol = StringTrim(pairs[i]);
      if(symbol == "" || symbol == _Symbol)
         continue;
      if(PositionSelect(symbol))
         return(true);
     }
   return(false);
  }

string StringTrim(string text)
  {
   StringTrimLeft(text);
   StringTrimRight(text);
   return(text);
  }

int CountOpenPositions()
  {
   int total = 0;
   for(int i = 0; i < PositionsTotal(); i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetInteger(POSITION_MAGIC) == (long)MagicNumber)
         total++;
     }
   return(total);
  }

void CloseAllPositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != (long)MagicNumber)
         continue;
      trade.PositionClose(ticket);
     }
  }

double DailyPnLPercent()
  {
   if(g_dayStartBalance <= 0.0)
      return(0.0);
   return((AccountInfoDouble(ACCOUNT_BALANCE) - g_dayStartBalance) / g_dayStartBalance * 100.0);
  }

double CurrentDrawdownPercent()
  {
   if(g_peakEquity <= 0.0)
      return(0.0);
   return((g_peakEquity - AccountInfoDouble(ACCOUNT_EQUITY)) / g_peakEquity * 100.0);
  }

void Notify(string message)
  {
   Print(message);
   if(EnablePushNotifications)
      SendNotification(message);
   if(EnableEmailAlerts)
      SendMail("FBOT_MultiStrategy_MT5_v1", message);
   if(EnableTelegramAlerts)
      SendTelegram(message);
  }

void SendTelegram(string message)
  {
   if(TelegramBotToken == "" || TelegramChatId == "")
      return;
   string url = "https://api.telegram.org/bot" + TelegramBotToken + "/sendMessage?chat_id=" + TelegramChatId + "&text=" + message;
   char result[];
   char post[];
   string headers = "";
   ResetLastError();
   WebRequest("GET",url,"","",5000,post,0,result,headers);
  }

string StrategyName()
  {
   switch(g_strategyMode)
     {
      case STRATEGY_TREND: return("Trend");
      case STRATEGY_SCALPING: return("Scalping");
      case STRATEGY_BREAKOUT: return("Breakout");
      case STRATEGY_MEAN_REVERSION: return("MeanRev");
      case STRATEGY_SMC: return("SMC");
      case STRATEGY_ICT: return("ICT");
      case STRATEGY_GRID: return("Grid");
      case STRATEGY_HEDGING: return("Hedging");
      case STRATEGY_NEWS_FILTERED: return("News");
      default: return("Auto");
     }
  }

void CycleStrategyMode()
  {
   int next = (int)g_strategyMode + 1;
   if(next > (int)STRATEGY_NEWS_FILTERED)
      next = 0;
   g_strategyMode = (ENUM_STRATEGY_MODE)next;
  }

void CreateDashboard()
  {
   CreateRectangle(PREFIX + "bg",10,20,280,170,DashboardBg);
   CreateLabel(PREFIX + "title",20,28,"FBOT MultiStrategy MT5 v1",DashboardAccent,11);
   CreateButton(PREFIX + "toggle",20,145,80,22,"Start/Stop");
   CreateButton(PREFIX + "close",110,145,70,22,"Close All");
   CreateButton(PREFIX + "mode",190,145,80,22,"Mode");
  }

void UpdateDashboard()
  {
   string text =
      "Mode: " + StrategyName() +
      "\nTrading: " + (g_tradingEnabled ? "ON" : "OFF") +
      "\nTrend: " + TrendLabel() +
      "\nSpread: " + DoubleToString(CurrentSpreadPoints(),1) +
      "\nOpen Trades: " + IntegerToString(CountOpenPositions()) +
      "\nDaily P/L %: " + DoubleToString(DailyPnLPercent(),2) +
      "\nDrawdown %: " + DoubleToString(CurrentDrawdownPercent(),2) +
      "\nBalance: " + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2) +
      "\nRisk %: " + DoubleToString(RiskPerTradePercent,2) +
      "\nSession: " + (IsSessionAllowed() ? "Open" : "Closed") +
      "\nNews: " + (IsInNewsWindow() ? "Blocked" : "Clear");

   if(ObjectFind(0,PREFIX + "stats") < 0)
      CreateLabel(PREFIX + "stats",20,48,text,DashboardText,9);
   else
      ObjectSetString(0,PREFIX + "stats",OBJPROP_TEXT,text);
  }

void DeleteDashboard()
  {
   ObjectDelete(0,PREFIX + "bg");
   ObjectDelete(0,PREFIX + "title");
   ObjectDelete(0,PREFIX + "toggle");
   ObjectDelete(0,PREFIX + "close");
   ObjectDelete(0,PREFIX + "mode");
   ObjectDelete(0,PREFIX + "stats");
  }

string TrendLabel()
  {
   int bias = HigherTimeframeTrendBias();
   if(bias > 0) return("Bullish");
   if(bias < 0) return("Bearish");
   return("Neutral");
  }

void CreateRectangle(string name,int x,int y,int w,int h,color clr)
  {
   ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
  }

void CreateLabel(string name,int x,int y,string text,color clr,int size)
  {
   ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,size);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetString(0,name,OBJPROP_FONT,"Consolas");
  }

void CreateButton(string name,int x,int y,int w,int h,string text)
  {
   ObjectCreate(0,name,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,name,OBJPROP_COLOR,DashboardText);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,DashboardAccent);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetString(0,name,OBJPROP_FONT,"Consolas");
  }
