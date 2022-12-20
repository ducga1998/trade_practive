

#property copyright "Copyright 2010, MetaQuotes Software Corp."

#property link      "http://www.mql5.com"

#property version   "1.00"
#include <Trade/Trade.mqh>
#include <Expert/Trailing/TrailingMA.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Tools/DateTime.mqh>


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
CDateTime myDate;

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




int OnInit()

{

//--- Get handle for ADX indicator
   mytrade.SetAsyncMode(true);
   mytrade.LogLevel(0);
   rsiHandle = iRSI(_Symbol,PERIOD_CURRENT, 14,PRICE_CLOSE);
   adxHandle=iADX(NULL,0,ADX_Period);
   atrHandle = iATR(NULL,PERIOD_CURRENT, 14 );
   
   zigzagHandle = iCustom( NULL, 0, "Examples/ZigZag",12,5,3 );


   
   maHandle=iMA(_Symbol,_Period,MA_Period,0,MODE_EMA,PRICE_CLOSE);
   
   
//--- What if handle returns Invalid Handle

   if(adxHandle<0 || maHandle<0 )

   {

      Alert("Error Creating Handles for indicators - error: ",GetLastError(),"!!");

      return(-1);

   }

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
   static datetime oldTime;

   datetime New_Time[1];
   bool IsNewBar=false;

// copying the last bar time to the element New_Time[0]
   int copied=CopyTime(_Symbol,_Period,0,1,New_Time);
   if(copied>0) { // ok, the data has been copied successfully
      if(oldTime!=New_Time[0]) { // if old time isn't equal to new bar time
         IsNewBar=true;   // if it isn't a first call, the new bar has appeared
         if(MQL5InfoInteger(MQL5_DEBUGGING)) Print("We have new bar here ",New_Time[0]," old time was ",oldTime);
         oldTime=New_Time[0];            // saving bar time
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

   ArraySetAsSeries(maVal,true);

   ArraySetAsSeries(zigzagVal, true);

   ulong array_ticket[];
   // getTicket(ORDER_TYPE_BUY_STOP  , array_ticket);

   CopyBuffer(atrHandle, 0, 0, 100, atrValue);
   CopyBuffer(zigzagHandle, 0, 0,10, zigzagVal);
   CopyBuffer(rsiHandle, 0, 0,  3, rsiVal);




   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);

   double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);


   TimeGMT(myDate);

   int m_hour_date = myDate.hour;
   myDate.hour;
   Print("index hour" , m_hour_date);
   double priceOpen =  iOpen(_Symbol ,  PERIOD_CURRENT , m_hour_date);

   Print("Print open " , priceOpen);
   // if(rsiVal[0] >=rsiMax ) {
   //    if(Buy_opened){
   //       CloseAll();
   //    }
   //    mytrade.Sell(Lot,_Symbol,bid,bid+ bid * SlDist /100,bid- bid * TpDist /100 );
   // }


   // if(rsiVal[0] <= rsiMin) {
   //    if(Sell_opened){
   //       CloseAll();
   //    }
   //    mytrade.Buy(Lot,_Symbol,ask,ask- ask * SlDist /100, ask + ask * TpDist/ 100);
   // }


   return;

}




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

