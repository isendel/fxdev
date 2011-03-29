//+------------------------------------------------------------------+
//|                                            vip_10pips_martin.mq4 |
//|                           Copyright © 2011, Viktor M. Pishchulin |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

//---- input parameters


extern double lotAmplifier = 2;
extern bool debug = false;
extern int magic = 111;

extern double Lots = 2.0;
extern string symbols = "EURUSD,USDJPY,GBPJPY,USDCAD,NZDUSD,AUDUSD,GBPUSD,NZDCHF,EURGBP,EURCHF,USDCHF";
extern string reverseSymbols = "EURUSD";
extern bool reverseEnabled = false;
extern int reverseCount = 2;

bool deletePending = false;
bool hasBuyStop = false;
bool hasSellStop = false;
bool stop = false;
bool isReverseSymbol = false;


extern double orderStopLevel = 0.1;
int start(){
   if(stop) {
      //return(0);
   }
   string currentTradingSymbols[0];
   for(int k = OrdersTotal()-1;k>=0;k--) {
      if(OrderSelect(k, SELECT_BY_POS) == true) {
         if(OrderMagicNumber() == magic && (OrderType()==OP_BUY || OrderType()==OP_SELL)) {
            if(!arrayContainsValue(currentTradingSymbols, OrderSymbol())) {
               ArrayResize(currentTradingSymbols, ArraySize(currentTradingSymbols)+1);
               currentTradingSymbols[ArraySize(currentTradingSymbols)-1] = OrderSymbol();
            }
         }
      }
   }
   
   for(int o=0;o<ArraySize(currentTradingSymbols);o++) {
      startTrade(currentTradingSymbols[o], OP_BUY);
      startTrade(currentTradingSymbols[o], OP_SELL);
   }
 

   string symbolArray[];
   stringExplode(",", symbols, symbolArray);
   for(int i=0;i<ArraySize(symbolArray);i++) {
      trade(symbolArray[i]);   
   }
   
}

int startTrade(string curr, int orderType){
   if(debug) {
      Comment("Start ", curr);
   }
   int ordersNet[0];
   int reverseOrdersNet[0];
   ArrayResize(ordersNet, 0);
   ArrayResize(reverseOrdersNet, 0);
   int total = OrdersTotal();
   deletePending = false;
   for(int k = OrdersTotal()-1;k>=0;k--) {
      if(OrderSelect(k, SELECT_BY_POS) == true) {
         if(OrderSymbol()==curr && OrderMagicNumber() == magic) {
            if(OrderType()==orderType) {
               ArrayResize(ordersNet, ArraySize(ordersNet)+1);
               ordersNet[ArraySize(ordersNet)-1] = OrderTicket();
               deletePending = true;   
            }
            if(OrderType() == getReverseOrderType(orderType)) {
               ArrayResize(reverseOrdersNet, ArraySize(reverseOrdersNet)+1);
               reverseOrdersNet[ArraySize(reverseOrdersNet)-1] = OrderTicket();
            }
         }
      }
   }
   
   isReverseSymbol = false;
   string reverseSymbolsArray[];
   stringExplode(",", reverseSymbols, reverseSymbolsArray);
   for(int i=0;i<ArraySize(reverseSymbolsArray);i++) {
      if(curr == reverseSymbolsArray[i]) {
         isReverseSymbol = true;
      }
   }
   if(ArraySize(ordersNet) > reverseCount && ArraySize(reverseOrdersNet)==0 && isReverseSymbol && reverseEnabled) {
      Print("ArraySize(ordersNet): " + ArraySize(ordersNet));
      Print("ArraySize(reverseOrdersNet): " + ArraySize(reverseOrdersNet));
      if(OrderSelect(getLastNetOrderTicket(ordersNet), SELECT_BY_TICKET)==true) {
         if(OrderType() == OP_BUY) {
            double stopLevel = MarketInfo(OrderSymbol(), MODE_STOPLEVEL) + MarketInfo(OrderSymbol(), MODE_SPREAD);
            double tpSell = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_BID)-MarketInfo(OrderSymbol(), MODE_POINT)*10*mult(OrderSymbol()), MarketInfo(OrderSymbol(), MODE_DIGITS));
            if(OrderSend(curr,OP_SELL,Lots,MarketInfo(OrderSymbol(), MODE_BID),3,NULL,tpSell, "nasos_reverse", magic) == -1) {
               Print("tpSell: " + tpSell);
               Print("BID: " + MarketInfo(OrderSymbol(), MODE_BID));
               Print("stopLevel: " + stopLevel);
               stop=true;
            }
         }
         if(OrderType() == OP_SELL) {
            double tpBuy = NormalizeDouble(MarketInfo(OrderSymbol(), MODE_ASK)+MarketInfo(OrderSymbol(), MODE_POINT)*10*mult(OrderSymbol()), MarketInfo(OrderSymbol(), MODE_DIGITS));
            if(OrderSend(curr,OP_BUY,Lots,MarketInfo(OrderSymbol(), MODE_ASK),3,NULL,tpBuy, "nasos_reverse", magic)==-1) {
               Print("tpBuy: " + tpBuy);
               Print("ASK: " + MarketInfo(OrderSymbol(), MODE_ASK));
               Print("stopLevel: " + stopLevel);
               stop=true;
            }
   
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
               breakeven = (OrderOpenPrice() - MarketInfo(curr, MODE_POINT)*15*mult(OrderSymbol()));
               newTp = OrderOpenPrice() - MarketInfo(curr, MODE_POINT)*5*mult(OrderSymbol());
            } else {
               breakeven = (OrderOpenPrice() + MarketInfo(curr, MODE_POINT)*15*mult(OrderSymbol()));
               newTp = OrderOpenPrice() + MarketInfo(curr, MODE_POINT)*5*mult(OrderSymbol());
            }
            newPrice = (lotSum * breakeven - prevLotPrices)/ordersNetLotNew;

            if(OrderType()==OP_BUY && MarketInfo(curr, MODE_ASK)<=newPrice) {
               if(OrderSend(OrderSymbol(),OrderType(),ordersNetLotNew,MarketInfo(curr, MODE_ASK),3,NULL,
               newTp, "nasos_martin", magic) == -1){
                  Print("Error");
                  stop = true;
               } else {
                  modifyOrdersTP(newTp, curr);
               }
            }
            if(debug){
               Print("newPrice: " + newPrice + ", breakeven: " + breakeven + ", newTp: " + newTp + ", ordersNetLotNew: " + ordersNetLotNew);
            }
            if(OrderType()==OP_SELL && MarketInfo(curr, MODE_BID)>=newPrice) {
               if(OrderSend(OrderSymbol(),OrderType(),ordersNetLotNew,MarketInfo(curr, MODE_BID),3,NULL,
               newTp, "nasos_martin", magic)==-1){
                  Print("Error");
                  stop = true;
               } else {
                  modifyOrdersTP(newTp, curr);
               }
            }
         } else {
            Print("Failed fint order by ticket: " + ordersNet[netSize-1]);
         }
         return(0);
      } else {
         return(0);
      }
   }
  

//----
   return(0);
  }
//+------------------------------------------------------------------+

int getReverseOrderType(int orderType) {
   if(orderType == OP_SELL){
      return (OP_BUY);
   } else if(orderType == OP_BUY){
      return (OP_SELL);
   } else {
      return(-1);
   }
   
}

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
   for(int k = OrdersTotal()-1;k>=0;k--) {
      if(OrderSelect(k, SELECT_BY_POS) == true) {
         if(OrderSymbol()==curr && OrderMagicNumber() == magic && (OrderType()==OP_SELL || OrderType() == OP_BUY)) {
            return;
         }
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

   double lastDayHight = NormalizeDouble(iHigh(curr,PERIOD_D1,1), MarketInfo(curr, MODE_DIGITS));
   double lastDayLow = NormalizeDouble(iLow(curr,PERIOD_D1,1), MarketInfo(curr, MODE_DIGITS));
   //Print(curr + " lastDayHight: " + lastDayHight);
   //Print(curr + " lastDayLow: " + lastDayLow);
   double tp;
   double stopLevel = MarketInfo(curr,MODE_STOPLEVEL);
   if(MarketInfo(curr, MODE_ASK) < lastDayHight && MathAbs(lastDayHight-MarketInfo(curr, MODE_ASK))>(lastDayHight-lastDayLow)*orderStopLevel  && !hasBuyStop) {
   //if(MarketInfo(curr, MODE_ASK) < lastDayHight && !hasBuyStop) {
      tp = NormalizeDouble(lastDayHight+MarketInfo(curr, MODE_POINT)*10*mult(curr), MarketInfo(curr, MODE_DIGITS));
      if(OrderSend(curr,OP_BUYSTOP,Lots,lastDayHight,3,NULL,tp, "vip_10pips_martin", magic, iTime( curr, PERIOD_D1, 0 ) + 86400) == -1){
         Print(curr + " buy error: " + GetLastError());
         Print(curr + " STOPLEVEL: " + stopLevel);
         Print(curr + " tp: " + tp);
         Print(curr + " MarketInfo(curr, MODE_DIGITS) " + MarketInfo(curr, MODE_DIGITS));
         Print(curr + " MarketInfo(curr, MODE_POINT) " + MarketInfo(curr, MODE_POINT));
         Print(curr + " lastDayHight: " + lastDayHight);
         Print(curr + " lastDayLow: " + lastDayLow);
      }
   }

   if(MarketInfo(curr, MODE_BID) > lastDayLow && MathAbs(lastDayLow-MarketInfo(curr, MODE_BID))>(lastDayLow-lastDayLow)*orderStopLevel && !hasSellStop) {
   //if(MarketInfo(curr, MODE_BID) > lastDayLow && !hasSellStop) {
      tp = NormalizeDouble(lastDayLow-MarketInfo(curr, MODE_POINT)*10*mult(curr), MarketInfo(curr, MODE_DIGITS));
      if(OrderSend(curr,OP_SELLSTOP,Lots,lastDayLow,3,NULL,tp, "vip_10pips_martin", magic, iTime( curr, PERIOD_D1, 0 ) + 86400) == -1){
         Print(curr + " buy error: " + GetLastError());
         Print(curr + " STOPLEVEL: " + stopLevel);
         Print(curr + " tp: " + tp);
         Print(curr + " MarketInfo(curr, MODE_DIGITS) " + MarketInfo(curr, MODE_DIGITS));
         Print(curr + " MarketInfo(curr, MODE_POINT) " + MarketInfo(curr, MODE_POINT));
         Print(curr + " lastDayHight: " + lastDayHight);
         Print(curr + " lastDayLow: " + lastDayLow);
      }
   } 
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

bool arrayContainsValue(string array[], string value) {
   for(int o=0;o<ArraySize(array);o++) {
      if(array[o]==value) {
         return(true);
      }
   }
   return(false);
}