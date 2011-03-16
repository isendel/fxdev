//+------------------------------------------------------------------+
//|                                   Copyright © 2010, Ivan Kornilov|
//|                                                      FiboBars.mq4|
//+------------------------------------------------------------------+
#property copyright "Copyright © 2010, Ivan Kornilov. All rights reserved."
#property link "excelf@gmail.com"

#property indicator_chart_window
#property indicator_buffers 5
#property indicator_color1 Red
#property indicator_color2 Green
#property indicator_color3 Red
#property indicator_color4 Green
#property indicator_color5 Gold

extern int TF_1 = 15;
extern int TF_2 = 60;
//extern int period = 4;//1H
extern int period = 10;//5Min
extern int fiboLevel = 1;
extern bool alertMode = false;
extern string Prefix       = "AK";
extern bool   ReverseSignal = False;

double ExtMapBuffer1[];
double ExtMapBuffer2[];
double ExtMapBuffer3[];
double ExtMapBuffer4[];
double ExtMapBuffer5[];

bool oldIsTrandDown ;
double level;
#define level1 0.236
#define level2 0.382
#define level3 0.5
#define level4 0.618
#define level5 0.762

bool Activate;
string Name, STime, Signal;
datetime LastBar;

int init() {
    ObjectDelete("line_FiboBars");
    Activate = False;
    SetIndexStyle(0, DRAW_HISTOGRAM, 0, 1);
    SetIndexBuffer(0, ExtMapBuffer1);
    SetIndexStyle(1, DRAW_HISTOGRAM, 0, 1);
    SetIndexBuffer(1, ExtMapBuffer2);
    SetIndexStyle(2, DRAW_HISTOGRAM, 0, 3);
    SetIndexBuffer(2, ExtMapBuffer3);
    SetIndexStyle(3, DRAW_HISTOGRAM, 0, 3);
    SetIndexBuffer(3, ExtMapBuffer4);
   SetIndexStyle(4,DRAW_LINE);
   SetIndexBuffer(4,ExtMapBuffer5);

    SetIndexDrawBegin(0, 10);
    SetIndexDrawBegin(1, 10);
    SetIndexDrawBegin(2, 10);
    SetIndexDrawBegin(3, 10);
    SetIndexDrawBegin(4, 10);
    SetIndexBuffer(0, ExtMapBuffer1);
    SetIndexBuffer(1, ExtMapBuffer2);
    SetIndexBuffer(2, ExtMapBuffer3);
    SetIndexBuffer(3, ExtMapBuffer4);
    SetIndexBuffer(4, ExtMapBuffer5);
   
    switch(fiboLevel){
    case 1:
        level = level1;
        break;
    case 2:
        level = level2;   
        break;
    case 3:
        level = level3;
        break;
    case 4:
        level = level4;
        break;
    case 5:
        level = level5;
        break;
    default:
        level = level1;
        break;
    }
   
       // Номер индикатора в списке стратегий 6
   Name = Prefix+Symbol()+"Name";
   STime = Prefix+Symbol()+"STime";
   Signal = Prefix+Symbol()+"Signal";
   if (GlobalVariableCheck(Name))
     {
      Alert("Один индикатор уже присоединен!");
      return(0);       
     }
     
   GlobalVariableSet(Name, 6); // Идентификатор индикатора
   GlobalVariableSet(STime, 0); // Последнее время обновления значений
   GlobalVariableSet(Signal, 0); // Текущее состояние "нет сигнала"
   
   LastBar = 0;
   Activate = True; 
   
    return(0);
}

int deinit()
{
   ObjectDelete("line_FiboBars");
   if (Activate)
     {
      GlobalVariableDel(Name);
      GlobalVariableDel(STime);
      GlobalVariableDel(Signal);
     }
    return(0);
}

int start() {
    int indicatorCounted = IndicatorCounted();
    if (indicatorCounted < 0) {
        return (-1);
    }
    if(indicatorCounted > 0) {
       indicatorCounted--;
    }
   
    int limit = Bars - indicatorCounted;
    for(int i = limit; i >= 0; i--)
    {
        bool isTrandDown = ExtMapBuffer1[i+1] > ExtMapBuffer2[i+1];
        double maxHigh = High[iHighest(NULL,0,MODE_HIGH, period, i)];
        double minLow = Low[iLowest(NULL,0,MODE_LOW, period, i)];
        if(Open[i] > Close[i]) {
           if(!(!isTrandDown  && (maxHigh - minLow) * level < (Close[i] - minLow))) {
                isTrandDown = true;
           } else {
              isTrandDown = false;
     
            }
        } else {
            if(!(isTrandDown  && (maxHigh - minLow) * level < (maxHigh - Close[i]))) {
                isTrandDown  = false;
            } else {
                isTrandDown = true;
            }
        }
       
        if(alertMode && i == 0 && (ExtMapBuffer1[i+1] > ExtMapBuffer2[i+1]) != isTrandDown) {
            if (isTrandDown) {
                Alert("FiboBars: " + Symbol() + " M" + Period() + ": Signal: SELL");
            } else {
                Alert("FiboBars: " + Symbol() + " M" + Period() + ": Signal: BUY");
            }
        }
       
        if(isTrandDown) {//RED BAR
            ExtMapBuffer1[i] = High[i];
            ExtMapBuffer2[i] = Low[i];
            ExtMapBuffer3[i] = MathMax(Open[i], Close[i]);
            ExtMapBuffer4[i] = MathMin(Open[i], Close[i]);   
        } else {//GREEN BAR
            ExtMapBuffer1[i] = Low[i];
            ExtMapBuffer2[i] = High[i];
            ExtMapBuffer3[i] = MathMin(Open[i], Close[i]); 
            ExtMapBuffer4[i] = MathMax(Open[i], Close[i]);   
        }
       
         if(isTrandDown)
           ExtMapBuffer5[i]=maxHigh-(maxHigh - minLow)*level;
         else
           ExtMapBuffer5[i]=minLow+(maxHigh - minLow)*level; 
     if((i==1)) {
       ObjectDelete("line_FiboBars");
       if(ObjectFind("line_FiboBars")<0) {
         if(isTrandDown)
           ObjectCreate("line_FiboBars", OBJ_HLINE, 0, Time[0], maxHigh-(maxHigh - minLow)*level);
         else
           ObjectCreate("line_FiboBars", OBJ_HLINE, 0, Time[0], minLow+(maxHigh - minLow)*level); 
       } else {
         if(isTrandDown)
           ObjectMove("line_FiboBars", 0, Time[0], maxHigh-(maxHigh - minLow)*level);
         else
           ObjectMove("line_FiboBars", 0, Time[0], minLow+(maxHigh - minLow)*level); 
       }
       ObjectSet("line_FiboBars", OBJPROP_COLOR, Gold) ;
     } 
    }
   
      // Передача сигнала SELL в АК
    if (ExtMapBuffer1[1] > ExtMapBuffer2[1] && ExtMapBuffer1[2] < ExtMapBuffer2[2])
      { 
       if (ReverseSignal)
         GlobalVariableSet(Signal, 1);
        else
         GlobalVariableSet(Signal, -1);
       GlobalVariableSet(STime, Time[0]);     
      }
      // Передача сигнала BUY в АК
    if (ExtMapBuffer1[1] < ExtMapBuffer2[1] && ExtMapBuffer1[2] > ExtMapBuffer2[2])
      { 
       if (ReverseSignal)
         GlobalVariableSet(Signal, -1);
        else
         GlobalVariableSet(Signal, 1);
       GlobalVariableSet(STime, Time[0]);     
      }

    return(0);
}