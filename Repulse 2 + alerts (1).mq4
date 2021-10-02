//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""

#property indicator_separate_window
#property indicator_buffers 3
#property indicator_color1  LightGreen
#property indicator_color2  Thistle
#property indicator_color3  DimGray
#property indicator_width1  2
#property indicator_width2  2
#property indicator_width3  2
#property indicator_level1  0.0
#property indicator_levelcolor DimGray
#property strict

//
//
//
//
//

extern int  RepulseLength   = 5;      // Repulse period
extern bool AlertsOn        = false;  // Turn alerts on?
extern bool AlertsOnCurrent = true;   // Alerts on current bar?
extern bool AlertsMessage   = true;   // Alerts message?  
extern bool AlertsSound     = false;  // Alerts sound?
extern bool AlertsEmail     = false;  // Alerts email?

//
//
//
//
//

double repulse[];
double repulsh[];
double repulsl[];
double buffa[];
double buffb[];
double trend[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int init()
{
   IndicatorBuffers(6);
   SetIndexBuffer(0, repulsh); SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexBuffer(1, repulsl); SetIndexStyle(1,DRAW_HISTOGRAM);
   SetIndexBuffer(2, repulse); 
   SetIndexBuffer(3, buffa); 
   SetIndexBuffer(4, buffb); 
   SetIndexBuffer(5, trend); 
      IndicatorShortName("Repulse ("+(string)RepulseLength+")");
   return(0);
}
int deinit(){ return(0); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
{
   int counted_bars=IndicatorCounted();
      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
         int limit = MathMin(Bars-counted_bars,Bars-1);
         
   //
   //
   //
   //
   //

   double alpha = 2.0/(1.0+5.0*RepulseLength);
   for(int i=limit; i>=0; i--)
   {
      double pricea = (i<Bars-RepulseLength) ? 100.0*(3.0*Close[i]-2.0*Low[iLowest(NULL,0,MODE_LOW,RepulseLength,i)]-Open[i+RepulseLength])/Close[i] : Close[i];
      double priceb = (i<Bars-RepulseLength) ? 100.0*(Open[i+RepulseLength]+2.0*High[iHighest(NULL,0,MODE_HIGH,RepulseLength,i)]-3.0*Close[i])/Close[i] : Open[i];
             buffa[i] = (i<Bars-1) ? buffa[i+1]+alpha*(pricea-buffa[i+1]) : pricea;
             buffb[i] = (i<Bars-1) ? buffb[i+1]+alpha*(priceb-buffb[i+1]) : priceb;
         repulse[i] = buffa[i]-buffb[i];
         trend[i]   = (repulse[i]>0) ? 1 : (repulse[i]<0) ? -1 : (i<Bars-1) ? trend[i+1] : 0;
         repulsh[i] = (trend[i]== 1) ? repulse[i] : EMPTY_VALUE;
         repulsl[i] = (trend[i]==-1) ? repulse[i] : EMPTY_VALUE;
   }
   manageAlerts();
   return(0);
}

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------
//
//
//
//
//

void manageAlerts()
{
   if (AlertsOn)
   {
      int whichBar = (AlertsOnCurrent) ? 0 : 1;
      if (trend[whichBar]!= trend[whichBar+1])
      {
         static datetime time1 = 0;
         static string   mess1 = "";
            if (trend[whichBar] ==  1) doAlert(time1,mess1," Repulse trend changed to up");
            if (trend[whichBar] == -1) doAlert(time1,mess1," Repulse trend changed to down");
      }
   }
}

//
//
//
//
//

void doAlert(datetime& previousTime, string& previousAlert, string doWhat)
{
   string message;
   
   if (previousAlert != doWhat || previousTime != Time[0]) {
       previousAlert  = doWhat;
       previousTime   = Time[0];

       //
       //
       //
       //
       //

       message =  Symbol()+" at "+TimeToStr(TimeLocal(),TIME_SECONDS)+doWhat;
          if (AlertsMessage) Alert(message);
          if (AlertsEmail)   SendMail(Symbol()+" Repulse",message);
          if (AlertsSound)   PlaySound("alert2.wav");
   }
}

