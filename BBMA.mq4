//+------------------------------------------------------------------+
//|                                                         BBMA.mq4 |
//|                                                         don.chan |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "don.chan"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "BBMA"
#property strict



#include <MovingAverages.mqh>

#property indicator_chart_window
#property indicator_buffers 16
//#property indicator_color1 LightSeaGreen
//#property indicator_color2 LightSeaGreen
//#property indicator_color3 LightSeaGreen
//#property indicator_color3 LightSeaGreen
//--- indicator parameters
input int    InpBandsPeriod=60;      // Bands Period
input int    InpBandsShift=0;        // Bands Shift
input double InpBandsDeviations=1.0; // Bands Deviations

input int    InpBandsPeriod_blue=240;      // Bands Period
input int    InpBandsPeriod_yellow=480;      // Bands Period
input int    InpBandsPeriod_red=1440;      // Bands Period

//--- tomato buffers-----------------
double ExtMovingBuffer[];
double ExtUpperBuffer[];
double ExtLowerBuffer[];
double ExtStdDevBuffer[];
//------------blue buffer----------------
double ExtMovingBuffer_blue[];
double ExtUpperBuffer_blue[];
double ExtLowerBuffer_blue[];
double ExtStdDevBuffer_blue[];
//-------------yellow buffer-------------
double ExtMovingBuffer_yellow[];
double ExtUpperBuffer_yellow[];
double ExtLowerBuffer_yellow[];
double ExtStdDevBuffer_yellow[];
//-------------red buffer-------------
double ExtMovingBuffer_red[];
double ExtUpperBuffer_red[];
double ExtLowerBuffer_red[];
double ExtStdDevBuffer_red[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit(void)
  {
//--- 1 additional buffer used for counting.
   IndicatorBuffers(5);
   IndicatorDigits(Digits);
//---tomato----------------------------------------
//--- middle line
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrTomato);
   SetIndexBuffer(0,ExtMovingBuffer);
   SetIndexShift(0,InpBandsShift);
   SetIndexLabel(0,"Bands SMA");
//--- upper band
   SetIndexStyle(1,DRAW_LINE,STYLE_DASHDOT,1,clrTomato);
   SetIndexBuffer(1,ExtUpperBuffer);
   SetIndexShift(1,InpBandsShift);
   SetIndexLabel(1,"Bands Upper");
//--- lower band
   SetIndexStyle(2,DRAW_LINE,STYLE_DASHDOT,1,clrTomato);
   SetIndexBuffer(2,ExtLowerBuffer);
   SetIndexShift(2,InpBandsShift);
   SetIndexLabel(2,"Bands Lower");

//--------------------blue-----------------------------
//--- middle line
   SetIndexStyle(3,DRAW_LINE,STYLE_SOLID,2,clrBlue);
   SetIndexBuffer(3,ExtMovingBuffer_blue);
   SetIndexShift(3,InpBandsShift);
   SetIndexLabel(3,"Bands SMA");
//--- upper band
   SetIndexStyle(4,DRAW_LINE,STYLE_DASHDOT,1,clrBlue);
   SetIndexBuffer(4,ExtUpperBuffer_blue);
   SetIndexShift(4,InpBandsShift);
   SetIndexLabel(4,"Bands Upper");
//--- lower band
   SetIndexStyle(5,DRAW_LINE,STYLE_DASHDOT,1,clrBlue);
   SetIndexBuffer(5,ExtLowerBuffer_blue);
   SetIndexShift(5,InpBandsShift);
   SetIndexLabel(5,"Bands Lower");
   
//--------------------yellow-----------------------------
//--- middle line
   SetIndexStyle(6,DRAW_LINE,STYLE_SOLID,2,clrYellow);
   SetIndexBuffer(6,ExtMovingBuffer_yellow);
   SetIndexShift(6,InpBandsShift);
   SetIndexLabel(6,"Bands SMA");
//--- upper band
   SetIndexStyle(7,DRAW_LINE,STYLE_DASHDOT,1,clrYellow);
   SetIndexBuffer(7,ExtUpperBuffer_yellow);
   SetIndexShift(7,InpBandsShift);
   SetIndexLabel(7,"Bands Upper");
//--- lower band
   SetIndexStyle(8,DRAW_LINE,STYLE_DASHDOT,1,clrYellow);
   SetIndexBuffer(8,ExtLowerBuffer_yellow);
   SetIndexShift(8,InpBandsShift);
   SetIndexLabel(8,"Bands Lower");
   
//--------------------red-----------------------------
//--- middle line
   SetIndexStyle(9,DRAW_LINE,STYLE_SOLID,2,clrRed);
   SetIndexBuffer(9,ExtMovingBuffer_red);
   SetIndexShift(9,InpBandsShift);
   SetIndexLabel(9,"Bands SMA");
//--- upper band
   SetIndexStyle(10,DRAW_LINE,STYLE_DASHDOT,1,clrRed);
   SetIndexBuffer(10,ExtUpperBuffer_red);
   SetIndexShift(10,InpBandsShift);
   SetIndexLabel(10,"Bands Upper");
//--- lower band
   SetIndexStyle(11,DRAW_LINE,STYLE_DASHDOT,1,clrRed);
   SetIndexBuffer(11,ExtLowerBuffer_red);
   SetIndexShift(11,InpBandsShift);
   SetIndexLabel(11,"Bands Lower");


//--- work buffer
   SetIndexBuffer(12,ExtStdDevBuffer);
   SetIndexBuffer(13,ExtStdDevBuffer_blue);
   SetIndexBuffer(14,ExtStdDevBuffer_yellow);
   SetIndexBuffer(15,ExtStdDevBuffer_red);
   
//--- check for input parameter
   if(InpBandsPeriod<=0)
     {
      Print("Wrong input parameter Bands Period=",InpBandsPeriod);
      return(INIT_FAILED);
     }
//---
//--------------tomato-----------------------------
   SetIndexDrawBegin(0,InpBandsPeriod+InpBandsShift);
   SetIndexDrawBegin(1,InpBandsPeriod+InpBandsShift);
   SetIndexDrawBegin(2,InpBandsPeriod+InpBandsShift);
//---------------blue---------------------------------
   SetIndexDrawBegin(3,InpBandsPeriod_blue+InpBandsShift);
   SetIndexDrawBegin(4,InpBandsPeriod_blue+InpBandsShift);
   SetIndexDrawBegin(5,InpBandsPeriod_blue+InpBandsShift);
//---------------yellow---------------------------------
   SetIndexDrawBegin(6,InpBandsPeriod_yellow+InpBandsShift);
   SetIndexDrawBegin(7,InpBandsPeriod_yellow+InpBandsShift);
   SetIndexDrawBegin(8,InpBandsPeriod_yellow+InpBandsShift);
//---------------red---------------------------------
   SetIndexDrawBegin(9,InpBandsPeriod_red+InpBandsShift);
   SetIndexDrawBegin(10,InpBandsPeriod_red+InpBandsShift);
   SetIndexDrawBegin(11,InpBandsPeriod_red+InpBandsShift);
//--- initialization done
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Bollinger Bands                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   int i,pos;
//---
   if(rates_total<=InpBandsPeriod || InpBandsPeriod<=0)
      return(0);
//--- counting from 0 to rates_total
//------------------tomato------------------
   ArraySetAsSeries(ExtMovingBuffer,false);
   ArraySetAsSeries(ExtUpperBuffer,false);
   ArraySetAsSeries(ExtLowerBuffer,false);
   ArraySetAsSeries(ExtStdDevBuffer,false);
//-----------------blue-----------------------
   ArraySetAsSeries(ExtMovingBuffer_blue,false);
   ArraySetAsSeries(ExtUpperBuffer_blue,false);
   ArraySetAsSeries(ExtLowerBuffer_blue,false);
   ArraySetAsSeries(ExtStdDevBuffer_blue,false);
//-----------------yellow-----------------------
   ArraySetAsSeries(ExtMovingBuffer_yellow,false);
   ArraySetAsSeries(ExtUpperBuffer_yellow,false);
   ArraySetAsSeries(ExtLowerBuffer_yellow,false);
   ArraySetAsSeries(ExtStdDevBuffer_yellow,false);
//-----------------red-----------------------
   ArraySetAsSeries(ExtMovingBuffer_red,false);
   ArraySetAsSeries(ExtUpperBuffer_red,false);
   ArraySetAsSeries(ExtLowerBuffer_red,false);
   ArraySetAsSeries(ExtStdDevBuffer_red,false);
  
   ArraySetAsSeries(close,false);
//--- initial zero
   if(prev_calculated<1)
     {
     //---------tomato---------------------
      for(i=0; i<InpBandsPeriod; i++)
        {
         ExtMovingBuffer[i]=EMPTY_VALUE;
         ExtUpperBuffer[i]=EMPTY_VALUE;
         ExtLowerBuffer[i]=EMPTY_VALUE;
         //ExtMovingBuffer_blue[i]=EMPTY_VALUE;
        }
     //----------blue-----------------------
      for(i=0; i<InpBandsPeriod_blue; i++)
        {
         ExtMovingBuffer_blue[i]=EMPTY_VALUE;
         ExtUpperBuffer_blue[i]=EMPTY_VALUE;
         ExtLowerBuffer_blue[i]=EMPTY_VALUE;
         
        }
     //----------blue-----------------------
      for(i=0; i<InpBandsPeriod_yellow; i++)
        {
         ExtMovingBuffer_yellow[i]=EMPTY_VALUE;
         ExtUpperBuffer_yellow[i]=EMPTY_VALUE;
         ExtLowerBuffer_yellow[i]=EMPTY_VALUE;
         
        }
     //----------blue-----------------------
      for(i=0; i<InpBandsPeriod_red; i++)
        {
         ExtMovingBuffer_red[i]=EMPTY_VALUE;
         ExtUpperBuffer_red[i]=EMPTY_VALUE;
         ExtLowerBuffer_red[i]=EMPTY_VALUE;
         
        }
     }
//--- starting calculation
   if(prev_calculated>1)
      pos=prev_calculated-1;
   else
      pos=0;
//--- main cycle
   for(i=pos; i<rates_total && !IsStopped(); i++)
     {
      //------------tomato----------------
      //--- middle line
      ExtMovingBuffer[i]=SimpleMA(i,InpBandsPeriod,close);
      //--- calculate and write down StdDev
      ExtStdDevBuffer[i]=StdDev_Func(i,close,ExtMovingBuffer,InpBandsPeriod);
      //--- upper line
      ExtUpperBuffer[i]=ExtMovingBuffer[i]+InpBandsDeviations*ExtStdDevBuffer[i];
      //--- lower line
      ExtLowerBuffer[i]=ExtMovingBuffer[i]-InpBandsDeviations*ExtStdDevBuffer[i];
      //---
      
      //-------------blue--------------------------
      //--- middle line
      ExtMovingBuffer_blue[i]=SimpleMA(i,InpBandsPeriod_blue,close);
       //--- calculate and write down StdDev
      ExtStdDevBuffer_blue[i]=StdDev_Func(i,close,ExtMovingBuffer_blue,InpBandsPeriod_blue);
      //--- upper line
      ExtUpperBuffer_blue[i]=ExtMovingBuffer_blue[i]+InpBandsDeviations*ExtStdDevBuffer_blue[i];
      //--- lower line
      ExtLowerBuffer_blue[i]=ExtMovingBuffer_blue[i]-InpBandsDeviations*ExtStdDevBuffer_blue[i];
      
      //-------------yellow--------------------------
      //--- middle line
      ExtMovingBuffer_yellow[i]=SimpleMA(i,InpBandsPeriod_yellow,close);
       //--- calculate and write down StdDev
      ExtStdDevBuffer_yellow[i]=StdDev_Func(i,close,ExtMovingBuffer_yellow,InpBandsPeriod_yellow);
      //--- upper line
      ExtUpperBuffer_yellow[i]=ExtMovingBuffer_yellow[i]+InpBandsDeviations*ExtStdDevBuffer_yellow[i];
      //--- lower line
      ExtLowerBuffer_yellow[i]=ExtMovingBuffer_yellow[i]-InpBandsDeviations*ExtStdDevBuffer_yellow[i];
      
      //-------------red--------------------------
      //--- middle line
      ExtMovingBuffer_red[i]=SimpleMA(i,InpBandsPeriod_red,close);
       //--- calculate and write down StdDev
      ExtStdDevBuffer_red[i]=StdDev_Func(i,close,ExtMovingBuffer_red,InpBandsPeriod_red);
      //--- upper line
      ExtUpperBuffer_red[i]=ExtMovingBuffer_red[i]+InpBandsDeviations*ExtStdDevBuffer_red[i];
      //--- lower line
      ExtLowerBuffer_red[i]=ExtMovingBuffer_red[i]-InpBandsDeviations*ExtStdDevBuffer_red[i];
     }
//---- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Calculate Standard Deviation                                     |
//+------------------------------------------------------------------+
double StdDev_Func(int position,const double &price[],const double &MAprice[],int period)
  {
//--- variables
   double StdDev_dTmp=0.0;
//--- check for position
   if(position>=period)
     {
      //--- calcualte StdDev
      for(int i=0; i<period; i++)
         StdDev_dTmp+=MathPow(price[position-i]-MAprice[position],2);
      StdDev_dTmp=MathSqrt(StdDev_dTmp/period);
     }
//--- return calculated value
   return(StdDev_dTmp);
  }

