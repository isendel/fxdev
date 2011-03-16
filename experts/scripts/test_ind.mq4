//+------------------------------------------------------------------+
//|                                                     test_ind.mq4 |
//|                      Copyright © 2010, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2010, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
  {
//----
  //Comment(iCustom(NULL,0,"FiboBars",0,0)," ",iCustom(NULL,0,"FiboBars",1,0)," ",iCustom(NULL,0,"FiboBars",2,0)," ",iCustom(NULL,0,"FiboBars",3,0));
  if((iCustom(NULL,0,"FiboBars",0,0)==High[0]) && (iCustom(NULL,0,"FiboBars",0,1)==Low[1]))
    Comment("DOWN");
    
  if((iCustom(NULL,0,"FiboBars",0,0)==Low[0]) && (iCustom(NULL,0,"FiboBars",0,1)==High[1]))
    Comment("UP");
//----
   return(0);
  }
//+------------------------------------------------------------------+