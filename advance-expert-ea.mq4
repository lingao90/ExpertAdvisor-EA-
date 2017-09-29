//+------------------------------------------------------------------+
//|                                            advance-expert-ea.mq4 |
//|                                                         don.chan |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "don.chan"
#property link      "https://www.mql5.com"
#property version   "1.00"

#property description "SUPSTANCE_EA"
#property version "2.00"

#property strict

input string   ADVISOR_NAME         = "RANGE-BREAKOUT_EA_";
input string   VERSION              = "PERIOD_RANGING_PRO";
input string   AUTHOR               = "OLADEJO_Olusegun@IDQFX";
//***************************************************************
input double Profit   = 2.0;
input double Loss     = 5.0;


//***************************************************************

input string   SECTION_ONE          = "********************************************************";
input string   MONEY_MANAGEMENT     = "_";
input bool     AutoLots             = false;
input string   BALANCEPLUS          = "_"; //BALANCE+
input double   Risk_Ratio           = 0.01;
input double   Risk_Capital         = 100;
input double   Starting_Lotsize     = 0.01;
input double   Lot_Increase         = 0.01;
input double   Max_Starting_Lotsize = 10; //Max._Starting_Lotsize

enum enyn {Yes=0, No=1};
input string   SECTION_TWO          = "********************************************************";
input string   ORDER_MANAGEMENT     = "_";
input enyn     TradeOnMonday        = Yes;
input enyn     TradeOnTuesday       = Yes;
input enyn     TradeOnWednesday     = Yes;
input enyn     TradeOnThurstday     = Yes;
input enyn     TradeOnFriday        = Yes;
input enyn      ShowPairSpread       = Yes;

input string   Box_Start_Time       = "00:00";
input string   Box_End_Time         = "06:00";
input double   Max_Box_Height       = 30;

input double   Min_Box_Height       = 20;
input double   Offset               = 5; //Offset(From S/R)
input double   Starting_TP          = 40;
input double   TP_Step              = 10;
input double   Max_TP               = 300;
input double   StopLoss             = 20;
input int      RecoveryAt           = 10;
input double   AddSLPips            = 2;
input bool     AutomaticSLPips      = True;
input double   MaxSpread            = 4;
input int      Slippage             = 4;
input int      Requote_Attempts     = 40;

input string   SECTION_THREE        = "********************************************************";
input string   TRADE_MANAGEMENT     = "_";
input bool     Stealth              = True;
input bool     ECN_Broker           = True;
input bool     Show_Barrier         = True;
enum enLst {Four=4, //4
            Five=5 //5
            };
input enLst    BrokerDigit          = Five;
input int      Magic                = 554310;
input bool     UseBEP               = false;
input double   BEPPips              = 20;

double BEPOffset                  = 0;
double MyPoin;
int NewDay;
bool BoxDraw;
int TotalMarket,TotalCount,BuyCount,SellCount,TotalPending,BuyLimitCount,SellLimitCount,BuyStopCount,SellStopCount;
int Slip;
string LastComm;
double LastLots;
double LastProfit;
bool CanTrade;
bool TradeBar;
int NewBar;
int Requote = 0;
double StealthTP, StealthSL;
double MyHigh, MyLow;
double Resistant, Support;
bool NewCycle;
double Spread;
//**************************dorin******************************************
double Balance,TargetEquity,TargetEquity_profit,TargetEquity_loss,Equity,currentProfit,currentLoss,percent,Tmp_Balance;
int flag = 0;
bool NextDay;
//********************************************************************


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   MyPoin = Point;
   Slip = Slippage;
   if (BrokerDigit == Five)
   {
      MyPoin = Point*10;
      Slip = Slippage*10;
   }
   
   int X1Off = 10;
   int YOff = 3;
   int Line = 0;
   int LineDist = 20;
   //*********************dorin****************************
   Balance = AccountBalance();
   Tmp_Balance = 0;
   NextDay = true;
   //*************************************************

   Line++;
   PrintLabel(WindowExpertName()+"LineX1"+IntegerToString(Line),VERSION,X1Off,YOff+Line*LineDist,PaleGoldenrod);
   Line++;
   PrintLabel(WindowExpertName()+"LineX1"+IntegerToString(Line),AUTHOR,X1Off,YOff+Line*LineDist,PaleGoldenrod);
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//---
   Comment("");
   DeleteInfo();
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---
   CheckOpened();
   
   if (TotalMarket == 0)
   {
      LastComm = "";
      LastLots = 0;
      LastProfit = 0;
      CheckHistory();
   }
   
   if (NewDay != iBars(NULL,PERIOD_D1))
   {
      NewDay = iBars(NULL,PERIOD_D1);
      if (TotalMarket == 0 && (LastProfit > 0 || LastComm == ""))
      {
         BoxDraw = false;
      }
   }
   if (NewBar != iBars(NULL,0))
   {
      NewBar = iBars(NULL,0);
      TradeBar = false;
   }
   
   datetime Start = StrToTime(Box_Start_Time);
   datetime End = StrToTime(Box_End_Time);
   int BarStart, BarEnd;
   BarStart = iBarShift(Symbol(),0,Start);
   BarEnd = iBarShift(Symbol(),0,End);
   
   bool DayTrade = true;
   if (TimeDayOfWeek(TimeCurrent()) == 1 && TradeOnMonday == No) DayTrade = false;
   if (TimeDayOfWeek(TimeCurrent()) == 2 && TradeOnTuesday == No) DayTrade = false;
   if (TimeDayOfWeek(TimeCurrent()) == 3 && TradeOnWednesday == No) DayTrade = false;
   if (TimeDayOfWeek(TimeCurrent()) == 4 && TradeOnThurstday == No) DayTrade = false;
   if (TimeDayOfWeek(TimeCurrent()) == 5 && TradeOnFriday == No) DayTrade = false;
   
   if (!BoxDraw && TimeCurrent() > End)
   {
      MyHigh = High[Highest(Symbol(), 0, MODE_HIGH, BarStart-BarEnd+1, BarEnd)];
      MyLow = Low[Lowest(Symbol(), 0, MODE_LOW, BarStart-BarEnd+1, BarEnd)];
      Support = MyLow - Offset*MyPoin;
      Resistant = MyHigh + Offset*MyPoin;
   }
   bool Trade = False;
   if (MyHigh-MyLow < Max_Box_Height*MyPoin)
   {
      Trade = True;
      //Comment("");
   }
   else Trade = false;
   //Comment("Range Size = "+DoubleToStr((MyHigh-MyLow)/MyPoin));
   
   if (TotalMarket == 0 && !CanTrade)
   {
      if (Close[0] < Resistant && Close[0] > Support) CanTrade = true;
      else CanTrade = false;
   }
   if (TotalMarket > 0 && CanTrade) CanTrade = false;
   
   if (!Trade)
   {
      CanTrade = false;
      //Comment("Range is exceeded the limit");
   }
   
   Spread = (Ask-Bid)/MyPoin;
   bool TradeAllow = true;
   if (Spread >= 4) TradeAllow = false;
   if (ShowPairSpread == Yes) ShowSpread();
   //************************************Dorin*************************************
    Equity = AccountEquity();
    percent =100*((Equity - Balance)/Balance);
   if(percent>0){
      Balance = Balance+Tmp_Balance;
      //TargetEquity = Balance+Balance*(Profit/100);
      TargetEquity_profit = Balance+Balance*(Profit/100);
      TargetEquity_loss = Balance-Balance*(Loss/100);
   }else{
      Balance = Balance-Tmp_Balance;
      //TargetEquity = Balance-Balance*(Loss/100);
      TargetEquity_profit = Balance+Balance*(Profit/100);
      TargetEquity_loss = Balance-Balance*(Loss/100);
   }
   
   ShowTargetEquity(TargetEquity_loss,TargetEquity_profit);
   ShowBalance(Balance);
   ShowProfit_Loss_Text();
   ShowProfit_Loss_calculation_Text();
   //ShowPercent(percent);
   if(percent<Loss*(-1.0) || percent>Profit*1.0){
     TradeAllow = false; //TradeNow = false; 
     NewCycle = false; 
     NextDay = false;
     //ExitNow = true;
     if(percent<0){
      Tmp_Balance = Balance*(Loss/100);
     }else{
      Tmp_Balance = Balance*(Profit/100);
     }
     
    // showCloseResult(percent, Equity - Balance);
   }
   if(Hour()==23 && Minute()==59){
      NextDay = true;
   }
   if(NextDay){
      TradeAllow = true;
      Trade = true;
   }else{
      TradeAllow = false;
      Trade = false;
   }
   //************************************************************************

   if (TradeAllow && Trade && TimeCurrent() > End && !BoxDraw)
   {
      if (Show_Barrier)
      {
         string Box1 = "Rect1";
         ObjectDelete(Box1);
         ObjectCreate(ChartID(),Box1,OBJ_RECTANGLE,0,iTime(Symbol(),0,BarStart),Support,iTime(Symbol(),0,BarEnd),Resistant);
         ObjectSet(Box1,OBJPROP_COLOR,Green);
         string Box2 = "Rect2";
         ObjectDelete(Box2);
         ObjectCreate(ChartID(),Box2,OBJ_RECTANGLE,0,iTime(Symbol(),0,BarStart),MyLow,iTime(Symbol(),0,BarEnd),MyHigh);
         ObjectSet(Box2,OBJPROP_COLOR,Yellow);
         string Line1 = "Resistant";
         ObjectDelete(Line1);
         ObjectCreate(ChartID(),Line1,OBJ_TREND,0,iTime(Symbol(),PERIOD_D1,0),Resistant,iTime(Symbol(),PERIOD_D1,0)+86400,Resistant);
         ObjectSet(Line1,OBJPROP_RAY,True);
         ObjectSet(Line1,OBJPROP_COLOR,Yellow);
         ObjectSet(Line1,OBJPROP_STYLE,STYLE_DASHDOT);
         ObjectSetText(Line1,"Resistant",11,"Arial",Yellow);
         string Line2 = "Support";
         ObjectDelete(Line2);
         ObjectCreate(ChartID(),Line2,OBJ_TREND,0,iTime(Symbol(),PERIOD_D1,0),Support,iTime(Symbol(),PERIOD_D1,0)+86400,Support);
         ObjectSet(Line2,OBJPROP_RAY,True);
         ObjectSet(Line2,OBJPROP_COLOR,Yellow);
         ObjectSet(Line2,OBJPROP_STYLE,STYLE_DASHDOT);
         ObjectSetText(Line2,"Support",11,"Arial",Yellow);
      }
      BoxDraw = true;
      NewCycle = true;
   }
   
   string Signal = "";
   if (CanTrade && TotalMarket == 0)
   {
      if (Close[0] >= Resistant) Signal = "Buy";
      if (Close[0] <= Support) Signal = "Sell";
   }
   //Comment("\n",CanTrade,"\n",Signal);
   if (Signal != "")
   {
      if (NewCycle)
      {
         double Lots = Starting_Lotsize;
         if (AutoLots)
         {
            Lots = NormalizeDouble(MathFloor(AccountBalance()*Risk_Ratio),0)/Risk_Capital;
            double MinLot = MarketInfo(Symbol(),MODE_MINLOT);
            if (Lots < MinLot) Lots = MinLot;
            if (Lots > Max_Starting_Lotsize) Lots = Max_Starting_Lotsize;
         }
         bool Sent = false;
         if (Signal == "Buy" && Requote < Requote_Attempts && DayTrade) Sent = SendOrder(OP_BUY,Lots,Starting_TP,StopLoss,"1");
         if (Signal == "Sell" && Requote < Requote_Attempts && DayTrade) Sent = SendOrder(OP_SELL,Lots,Starting_TP,StopLoss,"1");
         if (Sent)
         {
            NewCycle = false;
         }
         return;
      }
      else
      {
         if (LastProfit <= 0 && LastComm != "")
         {
            int LastLevel = StrToInteger(LastComm);
            string NewLevel = IntegerToString(LastLevel+1);
            double New_TP = 0;
            New_TP = Starting_TP+LastLevel*TP_Step;
            if (New_TP > Max_TP) New_TP = Max_TP;
            double Lots = LastLots + Lot_Increase;
            bool Sent = false;
            if (Signal == "Buy" && Requote < Requote_Attempts) Sent = SendOrder(OP_BUY,Lots,New_TP,StopLoss,NewLevel);
            if (Signal == "Sell" && Requote < Requote_Attempts) Sent = SendOrder(OP_SELL,Lots,New_TP,StopLoss,NewLevel);
            return;
         }
      }
   }
   if (Stealth && TotalMarket > 0) CheckToCloseOrder();
   if (UseBEP) CheckBEP();
}
//+------------------------------------------------------------------+
//******************************Dorin**********************************************
void ShowPercent(double percent)
{
   flag = percent > 0 ? 2 : 1;
   string namastring = WindowExpertName()+"-Percent";
   string isistring = "Percent";
   if(flag==2) isistring = "CurrentProfit : "+DoubleToStr(percent,2) + "%";
   if(flag==1) isistring = "CurrentLoss : "+DoubleToStr(percent,2) + "%";
   if (ObjectFind(namastring) > -1) ObjectDelete(namastring);
   ObjectCreate(namastring, OBJ_LABEL, 0, 0, 0 );
   ObjectSetText(namastring, isistring, 15, "Arial", White);
   ObjectSet(namastring, OBJPROP_CORNER, 3 );
   ObjectSet(namastring, OBJPROP_XDISTANCE, 30 );
   ObjectSet(namastring, OBJPROP_YDISTANCE, 100 );
   ObjectSet(namastring, OBJPROP_BACK, true );
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void ShowTargetEquity(double targetEquity_loss,double targetEquity_profit)
{
   //flag = percent > 0 ? 2 : 1;
   string namastring = WindowExpertName()+"-TargetEquity";
   string isistring = "TargetEquity";
   isistring = "TargetEquity   "+DoubleToStr(targetEquity_profit,2) + " | "+DoubleToStr(targetEquity_loss,2);
   //if(flag==1) isistring = "CurrentLoss : "+DoubleToStr(percent,2) + "%";
   if (ObjectFind(namastring) > -1) ObjectDelete(namastring);
   ObjectCreate(namastring, OBJ_LABEL, 0, 0, 0 );
   ObjectSetText(namastring, isistring, 15, "Arial", White);
   ObjectSet(namastring, OBJPROP_CORNER, 3 );
   ObjectSet(namastring, OBJPROP_XDISTANCE, 30 );
   ObjectSet(namastring, OBJPROP_YDISTANCE, 140 );
   ObjectSet(namastring, OBJPROP_BACK, true );
}
//+------------------------------------------------------------------+
void ShowBalance(double balance)
{
   //flag = percent > 0 ? 2 : 1;
   string namastring = WindowExpertName()+"-Balance";
   string isistring = "Balance";
   isistring = "Balance  "+DoubleToStr(balance,2) + " |"+" "+DoubleToStr(balance,2);
   //if(flag==1) isistring = "CurrentLoss : "+DoubleToStr(percent,2) + "%";
   if (ObjectFind(namastring) > -1) ObjectDelete(namastring);
   ObjectCreate(namastring, OBJ_LABEL, 0, 0, 0 );
   ObjectSetText(namastring, isistring, 15, "Arial", White);
   ObjectSet(namastring, OBJPROP_CORNER, 3 );
   ObjectSet(namastring, OBJPROP_XDISTANCE, 30 );
   ObjectSet(namastring, OBJPROP_YDISTANCE, 170 );
   ObjectSet(namastring, OBJPROP_BACK, true );
}
//+------------------------------------------------------------------+
void ShowProfit_Loss_Text()
{
   //flag = percent > 0 ? 2 : 1;
   string namastring = WindowExpertName()+"-Profit_Loss_Text";
   string isistring = "-Profit_Loss_Text";
   isistring = "Profit   |  "+" Loss  ";
   //if(flag==1) isistring = "CurrentLoss : "+DoubleToStr(percent,2) + "%";
   if (ObjectFind(namastring) > -1) ObjectDelete(namastring);
   ObjectCreate(namastring, OBJ_LABEL, 0, 0, 0 );
   ObjectSetText(namastring, isistring, 17, "Arial", White);
   ObjectSet(namastring, OBJPROP_CORNER, 3 );
   ObjectSet(namastring, OBJPROP_XDISTANCE, 30 );
   ObjectSet(namastring, OBJPROP_YDISTANCE, 200 );
   ObjectSet(namastring, OBJPROP_BACK, true );
}
//+------------------------------------------------------------------+
void ShowProfit_Loss_calculation_Text()
{
   //flag = percent > 0 ? 2 : 1;
   string namastring = WindowExpertName()+"-Profit_Loss_calculation_Text";
   string isistring = "-Profit_Loss_calculation_Text";
   isistring = "PROFIT/LOSS CALCULATION";
   //if(flag==1) isistring = "CurrentLoss : "+DoubleToStr(percent,2) + "%";
   if (ObjectFind(namastring) > -1) ObjectDelete(namastring);
   ObjectCreate(namastring, OBJ_LABEL, 0, 0, 0 );
   ObjectSetText(namastring, isistring, 15, "Arial", White);
   ObjectSet(namastring, OBJPROP_CORNER, 3 );
   ObjectSet(namastring, OBJPROP_XDISTANCE, 30 );
   ObjectSet(namastring, OBJPROP_YDISTANCE, 230 );
   ObjectSet(namastring, OBJPROP_BACK, true );
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void ShowSpread()
{
   string namastring = WindowExpertName()+"-Spread";
   string isistring = "Spread";
   isistring = "Spread : "+DoubleToStr((Ask-Bid)/Point,0);
   if (ObjectFind(namastring) > -1) ObjectDelete(namastring);
   ObjectCreate(namastring, OBJ_LABEL, 0, 0, 0 );
   ObjectSetText(namastring, isistring, 15, "Arial", White);
   ObjectSet(namastring, OBJPROP_CORNER, 3 );
   ObjectSet(namastring, OBJPROP_XDISTANCE, 25 );
   ObjectSet(namastring, OBJPROP_YDISTANCE, 10 );
   ObjectSet(namastring, OBJPROP_BACK, true );
}
//+------------------------------------------------------------------+


//********************************************************************************

void CheckOpened()
{
   TotalMarket = 0;
   TotalCount = 0;
   BuyCount = 0;
   SellCount = 0;
   TotalPending = 0;
   BuyLimitCount = 0;
   SellLimitCount = 0;
   BuyStopCount = 0;
   SellStopCount = 0;
   for (int i=0; i<OrdersTotal(); i++)
   {
      if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic)
         {
            if (OrderType() == OP_BUY) BuyCount++;
            if (OrderType() == OP_SELL) SellCount++;
            if (OrderType() == OP_BUYLIMIT) BuyLimitCount++;
            if (OrderType() == OP_BUYSTOP) BuyStopCount++;
            if (OrderType() == OP_SELLLIMIT) SellLimitCount++;
            if (OrderType() == OP_SELLSTOP) SellStopCount++;
         }
      }
   }
   TotalPending = BuyLimitCount + BuyStopCount + SellLimitCount + SellStopCount;
   TotalMarket = BuyCount + SellCount;
   TotalCount = TotalMarket + TotalPending;
}
//+------------------------------------------------------------------+
void CheckHistory()
{
   datetime ClosedTime = 0;
   for (int i=0; i<OrdersHistoryTotal(); i++)
   {
      if (OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
      {
         if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic && ClosedTime < OrderCloseTime())
         {
            ClosedTime = OrderCloseTime();
            LastComm = OrderComment();
            LastLots = OrderLots();
            LastProfit = OrderProfit();
         }
      }
   }
}
//+------------------------------------------------------------------+
bool SendOrder(int Type, double Size, double TP, double SL, string OrdComment)
{
   bool Res = false;
   color Colour = Gray;
   double Price = 0;
   double OrderTP=0, OrderSL=0;
   int Level = StrToInteger(Split(OrdComment,"|",0));
   if (Level >= RecoveryAt)
   {
      TP = SL*(Level-1)*0.5+AddSLPips;
      if (AutomaticSLPips) TP = SL*(Level-1)*0.5 + (Level-1)*Spread;
      if (TP > Max_TP) TP = Max_TP;
   }
   if (Type == OP_BUY)
   {
      Price = Ask;
      Colour = Blue;
      if (!ECN_Broker && !Stealth)
      {
         OrderTP = Ask+TP*MyPoin;
         OrderSL = Bid-SL*MyPoin;
         StealthTP = OrderTP;
         StealthSL = OrderSL;
      }
   }
   else if (Type == OP_SELL)
   {
      Price = Bid;
      Colour = Red;
      if (!ECN_Broker && !Stealth)
      {
         OrderTP = Bid-TP*MyPoin;
         OrderSL = Ask+SL*MyPoin;
         StealthTP = OrderTP;
         StealthSL = OrderSL;
      }
   }
   
   int Tiket = -1;
   Tiket = OrderSend(Symbol(),Type,Size,Price,Slip,OrderSL,OrderTP,OrdComment,Magic,0,Colour);
   if (Tiket > -1)
   {
      TradeBar = true;
      Requote = 0;
      Res = true;
      if (ECN_Broker && !Stealth)
      {
         if (OrderSelect(Tiket,SELECT_BY_TICKET,MODE_TRADES))
         {
            OrderSL = 0;
            OrderTP = 0;
            if (Type == OP_BUY)
            {
               if (SL > 0) OrderSL = OrderOpenPrice()-SL*MyPoin;
               if (TP > 0) OrderTP = OrderOpenPrice()+TP*MyPoin;
            }
            if (Type == OP_SELL)
            {
               if (SL > 0) OrderSL = OrderOpenPrice()+SL*MyPoin;
               if (TP > 0) OrderTP = OrderOpenPrice()-TP*MyPoin;
            }
            bool Modif = false;
            Modif = OrderModify(OrderTicket(),OrderOpenPrice(),OrderSL,OrderTP,0,Colour);
         }
      }
      if (Stealth)
      {
         if (OrderSelect(Tiket,SELECT_BY_TICKET,MODE_TRADES))
         {
            if (Type == OP_BUY)
            {
               StealthSL = OrderOpenPrice()-SL*MyPoin;
               StealthTP = OrderOpenPrice()+TP*MyPoin;
            }
            if (Type == OP_SELL)
            {
               StealthSL = OrderOpenPrice()+SL*MyPoin;
               StealthTP = OrderOpenPrice()-TP*MyPoin;
            }
         }
      }
   }
   else
   {
      int LastError = GetLastError();
      if (LastError == 136 || LastError == 138) Requote++;
   }
   return Res;
}
//+------------------------------------------------------------------+
void CheckToCloseOrder()
{
   for(int i=0; i<OrdersTotal(); i++)
   {
      if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic)
         {
            if (OrderType() == OP_BUY)
            {
               if (Bid >= StealthTP || Bid <= StealthSL)
               {
                  bool Clsd = false;
                  Clsd = OrderClose(OrderTicket(),OrderLots(),Bid,Slip,Blue);
               }
            }
            if (OrderType() == OP_SELL)
            {
               if (Ask <= StealthTP || Ask >= StealthSL)
               {
                  bool Clsd = false;
                  Clsd = OrderClose(OrderTicket(),OrderLots(),Ask,Slip,Red);
               }
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
void CheckBEP()
{
   for (int i=0; i<OrdersTotal(); i++)
   {
      if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic)
         {
            if (OrderType() == OP_BUY)
            {
               double BEP = OrderOpenPrice()+BEPPips*MyPoin;
               if (Bid >= BEP && OrderStopLoss() < OrderOpenPrice()+BEPOffset*MyPoin)
               {
                  bool Modif = false;
                  Modif = OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,Blue);
               }
            }
            if (OrderType() == OP_SELL)
            {
               double BEP = OrderOpenPrice()-BEPPips*MyPoin;
               if (Ask <= BEP && (OrderStopLoss() > OrderOpenPrice()-BEPOffset*MyPoin || OrderStopLoss() == 0))
               {
                  bool Modif = false;
                  Modif = OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,Red);
               }
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
void PrintLabel( string namastring, string isistring, int xoff, int yoff, color Warna) 
{
   if (ObjectFind(namastring) > -1) ObjectDelete(namastring);
   ObjectCreate(namastring, OBJ_LABEL, 0, 0, 0 );
   ObjectSetText(namastring, isistring, 9, "Arial", Warna);
   ObjectSet(namastring, OBJPROP_CORNER, 1 );
   ObjectSet(namastring, OBJPROP_XDISTANCE, xoff );
   ObjectSet(namastring, OBJPROP_YDISTANCE, yoff );
   ObjectSet(namastring, OBJPROP_BACK, true );
}
//+------------------------------------------------------------------+
void DeleteInfo()
{
   string Name;
   string Part = WindowExpertName();
   int TotObj = 1;
   while(TotObj > 0)
   {
      TotObj = 0;
      for (int i=0; i<ObjectsTotal(); i++)
      {
         Name = ObjectName(ChartID(),i,0,-1);
         if (StringFind(Name,Part,0) > -1)
         {
            ObjectDelete(ChartID(),Name);
            TotObj++;
         }
      }
   }
}
//+------------------------------------------------------------------+
string Split(string word, string sep, int index)
{
    int count  = 0;
    int oldpos = 0;
    int pos    = StringFind(word, sep, 0);
    while (pos >= 0 && count <= index)
    {
        if (count == index)
        {
            if (pos == oldpos)
            {
                return("");
            }
            else
            {
                return(StringSubstr(word, oldpos, pos - oldpos));
            }
        }
        oldpos = pos + StringLen(sep);
        pos    = StringFind(word, sep, oldpos);
        count++;
    }
    if (count == index)
    {
        return(StringSubstr(word, oldpos));
    }
    return("");
}
//+------------------------------------------------------------------+