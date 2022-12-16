

#property copyright "Copyright 2010, MetaQuotes Software Corp."

#property link      "http://www.mql5.com"

#property version   "1.00"
#include <Trade/Trade.mqh>
#include <Expert/Trailing/TrailingMA.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>
//--- input parameters
input group "Trading Input";
input int      StopLoss=30;      // Stop Loss
input double   Lot=0.1;  
input int      TakeProfit=100;   // Take Profit
input int      EA_Magic=12345;   // EA Magic Number
input group "Indicator Input";
input int      ADX_Period=8;     // ADX Period
input int      MA_Period=8;      // Moving Average Period
input int      ATR_Period = 14;
input double   Adx_Min=22.0;     // Minimum ADX Value

        // Lots to Trade

input double SlDist = 20;
input double TpDist = 50;
input double rsiMax = 80;
input double rsiMin = 20;
input int trailingStopLossPer =  70; // test per % trailing stop loss
//--- Other parameters

int adxHandle; // handle for our ADX indicator
int maHandle;  // handle for our Moving Average indicator
int rsiHandle;
double plsDI[],minDI[],adxVal[]; // Dynamic arrays to hold the values of +DI, -DI and ADX values for each bars

double maVal[]; // Dynamic array to hold the values of Moving Average for each bars

double p_close; // Variable to store the close value of a bar

int STP, TKP;   // To be used for Stop Loss & Take Profit values

int zigzagHandle;
double rsiVal[];
int  atrHandle;
double atrValue[];
double zigzagVal[];
CTrade mytrade;
CSymbolInfo mysymbol;
CAccountInfo myAccount;
CPositionInfo postionInfo;
void CloseAll()

{
   while(PositionsTotal()>0) {
      for (int i=PositionsTotal()-1; i>=0; i--)

      {

         PositionSelect(PositionGetSymbol(i));
         mytrade.PositionClose(PositionGetTicket(i),10);

         
      }
   }
}
//+----------------int--------------------------------------------------+

//| Expert initialization function                                   |

//+------------------------------------------------------------------+
int OnInit()

{

//--- Get handle for ADX indicator
   mytrade.SetAsyncMode(true);
   
   mytrade.LogLevel(0);
   rsiHandle = iRSI(_Symbol,PERIOD_CURRENT, 14,PRICE_CLOSE);
   adxHandle=iADX(NULL,0,ADX_Period);
   atrHandle = iATR(NULL,PERIOD_CURRENT, 14 );
   
   zigzagHandle = iCustom( NULL, 0, "Examples/ZigZag",12,5,3 );

//--- Get the handle for Moving Average indicator

   maHandle=iMA(_Symbol,_Period,MA_Period,0,MODE_EMA,PRICE_CLOSE);
   
   //iBands(_Symbol , _Period , )

//--- What if handle returns Invalid Handle

   if(adxHandle<0 || maHandle<0 )

   {

      Alert("Error Creating Handles for indicators - error: ",GetLastError(),"!!");

      return(-1);

   }



//--- Let us handle currency pairs with 5 or 3 digit prices instead of 4

   STP = StopLoss;

   TKP = TakeProfit;

   if(_Digits==5 || _Digits==3)

   {

      STP = STP*10;

      TKP = TKP*10;

   }

   return(0);

}





void OnDeinit(const int reason)

{

//--- Release our indicator handles

   IndicatorRelease(adxHandle);
   IndicatorRelease(maHandle);
   IndicatorRelease(zigzagHandle);
   IndicatorRelease(atrHandle);
   

}

//+------------------------------------------------------------------+

//| Expert tick function                                             |

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
{

//--- Do we have enough bars to work with







// We will use the static Old_Time variable to serve the bar time.
// At each OnTick execution we will check the current bar time with the saved one.
// If the bar time isn't equal to the saved time, it indicates that we have a new tick.
   static datetime Old_Time;
   datetime New_Time[1];
   bool IsNewBar=false;

// copying the last bar time to the element New_Time[0]
   int copied=CopyTime(_Symbol,_Period,0,1,New_Time);
   if(copied>0) { // ok, the data has been copied successfully
      if(Old_Time!=New_Time[0]) { // if old time isn't equal to new bar time
         IsNewBar=true;   // if it isn't a first call, the new bar has appeared
         if(MQL5InfoInteger(MQL5_DEBUGGING)) Print("We have new bar here ",New_Time[0]," old time was ",Old_Time);
         Old_Time=New_Time[0];            // saving bar time
      }
   } else {
      Alert("Error in copying historical times data, error =",GetLastError());
      ResetLastError();
      return;
   }


//--- EA should only check for new trade if we have a new bar
   if(IsNewBar==false) {
      return;
   }





// the ADX DI+values array

   ArraySetAsSeries(plsDI,true);

// the ADX DI-values array

   ArraySetAsSeries(minDI,true);

// the ADX values arrays

   ArraySetAsSeries(adxVal,true);

   ArraySetAsSeries(atrValue, true);

   ArraySetAsSeries(rsiVal, true );
   

// the MA-8 values arrays

   ArraySetAsSeries(maVal,true);

   ArraySetAsSeries(zigzagVal, true);

   ulong array_ticket[];
   // getTicket(ORDER_TYPE_BUY_STOP  , array_ticket);

   CopyBuffer(atrHandle, 0, 0, 100, atrValue);
   CopyBuffer(zigzagHandle, 0, 0,10, zigzagVal);
   CopyBuffer(rsiHandle, 0, 0,  3, rsiVal);


   double totalPf  = TotalProfit();

   trailingStopLoss(totalPf, trailingStopLossPer);
   bool Buy_opened=false;  // variable to hold the result of Buy opened position
   bool Sell_opened=false; // variable to hold the result of Sell opened position
   if (PositionSelect(_Symbol) ==true) { // we have an opened position
      if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
         Buy_opened = true;  //It is a Buy
      } else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
         Sell_opened = true; // It is a Sell
      }
   }

   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);

   double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);


   if(rsiVal[0] >=rsiMax ) {
      if(Buy_opened){
         CloseAll();
      }
      mytrade.Sell(Lot,_Symbol,bid,bid+ bid * SlDist /100,bid- bid * TpDist /100 );
   }


   if(rsiVal[0] <= rsiMin) {
      if(Sell_opened){
         CloseAll();
      }
      mytrade.Buy(Lot,_Symbol,ask,ask- ask * SlDist /100, ask + ask * TpDist/ 100);

   }


   return;

}
void getTotalProfit() {
   
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void getTicket( ENUM_ORDER_TYPE type, ulong &arr_ticket[])
{
   COrderInfo  OrdInfor;   // order object
   CTrade         Trade;

   int Total = OrdersTotal();   //5

   if(Total > 0) {

      int size = ArraySize(arr_ticket);
      ArrayFree(arr_ticket);
      ArrayResize(arr_ticket, Total);
      ArrayFill(arr_ticket, 0, size, 0);
      ArraySetAsSeries(arr_ticket, true);

      for(int i = 0; i < ArraySize(arr_ticket); i++) {
         Print("arr_ticket[" + i + "]: ", arr_ticket[i]);
      }
      

      int count = 0;
      int index = 0;
      while(count < Total) {
         if(OrdInfor.SelectByIndex(count)) {
            if(OrdInfor.Symbol() == Symbol())
               if(type == OrderGetInteger(ORDER_TYPE)) {
                  arr_ticket[index] = OrdInfor.Ticket();
                  index++;

               }

         }
         count++;
      }

   }
}








//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double TodayHistoryProfit()
{
   MqlDateTime SDateTime;
   TimeToStruct(TimeCurrent(), SDateTime);

   SDateTime.hour = 0;
   SDateTime.min = 0;
   SDateTime.sec = 0;
   datetime from_date = StructToTime(SDateTime);   // From date

   SDateTime.hour = 23;
   SDateTime.min = 59;
   SDateTime.sec = 59;
   datetime to_date = StructToTime(SDateTime);   // To date
   to_date += 60 * 60 * 24;


   int    trades_of_day = 0;
   double wining_trade = 0.0;
   double losing_trade = 0.0;
   double total_profit = 0.0;
   uint   total = HistoryDealsTotal();
   ulong  ticket = 0;
//--- for all deals
   for(uint i = 0; i < total; i++) {
      //--- try to get deals ticket
      if((ticket = HistoryDealGetTicket(i)) > 0) {
         ///////////----
         //--- get deals properties
         trades_of_day++;
         double deal_commission = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
         double deal_swap = HistoryDealGetDouble(ticket, DEAL_SWAP);
         double deal_profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         double profit = deal_commission + deal_swap + deal_profit;
         if(profit > 0.0)
            wining_trade += profit;
         if(profit < 0.0)
            losing_trade += profit;
         total_profit += profit;
      }
   }

   return(total_profit);
}

//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double TotalProfit()
{
   double profit = 0;
   int Total = PositionsTotal();
   for(int i =Total; i >=0; i -- ) {
      if(postionInfo.SelectByIndex(i))

         if(postionInfo.Symbol() == Symbol()) {

            profit += ( postionInfo.Profit()  + postionInfo.Commission() + postionInfo.Swap());

         }

   }
   return NormalizeDouble(profit, 3);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double ClosePositionWhenEnoughProfit(double enoughProfit)
{
   return 1;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double profitShifting()
{
   return 1;
}
double maxProfit = -1;
void trailingStopLoss(double totalProfit, double perForAllow   )
{


   if(totalProfit <= 0) {
      return;
   }

   if(maxProfit < totalProfit ) {
      maxProfit = totalProfit;
   }
   // maxProfit luon lon hon total profit
   // neu max profit lon hon total profit x%


   double perForCurrent  = ( (maxProfit - totalProfit   )/ totalProfit)  * 100;
   
   if(perForCurrent  >  perForAllow) {
      maxProfit = -1;
      Print(StringFormat( " maxProfit : %G , Per current:  %G  , per Allow : %G", maxProfit, perForCurrent, perForAllow));
    //  CloseAll();


   }



}

//+--------------------------