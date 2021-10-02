//+------------------------------------------------------------------+
//|                                                          tcf.mq4 |
//|                                                           mladen |
//|                                                                  |
//| Trend Continuation Factor originaly developed by M.H. Pee        |
//| TASC : 20:3 (March 2002) article                                 |
//| "Just How Long Will A Trend Go On? Trend Continuation Factor"    |
//+------------------------------------------------------------------+
#property copyright "mladen"
#property link      "mladenfx@gmail.com"

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1  clrLimeGreen
#property indicator_color2  clrDarkOrange

//
//
//
//
//

extern string TimeFrame = "Current time frame";
extern int    Length    = 35;
extern int    Price     = PRICE_CLOSE;

//
//
//
//
//

double TcfUp[];
double TcfDo[];
double values[][4];
int    timeFrame;
string IndicatorFileName;
bool   calculatingTcf = false;
bool   returningBars  = false;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int init()
{
   for (int i=0; i<indicator_buffers; i++) SetIndexStyle(i,DRAW_LINE);
   SetIndexBuffer(0,TcfUp);
   SetIndexBuffer(1,TcfDo);
      if (TimeFrame=="calculateTcf")
         {
            calculatingTcf = true;
            return(0);
         }            
      if (TimeFrame=="returnBars")
         {
            returningBars = true;
            return(0);
         }            

   //
   //
   //
   //
   //
            
   timeFrame = stringToTimeFrame(TimeFrame);
   IndicatorFileName = WindowExpertName();
   IndicatorShortName("Tcf "+TimeFrameToString(timeFrame)+" ("+Length+")");
   return(0);
}
int deinit()
{
   return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

#define plus_ch  0
#define minus_ch 1
#define plus_cf  2
#define minus_cf 3

//
//
//
//
//

int start()
{
   int counted_bars=IndicatorCounted();
   int i,limit;

   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
         limit = Bars-counted_bars;
         if (returningBars)  { TcfUp[0] = limit;    return(0); }
         if (calculatingTcf) { CalculateTcf(limit); return(0); }

   //
   //
   //
   //
   //
   
      if (timeFrame > Period()) limit = MathMax(limit,MathMin(Bars,iCustom(NULL,timeFrame,IndicatorFileName,"returnBars",0,0)*timeFrame/Period()));

      //
      //
      //
      //
      //
   
   	for(i = limit; i >= 0; i--)
      {
         int      shift1 = iBarShift(NULL,timeFrame,Time[i]);
         datetime time1  = iTime    (NULL,timeFrame,shift1);
   
            TcfUp[i] = iCustom(NULL,timeFrame,IndicatorFileName,"calculateTcf",Length,Price,0,shift1);
            TcfDo[i] = iCustom(NULL,timeFrame,IndicatorFileName,"calculateTcf",Length,Price,1,shift1);

            if(timeFrame <= Period() || shift1==iBarShift(NULL,timeFrame,Time[i-1])) continue;

            //
            //
	         //
            //
            //
		 
            for(int n = 1; i+n < Bars && Time[i+n] >= time1; n++) continue;	
            double factor = 1.0 / n;
            for(int k = 1; k < n; k++)
            {
    	          TcfUp[i+k] = k*factor*TcfUp[i+n] + (1.0-k*factor)*TcfUp[i];
    	          TcfDo[i+k] = k*factor*TcfDo[i+n] + (1.0-k*factor)*TcfDo[i];
            }    	          
      }

   //
   //
   //
   //
   //

   return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

void CalculateTcf(int limit )
{
   if (ArrayRange(values,0) != Bars) ArrayResize(values,Bars);
   
   //
   //
   //
   //
   
   int i,r;
   for(i=limit, r=Bars-limit-1; i>=0; i--,r++)
   {
      double roc = iMA(NULL,0,1,0,MODE_SMA,Price,i)-iMA(NULL,0,1,0,MODE_SMA,Price,i+1);

         values[r][plus_ch]  = 0;
         values[r][minus_ch] = 0;
         values[r][plus_cf]  = 0;
         values[r][minus_cf] = 0;
      
         //
         //
         //
         //
         //
               
            if (roc>0)
            {
               values[r][plus_ch] = roc;
               if (r>1)
                     values[r][plus_cf] = values[r][plus_ch]+values[r-1][plus_cf];
               else  values[r][plus_cf] = values[r][plus_ch];
            }                  
            if (roc<0)
            {
               values[r][minus_ch] = -roc;
               if (r>1)
                     values[r][minus_cf] = values[r][minus_ch]+values[r-1][minus_cf];
               else  values[r][minus_cf] = values[r][minus_ch];
            }
   
         //
         //
         //
         //
         //
                           
         TcfUp[i] = 0;
         TcfDo[i] = 0;
         for (int l=0; l<Length; l++)
         {
            TcfUp[i] += values[r-l][plus_ch]-values[r-l][minus_cf];
            TcfDo[i] += values[r-l][minus_ch]-values[r-l][plus_cf];
         }
   }      
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int stringToTimeFrame(string tfs)
{
   int tf=0;
       tfs = StringUpperCase(tfs);
         if (tfs=="M1" || tfs=="1")     tf=PERIOD_M1;
         if (tfs=="M5" || tfs=="5")     tf=PERIOD_M5;
         if (tfs=="M15"|| tfs=="15")    tf=PERIOD_M15;
         if (tfs=="M30"|| tfs=="30")    tf=PERIOD_M30;
         if (tfs=="H1" || tfs=="60")    tf=PERIOD_H1;
         if (tfs=="H4" || tfs=="240")   tf=PERIOD_H4;
         if (tfs=="D1" || tfs=="1440")  tf=PERIOD_D1;
         if (tfs=="W1" || tfs=="10080") tf=PERIOD_W1;
         if (tfs=="MN" || tfs=="43200") tf=PERIOD_MN1;
         if (tf<Period()) tf=Period();
  return(tf);
}
string TimeFrameToString(int tf)
{
   string tfs="";
   
   if (tf!=Period())
      switch(tf) {
         case PERIOD_M1:  tfs="M1"  ; break;
         case PERIOD_M5:  tfs="M5"  ; break;
         case PERIOD_M15: tfs="M15" ; break;
         case PERIOD_M30: tfs="M30" ; break;
         case PERIOD_H1:  tfs="H1"  ; break;
         case PERIOD_H4:  tfs="H4"  ; break;
         case PERIOD_D1:  tfs="D1"  ; break;
         case PERIOD_W1:  tfs="W1"  ; break;
         case PERIOD_MN1: tfs="MN1";
      }
   return(tfs);
}

//
//
//
//
//

string StringUpperCase(string str)
{
   string   s = str;
   int      lenght = StringLen(str) - 1;
   int      tchar;
   
   while(lenght >= 0)
      {
         tchar = StringGetChar(s, lenght);
         
         //
         //
         //
         //
         //
         
         if((tchar > 96 && tchar < 123) || (tchar > 223 && tchar < 256))
                  s = StringSetChar(s, lenght, tchar - 32);
         else 
              if(tchar > -33 && tchar < 0)
                  s = StringSetChar(s, lenght, tchar + 224);
         lenght--;
   }
   
   //
   //
   //
   //
   //
   
   return(s);
}