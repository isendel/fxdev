//+------------------------------------------------------------------+
//|                                      vip_EURUSD_Trend_System.mq4 |
//|                      Copyright © 2011, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

extern int magic = 333;
extern double breakaven = 50;
extern double Lots = 1.0;

int start() {
   double ma = iMA(NULL,PERIOD_H4,25,0,MODE_EMA,PRICE_CLOSE,1);
   double high = iHigh(NULL, PERIOD_H4, 1);
   double low = iLow(NULL, PERIOD_H4, 1);
   double open = iOpen(NULL, PERIOD_H4, 1);
   double close = iClose(NULL, PERIOD_H4, 1);
   double stopLoss;
   for(int k = OrdersTotal()-1;k>=0;k--) {
      if(OrderSelect(k, SELECT_BY_POS) == true) {
         if(OrderMagicNumber() == magic) {
            if(OrderType()==OP_BUY) {
               if(Ask - OrderOpenPrice()>breakaven*Point*mult(Symbol()) 
                     && OrderStopLoss()<Ask-breakaven*Point*mult(Symbol())) {
                  OrderModify(OrderTicket(),OrderOpenPrice(), Ask-breakaven*Point*mult(Symbol()),OrderTakeProfit(),0,Blue);
               }
            }
            if(OrderType()==OP_SELL) {
               if(OrderOpenPrice() - Bid>breakaven*Point*mult(Symbol()) 
                     && OrderStopLoss()>Bid+breakaven*Point*mult(Symbol())) {
                  OrderModify(OrderTicket(),OrderOpenPrice(), Bid+breakaven*Point*mult(Symbol()),OrderTakeProfit(),0,Blue);
               }
            }
            return(0);
         }
      }
   }
   if(open < ma && close > ma) {
      if(high-low<30*Point*mult(Symbol())) {
         stopLoss = high-29*Point*mult(Symbol());
      } else {
         stopLoss = low;
      }
      
      OrderSend(Symbol(),OP_BUYSTOP,Lots,high+1*Point*mult(Symbol()),3,stopLoss,NULL, "vip_balance_line", magic, iTime( Symbol(), PERIOD_D1, 0 ) + 86400, Green);
   }
   if(open > ma && close < ma) {
      if(high-low<30*Point*mult(Symbol())) {
         stopLoss = low+29*Point*mult(Symbol());
      } else {
         stopLoss = high;
      }
      
      OrderSend(Symbol(),OP_SELLSTOP,Lots,low-1*Point*mult(Symbol()),3,stopLoss,NULL, "vip_balance_line", magic, iTime( Symbol(), PERIOD_D1, 0 ) + 86400, Red);
   }
   
   return(0);
}
  
int mult(string symb){
   int x = 1;
   switch (MarketInfo(symb,MODE_DIGITS))       
    {
     case 2:    x=1;  break;
     case 4:    x=1;  break;
     case 3:    x=10; break;
     case 5:    x=10; break;
     default  : x=1; 
    }
   return(x);
}



