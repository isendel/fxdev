//+------------------------------------------------------------------+
//|                                                 vip_multy_v1.mq4 |
//|                      Copyright © 2011, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

extern int magic = 111;

extern double Lots = 2.0;

int start()  {
   double ma = iMA(NULL,PERIOD_D1,150,0,MODE_SMMA,PRICE_CLOSE,0);
   double rsi = iRSI(NULL,PERIOD_D1,3,PRICE_CLOSE,0);
   double stohastic = iStochastic(NULL,PERIOD_D1,6,3,3,MODE_SMA,0,MODE_CLOSE,0);
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