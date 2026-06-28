//+------------------------------------------------------------------+
//|                                             K1_StopLossPoints.mq5 |
//|                  MT5 Expert Advisor source for EX5 compilation    |
//+------------------------------------------------------------------+
#property copyright "Custom build"
#property version   "1.00"
#property strict
#property description "Grid/hedge helper EA matching the provided K1 input panel. Compile this MQ5 in MetaEditor to create the EX5 file."

#include <Trade/Trade.mqh>

input string InpLotsSequence      = "0.3,0.6,0.9,1.2,1.5,1.8,2.1,2.5"; // 等分下单手数
input int    InpGridDistance      = 3500;                              // 逆势加仓间距，小数点3位的是ex平台
input string InpGroup1Title       = "============第一组============";  // aps1
input double InpGroup1Lots        = 1.0;                               // 第一组手数
input double InpGroup1Distance    = 5000.0;                            // 第一组间隔
input string InpGroup2Title       = "============第二组============";  // aps2
input double InpGroup2Lots        = 5.0;                               // 第二组手数
input double InpGroup2Distance    = 10000.0;                           // 第二组间隔
input string InpGroup3Title       = "============第三组============";  // aps3
input double InpGroup3Lots        = 0.0;                               // 第三组手数
input double InpGroup3Distance    = 0.0;                               // 第三组间隔
input double InpGroup8Lots        = 0.0;                               // 第八组手数
input double InpGroup8Distance    = 0.0;                               // 第八组间隔
input long   InpMagicNumber       = 123456;                            // EA识别码
input int    InpSlippage          = 0;                                 // 允许滑点
input int    InpSingleTakeProfitPoints = 100;                          // 单边点数止盈
input int    InpSingleStopLossPoints   = 0;                            // 单边点数止损
input double InpSingleTakeProfitMoney  = 0.0;                          // 单边止盈金额(固定 不随手数变化)
input double InpSingleStopLossMoney    = 0.0;                          // 单边止损金额(固定 不随手数变化)
input int    InpHedgeStartOrders       = 7;                            // 对冲起始单量
input double InpHedgeProfitMoney       = 100.0;                        // 对冲盈利金额
input int    InpHedgeProfitPoints      = 0;                            // 对冲盈利点数
input bool   InpShowChartPanel         = true;                         // 显示图表按钮和订单线

CTrade trade;
double lot_sequence[];

int OnInit()
{
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpSlippage);
   ParseLotsSequence();
   if(InpShowChartPanel)
      CreatePanel();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   ObjectDelete(0, "K1_btn_lock");
   ObjectDelete(0, "K1_btn_buy");
   ObjectDelete(0, "K1_btn_sell");
   ObjectDelete(0, "K1_status");
}

void OnTick()
{
   ManageSingleSideProfitLoss(POSITION_TYPE_BUY);
   ManageSingleSideProfitLoss(POSITION_TYPE_SELL);
   ManageGrid(POSITION_TYPE_BUY);
   ManageGrid(POSITION_TYPE_SELL);
   ManageHedgeProfit();
   if(InpShowChartPanel)
      DrawPositionLines();
}

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
   if(id != CHARTEVENT_OBJECT_CLICK)
      return;

   if(sparam == "K1_btn_buy")
      OpenMarketOrder(ORDER_TYPE_BUY, NextLot(POSITION_TYPE_BUY));
   else if(sparam == "K1_btn_sell")
      OpenMarketOrder(ORDER_TYPE_SELL, NextLot(POSITION_TYPE_SELL));
}

void ParseLotsSequence()
{
   string parts[];
   const int count = StringSplit(InpLotsSequence, ',', parts);
   ArrayResize(lot_sequence, MathMax(count, 1));
   if(count <= 0)
   {
      lot_sequence[0] = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      return;
   }
   for(int i = 0; i < count; i++)
      lot_sequence[i] = NormalizeVolume(StringToDouble(parts[i]));
}

double NextLot(ENUM_POSITION_TYPE side)
{
   const int count = CountPositions(side);
   if(count < ArraySize(lot_sequence))
      return lot_sequence[count];
   return lot_sequence[ArraySize(lot_sequence) - 1];
}

void ManageGrid(ENUM_POSITION_TYPE side)
{
   const int count = CountPositions(side);
   if(count <= 0)
      return;

   const double last_price = LastEntryPrice(side);
   const double current = (side == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   const double distance = MathAbs(current - last_price) / _Point;

   if(distance < InpGridDistance)
      return;

   const bool adverse_for_buy = (side == POSITION_TYPE_BUY && current < last_price);
   const bool adverse_for_sell = (side == POSITION_TYPE_SELL && current > last_price);
   if(adverse_for_buy)
      OpenMarketOrder(ORDER_TYPE_BUY, NextLot(POSITION_TYPE_BUY));
   if(adverse_for_sell)
      OpenMarketOrder(ORDER_TYPE_SELL, NextLot(POSITION_TYPE_SELL));
}

void ManageSingleSideProfitLoss(ENUM_POSITION_TYPE side)
{
   double profit = 0.0;
   double volume = 0.0;
   double weighted_price = 0.0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket) || PositionGetInteger(POSITION_MAGIC) != InpMagicNumber || PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) != side)
         continue;

      const double lot = PositionGetDouble(POSITION_VOLUME);
      profit += PositionGetDouble(POSITION_PROFIT);
      volume += lot;
      weighted_price += PositionGetDouble(POSITION_PRICE_OPEN) * lot;
   }

   if(volume <= 0.0)
      return;

   const double average = weighted_price / volume;
   const double current = (side == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   const double points = (side == POSITION_TYPE_BUY) ? (current - average) / _Point : (average - current) / _Point;

   if((InpSingleTakeProfitPoints > 0 && points >= InpSingleTakeProfitPoints) ||
      (InpSingleStopLossPoints > 0 && points <= -InpSingleStopLossPoints) ||
      (InpSingleTakeProfitMoney > 0.0 && profit >= InpSingleTakeProfitMoney) ||
      (InpSingleStopLossMoney > 0.0 && profit <= -InpSingleStopLossMoney))
      CloseSide(side);
}

void ManageHedgeProfit()
{
   const int total = CountPositions(POSITION_TYPE_BUY) + CountPositions(POSITION_TYPE_SELL);
   if(total < InpHedgeStartOrders)
      return;

   const double all_profit = TotalProfit();
   if(InpHedgeProfitMoney > 0.0 && all_profit >= InpHedgeProfitMoney)
      CloseAll();
}

void OpenMarketOrder(ENUM_ORDER_TYPE type, double lots)
{
   lots = NormalizeVolume(lots);
   if(lots <= 0.0)
      return;

   if(type == ORDER_TYPE_BUY)
      trade.Buy(lots, _Symbol);
   else if(type == ORDER_TYPE_SELL)
      trade.Sell(lots, _Symbol);
}

int CountPositions(ENUM_POSITION_TYPE side)
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) && PositionGetInteger(POSITION_MAGIC) == InpMagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol && (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) == side)
         count++;
   }
   return count;
}

double LastEntryPrice(ENUM_POSITION_TYPE side)
{
   datetime latest = 0;
   double price = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket) || PositionGetInteger(POSITION_MAGIC) != InpMagicNumber || PositionGetString(POSITION_SYMBOL) != _Symbol || (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) != side)
         continue;
      const datetime opened = (datetime)PositionGetInteger(POSITION_TIME);
      if(opened >= latest)
      {
         latest = opened;
         price = PositionGetDouble(POSITION_PRICE_OPEN);
      }
   }
   return price;
}

double TotalProfit()
{
   double profit = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) && PositionGetInteger(POSITION_MAGIC) == InpMagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol)
         profit += PositionGetDouble(POSITION_PROFIT);
   }
   return profit;
}

void CloseSide(ENUM_POSITION_TYPE side)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) && PositionGetInteger(POSITION_MAGIC) == InpMagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol && (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) == side)
         trade.PositionClose(ticket);
   }
}

void CloseAll()
{
   CloseSide(POSITION_TYPE_BUY);
   CloseSide(POSITION_TYPE_SELL);
}

double NormalizeVolume(double lots)
{
   const double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   const double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   const double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   lots = MathMax(min_lot, MathMin(max_lot, lots));
   return MathRound(lots / step) * step;
}

void CreatePanel()
{
   CreateButton("K1_btn_lock", 12, 420, 180, 34, "suocang", clrWhite, clrDimGray);
   CreateButton("K1_btn_buy", 12, 462, 180, 34, "buy", clrAqua, clrDarkSlateGray);
   CreateButton("K1_btn_sell", 12, 504, 180, 34, "sell", clrAqua, clrDarkSlateGray);
   ObjectCreate(0, "K1_status", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "K1_status", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, "K1_status", OBJPROP_XDISTANCE, 12);
   ObjectSetInteger(0, "K1_status", OBJPROP_YDISTANCE, 380);
   ObjectSetInteger(0, "K1_status", OBJPROP_COLOR, clrWhite);
   ObjectSetString(0, "K1_status", OBJPROP_TEXT, "K1 EA ready");
}

void CreateButton(const string name, int x, int y, int w, int h, const string text, color bg, color fg)
{
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, fg);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 14);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
}

void DrawPositionLines()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket) || PositionGetInteger(POSITION_MAGIC) != InpMagicNumber || PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      const string name = "K1_line_" + IntegerToString((int)ticket);
      const double price = PositionGetDouble(POSITION_PRICE_OPEN);
      const string label = ((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? "BUY " : "SELL ") +
                           DoubleToString(PositionGetDouble(POSITION_VOLUME), 1) + " at " + DoubleToString(price, _Digits);

      if(ObjectFind(0, name) < 0)
         ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
      ObjectSetDouble(0, name, OBJPROP_PRICE, price);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrMediumSeaGreen);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetString(0, name, OBJPROP_TEXT, label);
   }
}
