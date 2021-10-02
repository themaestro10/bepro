//+------------------------------------------------------------------+
//|                                                         OBV2.mq4 |
//+------------------------------------------------------------------+
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1  DodgerBlue
#property indicator_color2  Red

extern string TimeFrame       = "Current time frame";
extern int    SignalPeriod    = 13;
extern int    SignalMaMode    = MODE_LWMA;

extern bool   alertsOn        = false;
extern bool   alertsOnCurrent = true;
extern bool   alertsMessage   = true;
extern bool   alertsSound     = false;
extern bool   alertsEmail     = false;

double gadblOBV[];
double ma[];
double trend[];

string indicatorFileName;
bool   returnBars;
bool   calculateValue;
int    timeFrame;

int init()
{
   IndicatorBuffers(3);
   SetIndexBuffer( 0, gadblOBV );
   SetIndexBuffer( 1, ma );
   SetIndexBuffer( 2, trend );
   IndicatorDigits( 0 );     
   
      //
      //
      //
      //
      //
      
         indicatorFileName = WindowExpertName();
         calculateValue    = TimeFrame=="calculateValue"; if (calculateValue) { return(0); }
         returnBars        = TimeFrame=="returnBars";     if (returnBars)     { return(0); }
         timeFrame         = stringToTimeFrame(TimeFrame);
      
      //
      //
      //
      //
      //

   IndicatorShortName( timeFrameToString(timeFrame)+" OBV2" );
   SetIndexLabel( 0, "OBV2" );
   return( 0 );
}

int start()
{
   int counted_bars = IndicatorCounted();
      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
           int limit=MathMin(Bars-counted_bars,Bars-1);
           if (returnBars) { gadblOBV[0] = MathMin(limit+1,Bars-1); return(0); }
   
   //
   //
   //
   //
   //

   if (calculateValue || timeFrame == Period())
   {
      for( int inx = limit; inx >=0; inx-- )
      {
         if ( inx == ( Bars - 1 ) )
         {
            gadblOBV[inx] = Volume[inx];
         }
         else 
         {
            if ( ( High[inx] == Low[inx] ) || ( Open[inx] == Close[inx] ) || ( Close[inx] == Close[inx+1] ) )
            {
               gadblOBV[inx] = gadblOBV[inx+1];
            }
            else
            {            
               if ( Close[inx] > Open[inx] )   gadblOBV[inx] = gadblOBV[inx+1] + ( Volume[inx] * ( Close[inx] - Open[inx] ) / ( High[inx] - Low[inx] ) );
               else                            gadblOBV[inx] = gadblOBV[inx+1] - ( Volume[inx] * ( Open[inx] - Close[inx] ) / ( High[inx] - Low[inx] ) );
            }
         }     
      }
      for(inx=limit; inx>=0; inx--)
      {
         ma[inx]=iMAOnArray(gadblOBV,0,SignalPeriod,0,SignalMaMode,inx);
         trend[inx] = trend[inx+1];
            if (gadblOBV[inx] > ma[inx])  trend[inx] =  1;
            if (gadblOBV[inx] < ma[inx])  trend[inx] = -1;
            
      } 
      manageAlerts();            
      return( 0 );
   }      

   limit = MathMax(limit,MathMin(Bars-1,iCustom(NULL,timeFrame,indicatorFileName,"returnBars",0,0)*timeFrame/Period()));
   for (int i=limit; i>=0; i--)
   {
      int y = iBarShift(NULL,timeFrame,Time[i]);
         gadblOBV[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",SignalPeriod,SignalMaMode,0,y);
         ma[i]       = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",SignalPeriod,SignalMaMode,1,y);
         trend[i]    = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",SignalPeriod,SignalMaMode,2,y);
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

string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

//
//
//
//
//

int stringToTimeFrame(string tfs)
{
   tfs = stringUpperCase(tfs);
   for (int i=ArraySize(iTfTable)-1; i>=0; i--)
         if (tfs==sTfTable[i] || tfs==""+iTfTable[i]) return(MathMax(iTfTable[i],Period()));
                                                      return(Period());
}
string timeFrameToString(int tf)
{
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
}

//
//
//
//
//

string stringUpperCase(string str)
{
   string   s = str;

   for (int length=StringLen(str)-1; length>=0; length--)
   {
      int tchar = StringGetChar(s, length);
         if((tchar > 96 && tchar < 123) || (tchar > 223 && tchar < 256))
                     s = StringSetChar(s, length, tchar - 32);
         else if(tchar > -33 && tchar < 0)
                     s = StringSetChar(s, length, tchar + 224);
   }
   return(s);
}

//+------------------------------------------------------------------
//|                                                                 
//+------------------------------------------------------------------
//
//
//
//
//

void manageAlerts()
{
   if (!calculateValue && alertsOn)
   {
      if (alertsOnCurrent)
           int whichBar = 0;
      else     whichBar = 1; whichBar = iBarShift(NULL,0,iTime(NULL,timeFrame,whichBar));
      if (trend[whichBar] != trend[whichBar+1])
      {
         if (trend[whichBar]   == 1) doAlert(whichBar," buy ");
         if (trend[whichBar]   ==-1) doAlert(whichBar," sell ");
      }         
   }
}

//
//
//
//
//

void doAlert(int forBar, string doWhat)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   string message;
   
   if (previousAlert != doWhat || previousTime != Time[forBar]) {
       previousAlert  = doWhat;
       previousTime   = Time[forBar];

       //
       //
       //
       //
       //

       message =  StringConcatenate(Symbol()," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," ",timeFrameToString(timeFrame)," OBV2 ",doWhat);
          if (alertsMessage) Alert(message);
          if (alertsEmail)   SendMail(StringConcatenate(Symbol()," OBV2 "),message);
          if (alertsSound)   PlaySound("alert2.wav");
   }
}