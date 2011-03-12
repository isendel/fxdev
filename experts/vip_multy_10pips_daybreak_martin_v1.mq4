//+------------------------------------------------------------------+
//|                                            vip_10pips_martin.mq4 |
//|                           Copyright © 2011, Viktor M. Pishchulin |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

//---- input parameters

//---- input parameters
//extern bool MoneyManagement=true;       // Change to false to shutdown money management controls.
//----                                  // Lots = 1 will be in effect and only 1 lot will be open regardless of equity.
extern double TradeSizePercent  = 10;   // Change to whatever percent of equity you wish to risk.
extern double MaxLots=4;

extern double lotAmplifier = 2;
extern bool debug = false;
extern int magic = 222;

extern double Lots = 2.0;
extern string symbols = "EURUSD,USDJPY,GBPJPY,USDCAD,NZDUSD,AUDUSD,GBPUSD";

bool deletePending = false;
bool hasBuyStop = false;
bool hasSellStop = false;

int start(){
   string symbolArray[];
   stringExplode(",", symbols, symbolArray);
   for(int i=0;i<ArraySize(symbolArray);i++) {
      startTrade(symbolArray[i]);
   }
   //startTrade(Symbol());
   /*startTrade("EURUSD");
   startTrade("USDJPY");
   startTrade("GBPJPY");
   startTrade("USDCAD");
   startTrade("NZDUSD");
   startTrade("AUDUSD");*/
}

int startTrade(string curr){
   if(debug) {
      Comment("Start ", curr);
   }
   int ordersNet[0];
   ArrayResize(ordersNet, 0);
   int total = OrdersTotal();
   deletePending = false;
   for(int k = OrdersTotal()-1;k>=0;k--) {
      if(OrderSelect(k, SELECT_BY_POS) == true) {
         if(OrderSymbol()==curr && OrderMagicNumber() == magic && (OrderType()==OP_BUY || OrderType()==OP_SELL)) {
            ArrayResize(ordersNet, ArraySize(ordersNet)+1);
            ordersNet[ArraySize(ordersNet)-1] = OrderTicket();
            deletePending = true;   
         }
      }
   }
   
   if(deletePending) {
      deletePendingOrders(magic, curr);
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
               newTp, "vip_10pips_martin", magic, iTime( OrderSymbol(), PERIOD_D1, 0 ) + 86400, Green);
               modifyOrdersTP(newTp, curr);
            }
            if(debug){
               Print("newPrice: " + newPrice + ", breakeven: " + breakeven + ", newTp: " + newTp + ", ordersNetLotNew: " + ordersNetLotNew);
            }
            if(OrderType()==OP_SELL && Bid>=newPrice) {
               OrderSend(OrderSymbol(),OrderType(),ordersNetLotNew,Bid,3,NULL,
               newTp, "vip_10pips_martin", magic, iTime( OrderSymbol(), PERIOD_D1, 0 ) + 86400, Red);
               modifyOrdersTP(newTp, curr);
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
   
   trade(curr);
//----
   return(0);
  }
//+------------------------------------------------------------------+

int deletePendingOrders(int Magic, string curr) {      
  int total  = OrdersTotal();
  for (int i=total-1; i >=0; i--){
    OrderSelect(i,SELECT_BY_POS,MODE_TRADES);     
    if (OrderMagicNumber()==Magic && OrderSymbol()==curr && (OrderType()==OP_BUYSTOP || OrderType()==OP_SELLSTOP)){
      OrderDelete(OrderTicket());
    }
  }

  return(0);
}

void trade(string curr) {
   if(debug) {
      Print("Trading " + curr + " symbol.");
   }
   int historyTotal = HistoryTotal();
   if (OrderSelect(historyTotal -1, SELECT_BY_POS, MODE_HISTORY)) {
      int c_time = CurTime();   
      datetime day_start;
      day_start=c_time-TimeHour(c_time)*60*60-TimeMinute(c_time)*60-TimeSeconds(c_time);
      if (Hour()<=3) {
         return;
      }
   }
   hasBuyStop = false;
   hasSellStop = false;
   int total = OrdersTotal();
   for(int j = OrdersTotal()-1;j>=0;j--) {
      if(OrderSelect(j, SELECT_BY_POS) == true) {
         if(OrderSymbol()==curr && OrderMagicNumber() == magic && (OrderType()== OP_BUYSTOP || OrderType()==OP_SELLSTOP)) {
            if(OrderType()== OP_BUYSTOP) {
               if(debug) {
                  Print(curr + " hasBuyStop");
               }
               hasBuyStop = true;
            }
            if(OrderType()== OP_SELLSTOP) {
               if(debug) {
                  Print(curr + " hasSellStop");
               }
               hasSellStop = true;
            }
         }
      }
   }

   double lastDayHight = iHigh(curr,PERIOD_D1,1);
   double lastDayLow = iLow(curr,PERIOD_D1,1);
   if(Ask < lastDayHight && MathAbs(lastDayHight-Ask)>(lastDayHight-lastDayLow)*0.2  && !hasBuyStop) {
      drawLastDayRect(curr, lastDayHight, lastDayLow);
      OrderSend(curr,OP_BUYSTOP,Lots,lastDayHight,3,NULL,lastDayHight+Point*10*mult(curr), "vip_10pips_martin", magic, iTime( curr, PERIOD_D1, 0 ) + 86400, Green);
      Print(GetLastError());
   }

   if(Bid > lastDayLow && MathAbs(lastDayLow-Bid)>(lastDayLow-lastDayLow)*0.2 && !hasSellStop) {
      drawLastDayRect(curr, lastDayHight, lastDayLow);
      OrderSend(curr,OP_SELLSTOP,Lots,lastDayLow,3,NULL,lastDayLow-Point*10*mult(curr), "vip_10pips_martin", magic, iTime( curr, PERIOD_D1, 0 ) + 86400, Red);
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

void modifyOrdersTP(double newTP, string curr) {
   int total = OrdersTotal();
   for(int k = OrdersTotal()-1;k>=0;k--) {
      if(OrderSelect(k, SELECT_BY_POS) == true) {
         if(OrderMagicNumber() == magic && OrderSymbol()==curr && (OrderType()==OP_BUY || OrderType()==OP_SELL)) {
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


void stringExplode(string sDelimiter, string sExplode, string &sReturn[]){
   
   int ilBegin = -1,ilEnd = 0;
   int ilElement=0;
   while (ilEnd != -1){
      ilEnd = StringFind(sExplode, sDelimiter, ilBegin+1);
      ArrayResize(sReturn,ilElement+1);
      sReturn[ilElement] = "";     
      if (ilEnd == -1){
         if (ilBegin+1 != StringLen(sExplode)){
            sReturn[ilElement] = StringSubstr(sExplode, ilBegin+1, StringLen(sExplode));
         }
      } else { 
         if (ilBegin+1 != ilEnd){
            sReturn[ilElement] = StringSubstr(sExplode, ilBegin+1, ilEnd-ilBegin-1);
         }
      }      
      ilBegin = StringFind(sExplode, sDelimiter,ilEnd);  
      ilElement++;    
   }
}