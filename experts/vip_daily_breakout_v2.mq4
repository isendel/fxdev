//+------------------------------------------------------------------+
//|                                        vip_daily_breakout_v1.mq4 |
//|                           Copyright © 2011, Viktor M. Pishchulin |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, Viktor M. Pishchulin"
#property link      "http://www.metaquotes.net"


extern double Lots = 0.2;
int magic = 12;
int magicStop = 21;
double stopLoss = 30;
double takeProfit = 25;
double firstTP = 10;
bool stop = false;
bool deletePending = false;


int start(){
   if(stop) {
      return(0);
   }
   int ordersNet[0];
   ArrayResize(ordersNet, 0);
   int total = OrdersTotal();
   deletePending = false;
   for(int j = OrdersTotal()-1;j>=0;j--) {
      if(OrderSelect(j, SELECT_BY_POS) == true) {
         if(OrderMagicNumber() == magic && (OrderType()==OP_BUY || OrderType()==OP_SELL)) {
            ArrayResize(ordersNet, ArraySize(ordersNet)+1);
            ordersNet[ArraySize(ordersNet)-1] = OrderTicket();
            deletePending = true;   
         }
      }
   }
   
   if(deletePending) {
      deletePendingOrders(magic);
   }
  
   for(int k = 0;k<ArraySize(ordersNet);k++) {
      if(OrderSelect(ordersNet[k], SELECT_BY_TICKET)==true) {
         if(OrderMagicNumber() == magic) {
            string curr = OrderSymbol();
            if(OrderType()==OP_BUY) {
               if(Bid - OrderOpenPrice()>firstTP*Point*mult(OrderSymbol())){
                  if(OrderStopLoss() != OrderOpenPrice()){
                     OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,Blue);
                     
                  }
                  if(OrderLots()==Lots && OrderMagicNumber() == magic) {
                     OrderClose(OrderTicket(), NormalizeDouble(Lots/2,Digits), Bid, 3, Red);
                  } 
               }
            }
            if(OrderType()==OP_SELL) {
               if(OrderOpenPrice()-Ask>firstTP*Point*mult(OrderSymbol())){
                  if(OrderStopLoss() != OrderOpenPrice()){
                     OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,Blue);
                  }
                  if(OrderLots()==Lots && OrderMagicNumber() == magic) {
                     OrderClose(OrderTicket(), NormalizeDouble(Lots/2,Digits), Ask, 3, Red);
                  }
               }
            }
            return(0);
         }
      }
   }
   trade(Symbol());
//----
   return(0);
  }
//+------------------------------------------------------------------+

int deletePendingOrders(int Magic) {      
  int total  = OrdersTotal();
  for (int i=total-1; i >=0; i--){
    OrderSelect(i,SELECT_BY_POS,MODE_TRADES);     
    if (OrderMagicNumber()==Magic && OrderSymbol()==Symbol() && (OrderType()==OP_BUYSTOP || OrderType()==OP_SELLSTOP)){
      OrderDelete(OrderTicket());
    }
  }

  return(0);
}

void trade(string curr) {
   int historyTotal = HistoryTotal();
   if (OrderSelect(historyTotal -1, SELECT_BY_POS, MODE_HISTORY)) {
      int c_time = CurTime();   
      datetime day_start;
      day_start=c_time-TimeHour(c_time)*60*60-TimeMinute(c_time)*60-TimeSeconds(c_time);
      if ((OrderOpenTime()>=day_start || Hour()<=3)&&OrderMagicNumber()==magic) {
         return;
      }
   }
   int total = OrdersTotal();
   for(int j = OrdersTotal()-1;j>=0;j--) {
      if(OrderSelect(j, SELECT_BY_POS) == true) {
         if(OrderMagicNumber() == magic && (OrderType()== OP_BUYSTOP || OrderType()==OP_SELLSTOP)) {
            return;
         }
      }
   }

   double lastDayHight = iHigh(curr,PERIOD_D1,1);
   double lastDayLow = iLow(curr,PERIOD_D1,1);
   
   if(Ask < lastDayHight) {
      drawLastDayRect(curr, lastDayHight, lastDayLow);
      OrderSend(curr,OP_BUYSTOP,Lots,lastDayHight,3,lastDayHight-Point*stopLoss*mult(curr),lastDayHight+Point*takeProfit*mult(curr), NULL, magic, iTime( curr, PERIOD_D1, 0 ) + 86400, Green);
      Print(GetLastError());
   }

   if(Bid > lastDayLow) {
      drawLastDayRect(curr, lastDayHight, lastDayLow);
      OrderSend(curr,OP_SELLSTOP,Lots,lastDayLow,3,lastDayLow+Point*stopLoss*mult(curr),lastDayLow-Point*takeProfit*mult(curr), NULL, magic, iTime( curr, PERIOD_D1, 0 ) + 86400, Red);
      Print(GetLastError());
   } 
}

void drawLastDayRect(string curr, double lastDayHight, double lastDayLow){
   string time = iTime(curr,PERIOD_M1,0);
   string labelRect = curr + "_lastDay_" + time;
   ObjectCreate(labelRect, OBJ_RECTANGLE, 0, iTime(curr,PERIOD_D1,1), lastDayHight, iTime(curr,PERIOD_D1,0), lastDayLow);
   ObjectSet(labelRect, OBJPROP_STYLE, STYLE_DASHDOTDOT);
   ObjectSet(labelRect, OBJPROP_COLOR, MidnightBlue);
   ObjectSet(labelRect, OBJPROP_WIDTH, 4);
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

