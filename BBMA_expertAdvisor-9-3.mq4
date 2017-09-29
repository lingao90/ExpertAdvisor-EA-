//+------------------------------------------------------------------+
//|                                         EA-2MACrossover_v1-0.mq4 |
//|                                                    Luca Spinello |
//|                                https://mql4tradingautomation.com |
//+------------------------------------------------------------------+

#property copyright     "Luca Spinello - mql4tradingautomation.com"
#property link          "https://mql4tradingautomation.com"
#property version       "1.00"
#property strict
#property description   "This Expert Advisor open orders at the crossover of two simple moving average (MA) indicators"
#property description   " "
#property description   "DISCLAIMER: This code comes with no guarantee, you can use it at your own risk"
#property description   "We recommend to test it first on a Demo Account"

/*
ENTRY BUY: when the fast MA crosses the slow from the bottom, both MA are going up
ENTRY SELL: when the fast MA crosses the slow from the top, both MA are going down
EXIT: Can be fixed pips (Stop Loss and Take Profit) or the entry signal for the next trade
Only 1 order at a time
*/


extern double LotSize=0.01;             //Position size

extern bool UseEntryToExit=true;       //Use next entry to close the trade (if false uses take profit)
//extern double StopLoss=20;             //Stop loss in pips
//extern double TakeProfit=50;           //Take profit in pips

extern int Slippage=2;                 //Slippage in pips

extern bool TradeEnabled=true;         //Enable trade

extern int MAFastPeriod=10;            //Fast moving average period
extern int MASlowPeriod=25;            //Slow moving average period

input int    InpBandsPeriod_tomato=60;      // Bands Period
input int    InpBandsShift=0;        // Bands Shift
input double InpBandsDeviations=1.0; // Bands Deviations

input int    InpBandsPeriod_blue=240;      // Bands Period
input int    InpBandsPeriod_yellow=480;      // Bands Period
input int    InpBandsPeriod_red=1440;      // Bands Period
//Functional variables
double ePoint;                         //Point normalized

bool CanOrder;                         //Check for risk management
bool CanOpenBuy;                       //Flag if there are buy orders open
bool CanOpenSell;                      //Flag if there are sell orders open

int OrderOpRetry=10;                   //Number of attempts to perform a trade operation
int SleepSecs=3;                       //Seconds to sleep if can't order
int MinBars=60;                        //Minimum bars in the graph to enable trading

//Functional variables to determine prices
double MinSL;
double MaxSL;
double TP;
double SL;
double Spread;
int Slip; 

int op_sell_start=0;
int count=0;
bool op_sell_started=false;
bool blue_flat_started=false;
bool yellow_flat_started=false;
bool red_flat_started=false;

bool yellow_reflat_started=false;
bool blue_reflat_started=false;
//Variable initialization function
void Initialize(){          
   RefreshRates();
   ePoint=Point;
   Slip=Slippage;
   if (MathMod(Digits,2)==1){
      ePoint*=10;
      Slip*=10;
   }
   //TP=TakeProfit*ePoint;
   //SL=StopLoss*ePoint;
   CanOrder=TradeEnabled;
   CanOpenBuy=true;
   CanOpenSell=true;
}


//Check if orders can be submitted
void CheckCanOrder(){            
   if( Bars<MinBars ){
      Print("INFO - Not enough Bars to trade");
      CanOrder=false;
   }
   OrdersOpen();
   return;
}


//Check if there are open orders and what type
void OrdersOpen(){
   for( int i = 0 ; i < OrdersTotal() ; i++ ) {
      if( OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) == false ) {
         Print("ERROR - Unable to select the order - ",GetLastError());
         break;
      } 
      if( OrderSymbol()==Symbol() && OrderType() == OP_BUY) CanOpenBuy=false;
      if( OrderSymbol()==Symbol() && OrderType() == OP_SELL) CanOpenSell=false;
   }
   return;
}


//Close all the orders of a specific type and current symbol
void CloseAll(int Command){
   double ClosePrice=0;
   for( int i = 0 ; i < OrdersTotal() ; i++ ) {
      if( OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) == false ) {
         Print("ERROR - Unable to select the order - ",GetLastError());
         break;
      }
      if( OrderSymbol()==Symbol() && OrderType()==Command) {
         if(Command==OP_BUY) ClosePrice=Bid;
         if(Command==OP_SELL) ClosePrice=Ask;
         double Lots=OrderLots();
         int Ticket=OrderTicket();
         for(int j=1; j<OrderOpRetry; j++){
            bool res=OrderClose(Ticket,Lots,ClosePrice,Slip,Red);
            if(res){
               Print("TRADE - CLOSE - Order ",Ticket," closed at price ",ClosePrice);
               break;
            }
            else Print("ERROR - CLOSE - error closing order ",Ticket," return error: ",GetLastError());
         }
      }
   }
   return;
}


//Open new order of a given type
void OpenNew(int Command){
   RefreshRates();
   double OpenPrice=0;
   double SLPrice;
   double TPPrice;
   if(Command==OP_BUY){
      OpenPrice=Ask;
      SLPrice=OpenPrice-SL;
      if(UseEntryToExit==false) TPPrice=OpenPrice+TP;
   }
   if(Command==OP_SELL){
      OpenPrice=Bid;
      SLPrice=OpenPrice+SL;
      if(UseEntryToExit==false) TPPrice=OpenPrice-TP;
   }
   for(int i=1; i<OrderOpRetry; i++){
      int res=OrderSend(Symbol(),Command,LotSize,OpenPrice,Slip,NormalizeDouble(SLPrice,Digits),NormalizeDouble(TPPrice,Digits),"",0,0,Green);
      if(res){
         Print("TRADE - NEW - Order ",res," submitted: Command ",Command," Volume ",LotSize," Open ",OpenPrice," Slippage ",Slip," Stop ",SLPrice," Take ",TPPrice);
         break;
      }
      else Print("ERROR - NEW - error sending order, return error: ",GetLastError());
   }
   return;
}


//Technical analysis of the indicators
bool CrossToBuy=false;
bool CrossToSell=false;

void CheckMACross(){
   CrossToBuy=false;
   CrossToSell=false;
   
   double BBtomato_main=iBands(Symbol(),0,InpBandsPeriod_tomato,InpBandsDeviations,InpBandsShift,PRICE_CLOSE,MODE_MAIN,0);
   double BBtomato_upper=iBands(Symbol(),0,InpBandsPeriod_tomato,InpBandsDeviations,InpBandsShift,PRICE_CLOSE,MODE_UPPER,0);
   double BBtomato_lower=iBands(Symbol(),0,InpBandsPeriod_tomato,InpBandsDeviations,InpBandsShift,PRICE_CLOSE,MODE_LOWER,0);
   
   double BBblue_main=iBands(Symbol(),0,InpBandsPeriod_blue,InpBandsDeviations,InpBandsShift,PRICE_CLOSE,MODE_MAIN,0);
   double BBblue_upper=iBands(Symbol(),0,InpBandsPeriod_blue,InpBandsDeviations,InpBandsShift,PRICE_CLOSE,MODE_UPPER,0);
   double BBblue_upper_prev_1=iBands(Symbol(),0,InpBandsPeriod_blue,InpBandsDeviations,InpBandsShift,PRICE_CLOSE,MODE_UPPER,1);
   double BBblue_upper_prev_2=iBands(Symbol(),0,InpBandsPeriod_blue,InpBandsDeviations,InpBandsShift,PRICE_CLOSE,MODE_UPPER,2);
   double BBblue_upper_prev_3=iBands(Symbol(),0,InpBandsPeriod_blue,InpBandsDeviations,InpBandsShift,PRICE_CLOSE,MODE_UPPER,3);
   double BBblue_upper_prev_4=iBands(Symbol(),0,InpBandsPeriod_blue,InpBandsDeviations,InpBandsShift,PRICE_CLOSE,MODE_UPPER,4);
   double BBblue_upper_prev_5=iBands(Symbol(),0,InpBandsPeriod_blue,InpBandsDeviations,InpBandsShift,PRICE_CLOSE,MODE_UPPER,5);
   double BBblue_lower=iBands(Symbol(),0,InpBandsPeriod_blue,InpBandsDeviations,InpBandsShift,PRICE_CLOSE,MODE_LOWER,0);
   
   double BByellow_main=iBands(Symbol(),0,InpBandsPeriod_yellow,InpBandsDeviations,InpBandsShift,PRICE_CLOSE,MODE_MAIN,0);
   double BByellow_upper=iBands(Symbol(),0,InpBandsPeriod_yellow,InpBandsDeviations,InpBandsShift,PRICE_CLOSE,MODE_UPPER,0);
   double BByellow_lower=iBands(Symbol(),0,InpBandsPeriod_yellow,InpBandsDeviations,InpBandsShift,PRICE_CLOSE,MODE_LOWER,0);
   
   double BBred_main=iBands(Symbol(),0,InpBandsPeriod_red,InpBandsDeviations,InpBandsShift,PRICE_CLOSE,MODE_MAIN,0);
   double BBred_upper=iBands(Symbol(),0,InpBandsPeriod_red,InpBandsDeviations,InpBandsShift,PRICE_CLOSE,MODE_UPPER,0);
   double BBred_lower=iBands(Symbol(),0,InpBandsPeriod_red,InpBandsDeviations,InpBandsShift,PRICE_CLOSE,MODE_LOWER,0);
   
   double MAtomato=iMA(Symbol(),0,InpBandsPeriod_tomato,0,MODE_SMA,PRICE_CLOSE,0);
   double MAtomato_prev=iMA(Symbol(),0,InpBandsPeriod_tomato,0,MODE_SMA,PRICE_CLOSE,1);
   double MAtomato_prev_2=iMA(Symbol(),0,InpBandsPeriod_tomato,0,MODE_SMA,PRICE_CLOSE,2);
   double MAtomato_prev_3=iMA(Symbol(),0,InpBandsPeriod_tomato,0,MODE_SMA,PRICE_CLOSE,3);
   double MAtomato_prev_4=iMA(Symbol(),0,InpBandsPeriod_tomato,0,MODE_SMA,PRICE_CLOSE,4);
   double MAtomato_prev_5=iMA(Symbol(),0,InpBandsPeriod_tomato,0,MODE_SMA,PRICE_CLOSE,5);
   
   double MAblue=iMA(Symbol(),0,InpBandsPeriod_blue,0,MODE_SMA,PRICE_CLOSE,0);
   double MAblue_prev=iMA(Symbol(),0,InpBandsPeriod_blue,0,MODE_SMA,PRICE_CLOSE,1);
   
   double MAyellow=iMA(Symbol(),0,InpBandsPeriod_yellow,0,MODE_SMA,PRICE_CLOSE,0);
   double MAyellow_prev=iMA(Symbol(),0,InpBandsPeriod_yellow,0,MODE_SMA,PRICE_CLOSE,1);
   
   double MAred=iMA(Symbol(),0,InpBandsPeriod_red,0,MODE_SMA,PRICE_CLOSE,0);
   double MAred_prev=iMA(Symbol(),0,InpBandsPeriod_red,0,MODE_SMA,PRICE_CLOSE,1);
      bool trade_sell=true;
   if(BBblue_upper_prev_2==0 || MAtomato_prev_2==0 || MAtomato==0 || BBblue_upper==0 || MAyellow==0)
           trade_sell=false;
   //if(trade_sell && BBblue_upper_prev_2<MAtomato_prev_2 && MAtomato<BBblue_upper){
   if(trade_sell && BBblue_upper_prev_5<MAtomato_prev_5 && MAflat(MAtomato , MAtomato_prev)){
      op_sell_started=true;
      
         string TradeName="Trade SELL";
         SL=High[0];
         TP=MAyellow;
         CrossToSell=true;
   }
   //if(op_sell_started && MAflat(MAtomato , MAtomato_prev))
   //ShowTrade_Name("TradeName");
   //------------1hr->4hr-------------------//
   if( op_sell_started && MAflat(MAblue , MAblue_prev) ){
      op_sell_started=false;
      blue_flat_started=true;
      
   }
   //------------4hr->8hr --------------------//
   if(blue_flat_started && MAflat(MAyellow , MAyellow_prev)){
      blue_flat_started=false;
      yellow_flat_started=true;
      SL=Low[0];
      TP=BByellow_main; 
      CrossToBuy=true;
   }
   //------------8hr->daily ------------------//
   if(yellow_flat_started && MAflat(MAred , MAred_prev)){
      yellow_flat_started=false;
      red_flat_started=true;
      string TradeName="Trade BUY";
      //-----------------OP_buy start ------------------------------//
      //SL=Low[0];
      //TP=BByellow_main; 
      //CrossToBuy=true;
   }
   
   //if(BBblue_upper_prev_2<MAtomato_prev_2 && MAtomato<BBblue_upper){
   //   SL=Low[0];
   //   TP=BByellow_main;
   //   CrossToBuy=true;
   //}

}

bool MAflat(double cur_val , double perv_val){
   const int RANGE=10;
   //bool find=false;
   if(cur_val < perv_val){
      count++;
      if(count < RANGE)
      //find=false;
      return false;
      if( count > RANGE)
      //find=true;
      return true;
   }else{
      count=0;
   }
   //if(find){
   //   ShowTrade_Name("TradeName");
   //}
   return false;
}

void ShowTrade_Name(string TradeName)
{
   //flag = percent > 0 ? 2 : 1;
   string namastring = WindowExpertName()+"-TradeName";
   string isistring = "TradeName";
   isistring = TradeName;
   //if(flag==1) isistring = "CurrentLoss : "+DoubleToStr(percent,2) + "%";
   if (ObjectFind(namastring) > -1) ObjectDelete(namastring);
   ObjectCreate(namastring, OBJ_LABEL, 0, 0, 0 );
   ObjectSetText(namastring, isistring, 15, "Arial", Red);
   ObjectSet(namastring, OBJPROP_CORNER, 3 );
   ObjectSet(namastring, OBJPROP_XDISTANCE, 90 );
   ObjectSet(namastring, OBJPROP_YDISTANCE, 50 );
   ObjectSet(namastring, OBJPROP_BACK, true );
}



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   //Calling initialization, checks and technical analysis
   Initialize();
   CheckCanOrder();
   CheckMACross();
   //Check of Entry/Exit signal with operations to perform
   if(CrossToBuy){
      if(UseEntryToExit) CloseAll(OP_SELL);
      if(CanOpenBuy && CanOpenSell && CanOrder) OpenNew(OP_BUY);
   }
   if(CrossToSell){
      if(UseEntryToExit) CloseAll(OP_BUY);
      if(CanOpenSell && CanOpenBuy && CanOrder) OpenNew(OP_SELL);
   }
  }
//+------------------------------------------------------------------+
