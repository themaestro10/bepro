//+------------------------------------------------------------------+

//| Tick Volume Indicator v2 |

//| Copyright © William Blau |

//+------------------------------------------------------------------+

#property copyright "www.forex-station.com"

//+------------------------------------------------------------------+

//---- properties

#property indicator_separate_window

#property indicator_buffers 5

#property indicator_color1 RoyalBlue // for line graph, set color1-color4

#property indicator_color2 LimeGreen // to CLR_NONE = set None in user

#property indicator_color3 Crimson // settings.

#property indicator_color4 Gold //

#property indicator_color5 Gold // set CLR_NONE to hide the line

#property indicator_width1 2

#property indicator_width2 2

#property indicator_width3 2

#property indicator_width4 2

#property indicator_width5 1

#property indicator_style5 2

//+------------------------------------------------------------------+

//---- input parameters

extern int r = 16;

extern int s = 16;

extern int u = 5;

extern string _n1 = "_Increase for more history";

extern int BarCount = 500;

extern string _n2 = "_AlertCandle = 0: current";

extern string _n3 = "_AlertCandle = 1: closed";

extern int AlertCandle = 1;

extern bool PopupAlerts = false; 

extern string _n4 = "_Leave empty for no email";

extern string AlertEmailSubject = "";

extern ENUM_MA_METHOD MaMethod=MODE_EMA;
//+------------------------------------------------------------------+

//---- globalscape

datetime LastAlertTime = -999999;

string AlertUp = "TVI change: UP";

string AlertDn = "TVI change: DOWN";

int Precision = 5;

datetime OldTime;

string ShortName;

//+------------------------------------------------------------------+

//---- buffers

double UpPos[], DnPos[], UpNeg[], DnNeg[];

double TVI[], TVI_Raw[], Trend[];

//+------------------------------------------------------------------+

//---- extra buffers

double UpTicks[], DnTicks[];

double EMA_U[], EMA_D[], DEMA_U[], DEMA_D[];

//+------------------------------------------------------------------+

//| indicator initialization |

//+------------------------------------------------------------------+

int init()




{ 

//---- data window / tooltip precision

IndicatorDigits(Precision);

//---- 7 buffers used (one still free)

IndicatorBuffers(7);

//---- 5 buffers for drawing

SetIndexBuffer(0, UpPos);

SetIndexBuffer(1, DnPos);

SetIndexBuffer(2, UpNeg);

SetIndexBuffer(3, DnNeg);

SetIndexBuffer(4, TVI);

SetIndexStyle(0, DRAW_HISTOGRAM); 

SetIndexStyle(1, DRAW_HISTOGRAM);

SetIndexStyle(2, DRAW_HISTOGRAM);

SetIndexStyle(3, DRAW_HISTOGRAM);

SetIndexStyle(4, DRAW_LINE);

//---- 2 buffers for calculations

SetIndexBuffer(5, TVI_Raw);

SetIndexBuffer(6, Trend);

//---- 6 additional buffers for calc

ArrayResize(UpTicks, BarCount); ArraySetAsSeries(UpTicks, true);

ArrayResize(DnTicks, BarCount); ArraySetAsSeries(DnTicks, true);

ArrayResize(EMA_U, BarCount); ArraySetAsSeries(EMA_U, true);

ArrayResize(EMA_D, BarCount); ArraySetAsSeries(EMA_D, true);

ArrayResize(DEMA_U, BarCount); ArraySetAsSeries(DEMA_U, true);

ArrayResize(DEMA_D, BarCount); ArraySetAsSeries(DEMA_D, true);

// ---- disable data values for histo buffers

SetIndexLabel(0, NULL); SetIndexLabel(1, NULL); SetIndexLabel(2, NULL); SetIndexLabel(3, NULL);

// ---- enable data value for TVI

SetIndexLabel(4, "TVI Value");

//---- reset bar counter 

OldTime = Time[0];

//---- collect indi name

ShortName = "TVI v2 (" + r + "," + s + "," + u + ") Trend is ";

//---- end init

return(0);

}

//+------------------------------------------------------------------+

//| indicator code |

//+------------------------------------------------------------------+

int start()

{

int counted_bars = IndicatorCounted();

if (counted_bars < 0) return (-1);

if (counted_bars > 0) counted_bars--;

int limit = MathMin(BarCount, Bars - counted_bars) - 1;

double Rate1, Rate2, Rate3, Rate4, Rate5;

double inverse = 1;

double ask = MarketInfo(Symbol(), MODE_ASK)/100;

double bid = MarketInfo(Symbol(), MODE_BID)/100;


// Market Delta = calculated by subtracting the volume transacted at the bid price from the volume transacted at the ask price.


/*Delta = Ask - Bid

Buy Volume (Ask Volume) = volume that traded at or above the ask price.

Sell Volume (Bid Volume) = volume that traded at or below the bid price.


Red - negative histogram bar. Delta is positive, but current price is below opening price.

Green - positive histogram bar. Delta is negative, but current price is above opening price.

Blue - positive histogram bar. Delta is positive, and current price is above opening price.

Yellow - negative histogram bar. Delta is negative, and current price is below opening price.

*/


double delta = ask-bid;


//---- resize/shift extra buffers on first and every next bar

if (Time[0] != OldTime) SyncExtraBuffers(BarCount);

//---- calculate ticks

for(int i = limit; i >= 0; i--)

{

UpTicks[i] = (delta + (Close[i] - Open[i]) / Point)/100;

//DnTicks[i] = 0;

DnTicks[i] = (delta + (Open[i] - Close[i]) / Point)/100;

}

//---- 1st pass smoothing 

for(i = limit; i >= 0; i--)

{

EMA_U[i] = iMAOnArray(UpTicks, 0, r, 0,MaMethod, i)/100;

EMA_D[i] = iMAOnArray(DnTicks, 0, r, 0, MaMethod, i)/100;

}

//---- 2nd pass smoothing 

for(i = limit; i >= 0; i--)

{

DEMA_U[i] = iMAOnArray(EMA_U, 0, s, 0, MaMethod, i)/100;

DEMA_D[i] = iMAOnArray(EMA_D, 0, s, 0, MaMethod, i)/100;

}

//---- calculate the ratio 

for(i = limit; i >= 0; i--)
if ((DEMA_U[i] + DEMA_D[i])!=0)
      TVI_Raw[i] = 1.0 * (DEMA_U[i] - DEMA_D[i]) / (DEMA_U[i] + DEMA_D[i]);
else  TVI_Raw[i] = 0;


//---- final smoothing 

for(i = limit; i >= 0; i--)

TVI[i] = iMAOnArray(TVI_Raw, 0, u, 0, MaMethod, i);

//---- make histogram

for(i = limit; i >= 0; i--)

{

// ---- keep previous direction

Trend[i] = Trend[i + 1];

// ---- ...until there's a change

if (TVI[i] > TVI[i + 1]) Trend[i] = 1;

else if (TVI[i] < TVI[i + 1]) Trend[i] = -1;

// ---- paint the buffers accordingly

if (Trend[i] > 0)

{

if (TVI[i] >= 0) 
   {
   UpPos[i] = TVI[i]; 
   DnPos[i] = EMPTY_VALUE;
   }

else {UpNeg[i] = TVI[i]; DnNeg[i] = EMPTY_VALUE;}

}

else if (Trend[i] < 0)

{

if (TVI[i] >= 0) 
   {
   DnPos[i] = TVI[i]; 
   UpPos[i] = EMPTY_VALUE;
   }

else {DnNeg[i] = TVI[i]; UpNeg[i] = EMPTY_VALUE;}

}

}

//---- trend display update

if (Trend[0] == 1) string t = "UP"; else t = "DOWN";

IndicatorShortName(ShortName + t);

//---- do alerts

ProcessAlerts();

//---- end of loop

return(0);

}

//+------------------------------------------------------------------+

//| shift extra buffers on new bar |

//+------------------------------------------------------------------+

void SyncExtraBuffers(int count)

{

for (int i = count - 1; i >= 0; i--)

{

UpTicks[i + 1] = UpTicks[i];

DnTicks[i + 1] = DnTicks[i];

EMA_U[i + 1] = EMA_U[i];

EMA_D[i + 1] = EMA_D[i];

DEMA_U[i + 1] = DEMA_U[i];

DEMA_D[i + 1] = DEMA_D[i];

}

//---- reset bar counter 

OldTime = Time[0];

}

//+------------------------------------------------------------------+

//| alert routine (thank you hanover :-) |

//| http://www.forexfactory.com/showthread.php?t=299520 |

//+------------------------------------------------------------------+

void ProcessAlerts()

{ 

if (AlertCandle >= 0 && Time[0] > LastAlertTime)

{

//---- alert UP

if (Trend[AlertCandle] == 1 && Trend[AlertCandle + 1] != 1)

{

string AlertText = Symbol() + "," + TFToStr(Period()) + ": " + AlertUp;

if (PopupAlerts) Alert(AlertText);

if (AlertEmailSubject > "") SendMail(AlertEmailSubject, AlertText);

LastAlertTime = Time[0]; 

}

//---- alert DOWN

if (Trend[AlertCandle] == - 1 && Trend[AlertCandle + 1] != -1)

{

AlertText = Symbol() + "," + TFToStr(Period()) + ": " + AlertDn;

if (PopupAlerts) Alert(AlertText);

if (AlertEmailSubject > "") SendMail(AlertEmailSubject, AlertText);

LastAlertTime = Time[0]; 

}

}

}

//+------------------------------------------------------------------+

string TFToStr(int tf)

{

if (tf == 0) tf = Period();

if (tf >= 43200) return("MN"); 

if (tf >= 10080) return("W1"); 

if (tf >= 1440) return("D1"); 

if (tf >= 240) return("H4"); 

if (tf >= 60) return("H1"); 

if (tf >= 30) return("M30");

if (tf >= 15) return("M15");

if (tf >= 5) return("M5"); 

if (tf >= 1) return("M1"); 

return("");

} 
