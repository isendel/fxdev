//+------------------------------------------------------------------+
//|                                                Send_By_Skype.mq4 |
//|                                     Copyright © 2010, ENSED Team |
//|                                             http://www.ensed.org |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2010, ENSED Team"
#property link      "http://www.ensed.org"
#property show_inputs
extern string Tel_Num = "+79627273648";
extern string Text    = "Hello!";

#import "SkypeLib.dll"
   bool SendSkypeSMS(int &ExCode[], string Num,string Message);
   bool SendSkypeMessage(int &ExCode[], string User, string Message);
#import

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
  {
//----
   int ExCode[1];

   Alert("Отправляем SMS сообщение...");
   Alert(SendSkypeSMS(ExCode, Tel_Num, Text));
   if(ExCode[0] == -1)
       Alert("Ошибка отправки SMS сообщения");
   else
       Alert("SMS сообщение отправлено");
   return(0);

//----
   return(0);
  }
//+------------------------------------------------------------------+