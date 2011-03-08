//+------------------------------------------------------------------+
//|                                                vip_return_v1.mq4 |
//|                           Copyright © 2011, Viktor M. Pishchulin |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, Viktor M. Pishchulin"
#property link      "http://www.metaquotes.net"

extern int magic = 222333;
extern double Lots = 0.1;
int stopLevel;
bool pendingActive;
bool stop = false;
int init(){
   stopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) + MarketInfo(Symbol(), MODE_SPREAD);
}

int start(){
   if(stop) {
      return(0);
   }
   if(DayOfWeek()==5) {  
      return(0);
   }
   string curr = Symbol();
   //Print("Hour(): " + Hour());
   if(Hour()==23) {
      deletePendingOrders(magic);
   }
   int total  = OrdersTotal();
   int ordersNet[0];
   pendingActive = false;
   for (int i=total-1; i >=0; i--){
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);     
       if (OrderMagicNumber()==magic && OrderSymbol()==Symbol()){
         if((OrderType()==OP_BUYLIMIT || OrderType()==OP_SELLLIMIT)) {
            pendingActive = true;
         }
         if((OrderType()==OP_BUY || OrderType()==OP_SELL)) {
            ArrayResize(ordersNet, ArraySize(ordersNet)+1);
            ordersNet[ArraySize(ordersNet)-1] = OrderTicket();
         }
       }
   }
   if(ArraySize(ordersNet) > 1) {
      double prevLotPrices = getPrevLotPrices(ordersNet);
      double breakeven = prevLotPrices/4 + 25/ArraySize(ordersNet);
      modifyOrdersTP(breakeven);
      
   }
   
   if(pendingActive) {
      return(0);
   }
 
   
   if(Hour()==20) {
      double openPrice = iOpen("EURUSD", PERIOD_H1, 0);

      OrderSend(curr,OP_SELLLIMIT,Lots,openPrice+25*Point*mult(curr),3,openPrice+25*Point*mult(curr) + 130*Point*mult(curr),openPrice, NULL, magic);
      OrderSend(curr,OP_SELLLIMIT,Lots,openPrice+30*Point*mult(curr),3,openPrice+30*Point*mult(curr) + 130*Point*mult(curr),openPrice, NULL, magic);
      OrderSend(curr,OP_SELLLIMIT,Lots,openPrice+35*Point*mult(curr),3,openPrice+35*Point*mult(curr) + 130*Point*mult(curr),openPrice, NULL, magic);
      OrderSend(curr,OP_SELLLIMIT,Lots,openPrice+40*Point*mult(curr),3,openPrice+40*Point*mult(curr) + 130*Point*mult(curr),openPrice, NULL, magic);
      
      OrderSend(curr,OP_BUYLIMIT,Lots,openPrice-25*Point*mult(curr),3,openPrice-25*Point*mult(curr) - 130*Point*mult(curr),openPrice, NULL, magic);
      OrderSend(curr,OP_BUYLIMIT,Lots,openPrice-30*Point*mult(curr),3,openPrice-30*Point*mult(curr) - 130*Point*mult(curr),openPrice, NULL, magic);
      OrderSend(curr,OP_BUYLIMIT,Lots,openPrice-35*Point*mult(curr),3,openPrice-35*Point*mult(curr) - 130*Point*mult(curr),openPrice, NULL, magic);
      OrderSend(curr,OP_BUYLIMIT,Lots,openPrice-40*Point*mult(curr),3,openPrice-40*Point*mult(curr) - 130*Point*mult(curr),openPrice, NULL, magic);
   }
   
   return(0);
}

int deletePendingOrders(int Magic) {      
  int total  = OrdersTotal();
  for (int i=total-1; i >=0; i--){
    OrderSelect(i,SELECT_BY_POS,MODE_TRADES);     
    if (OrderMagicNumber()==Magic && OrderSymbol()==Symbol() && (OrderType()==OP_SELLLIMIT || OrderType()==OP_BUYLIMIT)){
      OrderDelete(OrderTicket());
    }
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

double getPrevLotPrices(int orders[]) {
   double prevLotPrices = 0;
   //for(int o = ArraySize(orders)-1;o>=0;o--) {
   for(int o=0;o<ArraySize(orders);o++) {
      if(OrderSelect(orders[o], SELECT_BY_TICKET)==true) {
         if(prevLotPrices == 0) {
            prevLotPrices=OrderOpenPrice();
         } else {
            prevLotPrices+=OrderOpenPrice();
         }
         
      }
      
   }
   return (prevLotPrices);
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

