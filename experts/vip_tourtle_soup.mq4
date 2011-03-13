//+------------------------------------------------------------------+
//|                                             vip_tourtle_soup.mq4 |
//|                      Copyright © 2011, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

extern int magic = 222;

extern double Lots = 1.0;
extern double breakaven = 50;
int prevDayDraw = 0;
int lastDayDraw = 0;

int start() {
   int highestBar = iHighest(Symbol(), Period(), MODE_HIGH, 19, 1);
   int lowestBar = iLowest(Symbol(), Period(), MODE_LOW, 19, 1);
   double high = iHigh(Symbol(), Period(), highestBar);
   double low = iLow(Symbol(), Period(), lowestBar);
   //double stopLoss = getHighestBarSize(19);
   double stopLoss = getHighestBarSize(19);
   for(int k = OrdersTotal()-1;k>=0;k--) {
      if(OrderSelect(k, SELECT_BY_POS) == true) {
         if(OrderMagicNumber() == magic) {
            if(OrderType()==OP_BUY) {
               if(OrderStopLoss()==NULL) {
                  OrderModify(OrderTicket(),OrderOpenPrice(),iLow(Symbol(), Period(), 0) - 5*Point*mult(Symbol()),OrderTakeProfit(),0,Blue);
               }
               if(iMACD(Symbol(),0,12,26,9,PRICE_CLOSE,MODE_MAIN,0)<iMACD(Symbol(),0,12,26,9,PRICE_CLOSE,MODE_SIGNAL,0)) {
                  OrderClose(OrderTicket(), OrderLots(), Bid,3,Green);
               }
               /*if(Ask - OrderOpenPrice()>breakaven*Point*mult(Symbol()) 
                     && OrderStopLoss()<Ask-breakaven*Point*mult(Symbol())) {
                  OrderModify(OrderTicket(),OrderOpenPrice(), Ask-breakaven*Point*mult(Symbol()),OrderTakeProfit(),0,Blue);
               }*/ 
            }
            if(OrderType()==OP_SELL) {
               if(OrderStopLoss()==NULL) {
                  OrderModify(OrderTicket(),OrderOpenPrice(),iHigh(Symbol(), Period(), 0) + 5*Point*mult(Symbol()),OrderTakeProfit(),0,Blue);
               }
               if(iMACD(Symbol(),0,12,26,9,PRICE_CLOSE,MODE_MAIN,0)>iMACD(Symbol(),0,12,26,9,PRICE_CLOSE,MODE_SIGNAL,0)) {
                  OrderClose(OrderTicket(), OrderLots(), Ask,3,Red);
               }

               /*if(OrderOpenPrice() - Bid>breakaven*Point*mult(Symbol()) 
                     && OrderStopLoss()>Bid+breakaven*Point*mult(Symbol())) {
                  OrderModify(OrderTicket(),OrderOpenPrice(), Bid+breakaven*Point*mult(Symbol()),OrderTakeProfit(),0,Blue);
               }*/
            
            }
            return(0);
         }
      }
   }

   
   if(lastDayDraw != DayOfYear()) {
      int startTime = iTime(Symbol(), Period(), 20);
      int endTime = iTime(Symbol(), Period(), 1);
      prevDayDraw = lastDayDraw;
      lastDayDraw = DayOfYear();
      ObjectDelete("20daysBox_" + prevDayDraw);
      ObjectCreate("20daysBox_" + lastDayDraw, OBJ_RECTANGLE, 0,
                        startTime, low, endTime, high);
      ObjectSet("20daysBox_" + lastDayDraw, OBJPROP_SCALE, 1.0);
      ObjectSet("20daysBox_" + lastDayDraw, OBJPROP_COLOR, Green);
   }
   //Print("highestBar: " + highestBar + ", lowestBar: " + lowestBar);
   if(Bid > high && highestBar >= 4) {
      OrderSend(Symbol(),OP_SELLSTOP,Lots,high-10*Point*mult(Symbol()),3,NULL,NULL, "vip_turtle_soup", magic, iTime( Symbol(), Period(), 0 ) + 86400, Red);
   }
   if(Ask < low && lowestBar >= 4) {
      OrderSend(Symbol(),OP_BUYSTOP,Lots,low+10*Point*mult(Symbol()),3,NULL,NULL, "vip_turtle_soup", magic, iTime( Symbol(), Period(), 0 ) + 86400, Green);
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

double getHighestBarSize(int period) {
   double highestSize = 0;
   for(int i=0;i<=period;i++) {
      double size = iHigh(Symbol(), Period(), i) - iLow(Symbol(), Period(), i);
      if(size>highestSize) {
         highestSize = size;
      }
   }
   return(highestSize);
}