//+------------------------------------------------------------------+
//|                                                 goldx_ea.mq5     |
//| Minimal skeleton to demonstrate the GoldX execution flow.        |
//| This EA DOES NOT trade real money; it logs example "intents".    |
//+------------------------------------------------------------------+
#property copyright "OrgaX LLC"
#property link      "https://orgaxtech.com"
#property version   "1.00"
#property strict

input string InpSymbol = "XAUUSD";
input ENUM_TIMEFRAMES InpTF = PERIOD_M5;

double lastClose = 0;

int OnInit()
{
   Print("GoldX EA (skeleton) initialized on ", InpSymbol, " / ", EnumToString(InpTF));
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   Print("GoldX EA deinitialized. reason=", reason);
}

void OnTick()
{
   if(Symbol() != InpSymbol) return;

   MqlRates rates[];
   if(CopyRates(InpSymbol, InpTF, 0, 100, rates) <= 50) return;
   ArraySetAsSeries(rates, true);

   double close = rates[0].close;
   double ma20  = iMA(InpSymbol, InpTF, 20, 0, MODE_EMA, PRICE_CLOSE, 0);
   double ma50  = iMA(InpSymbol, InpTF, 50, 0, MODE_EMA, PRICE_CLOSE, 0);

   string dir = "FLAT";
   if(close > ma20 && ma20 > ma50) dir = "LONG";
   if(close < ma20 && ma20 < ma50) dir = "SHORT";

   // Example "intent" logging (not real trading)
   if(dir != "FLAT" && close != lastClose)
   {
      double atr = iATR(InpSymbol, InpTF, 14, 0);
      double sl  = (dir == "LONG") ? close - 1.5 * atr : close + 1.5 * atr;
      double tp  = (dir == "LONG") ? close + 2.0 * atr : close - 2.0 * atr;
      PrintFormat("[INTENT] %s price=%.2f SL=%.2f TP=%.2f", dir, close, sl, tp);

      // If you want to place real orders, add OrderSend logic here with your risk rules.
      // Make sure algorithmic trading is enabled and you test on demo first.
   }

   lastClose = close;
}

