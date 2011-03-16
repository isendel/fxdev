//+------------------------------------------------------------------+
//|                                                         test.mq4 |
//|                                     Copyright © 2010, ENSED Team |
//|                                             http://www.ensed.org |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2010, ENSED Team"
#property link      "http://www.ensed.org"

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
  {
//----
    double BUY_STOP_Price  = iHigh(NULL,PERIOD_M1,iHighest(NULL,PERIOD_M1,MODE_HIGH,240,0));
    double SELL_STOP_Price = iLow(NULL,PERIOD_M1,iLowest(NULL,PERIOD_M1,MODE_LOW,240,0));
   Comment(MarketInfo(Symbol(),MODE_STOPLEVEL)," ",BUY_STOP_Price," ",SELL_STOP_Price," ",(BUY_STOP_Price-SELL_STOP_Price)/Point);
//----
   return(0);
  }
//+------------------------------------------------------------------+