//+------------------------------------------------------------------+
//|                                            vip_10pips_martin.mq4 |
//|                           Copyright © 2011, Viktor M. Pishchulin |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

//---- input parameters

//---- input parameters
extern bool AccountIsMini=true;         // Change to true if trading mini account
extern bool MoneyManagement=true;       // Change to false to shutdown money management controls.
extern bool UseTrailingStop=true;
//----                                  // Lots = 1 will be in effect and only 1 lot will be open regardless of equity.
extern double TradeSizePercent  = 10;   // Change to whatever percent of equity you wish to risk.
extern double MaxLots=4;

extern double lotAmplifier = 2;
int magic = 111;

extern double Lots = 0.2;

bool deletePending = false;

int start(){
   int ordersNet[0];
   ArrayResize(ordersNet, 0);
   int total = OrdersTotal();
   deletePending = false;
   for(int k = OrdersTotal()-1;k>=0;k--) {
      if(OrderSelect(k, SELECT_BY_POS) == true) {
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

   
   if(ArraySize(ordersNet) != 0) {
      int netSize = 9;
      int size = ArraySize(ordersNet);
      ArraySort(ordersNet);
      if(ArraySize(ordersNet) <= netSize) {
         if(OrderSelect(getLastNetOrderTicket(ordersNet), SELECT_BY_TICKET)==true) {
            double newTp,newPrice,breakeven;
            double ordersNetLotNew = Lots;
            for(int o=0;o<size;o++) {
               ordersNetLotNew = ordersNetLotNew*lotAmplifier;
            }
            double prevLotPrices = getPrevLotPrices(ordersNet);
            double lotSum = getLotSum(ordersNet, ordersNetLotNew);
            if(OrderType()==OP_BUY) {
               breakeven = (OrderOpenPrice() - Point*15*mult(OrderSymbol()));
               newTp = OrderOpenPrice() - Point*5*mult(OrderSymbol());
            } else {
               breakeven = (OrderOpenPrice() + Point*15*mult(OrderSymbol()));
               newTp = OrderOpenPrice() + Point*5*mult(OrderSymbol());
            }
            newPrice = (lotSum * breakeven - prevLotPrices)/ordersNetLotNew;

            if(OrderType()==OP_BUY && Ask<=newPrice) {
               OrderSend(OrderSymbol(),OrderType(),ordersNetLotNew,Ask,3,NULL,
               newTp, NULL, magic);
               modifyOrdersTP(newTp);
            }
            if(OrderType()==OP_SELL && Bid>=newPrice) {
               OrderSend(OrderSymbol(),OrderType(),ordersNetLotNew,Bid,3,NULL,
               newTp, NULL, magic);
               modifyOrdersTP(newTp);
            }
         } else {
            Print("Failed fint order by ticket: " + ordersNet[netSize-1]);
         }
         return(0);
      } else {
         return(0);
      }
   }
  
   ArrayResize(ordersNet, 0);
   
   trade("EURUSD");
   trade("USDJPY");
   trade("USDCAD");
   trade("NZDUSD");
   //trade("GBPJPY");
   //trade("CHFJPY");
   trade("AUDUSD");
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
      OrderSend(curr,OP_BUYSTOP,Lots,lastDayHight,3,NULL,lastDayHight+Point*10*mult(curr), NULL, magic, iTime( curr, PERIOD_D1, 0 ) + 86400, Green);
      Print(GetLastError());
   }

   if(Bid > lastDayLow) {
      drawLastDayRect(curr, lastDayHight, lastDayLow);
      OrderSend(curr,OP_SELLSTOP,Lots,lastDayLow,3,NULL,lastDayLow-Point*10*mult(curr), NULL, magic, iTime( curr, PERIOD_D1, 0 ) + 86400, Red);
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

int getLastNetOrderTicket(int orders[]) {
   return (orders[ArraySize(orders)-1]);
}

void modifyOrdersTP(double newTP) {
   int total = OrdersTotal();
   for(int k = OrdersTotal()-1;k>=0;k--) {
      if(OrderSelect(k, SELECT_BY_POS) == true) {
         if(OrderMagicNumber() == magic) {
            OrderModify(OrderTicket(),OrderOpenPrice(),NULL,newTP,0,Blue);
         }
      }
   }
}

double getLotSum(int orders[], double newLot) {
   double lotSum = 0;
   for(int o=0;o<ArraySize(orders);o++) {
      if(OrderSelect(orders[o], SELECT_BY_TICKET)==true) {
         lotSum=lotSum+OrderLots();
      }
   }
   return (lotSum + newLot);
}

double getPrevLotPrices(int orders[]) {
   double prevLotPrices = 0;
   //for(int o = ArraySize(orders)-1;o>=0;o--) {
   for(int o=0;o<ArraySize(orders);o++) {
      if(OrderSelect(orders[o], SELECT_BY_TICKET)==true) {
         if(prevLotPrices == 0) {
            prevLotPrices=OrderOpenPrice()*OrderLots();
         } else {
            prevLotPrices+=OrderOpenPrice()*OrderLots();
         }
         
      }
      
   }
   return (prevLotPrices);
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


