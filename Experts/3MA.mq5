//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
// create an array for several prices
double arr_rapida[], arr_media[], arr_lenta[];

// ENUMs
enum TradeType {
    __BUY,   // Representa a operação de compra
    __SELL   // Representa a operação de venda
};
// Variáveis de Velas
MqlRates velas[];
int      OldNumBars;

// define the properties of  MAs - simple MA, 1st 10 / 2nd 24, 3rd 48
int mm_rapida = iMA(_Symbol, _Period, 10, 0, MODE_EMA, PRICE_CLOSE);
int mm_media  = iMA(_Symbol, _Period, 24, 0, MODE_EMA, PRICE_CLOSE);
int mm_lenta  = iMA(_Symbol, _Period, 48, 0, MODE_SMMA,
                    PRICE_CLOSE);   // 48

double RSIBuffer[];
int    RSIHandle;

int OnInit() {

    //--- Config Gráfico
    ChartSetInteger(0, CHART_SHOW_GRID, false);
    ChartSetInteger(0, CHART_MODE, CHART_CANDLES);
    ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrBlack);
    ChartSetInteger(0, CHART_COLOR_FOREGROUND, clrWhite);
    ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, clrLimeGreen);
    ChartSetInteger(0, CHART_COLOR_CHART_UP, clrSkyBlue);
    ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, clrRed);
    ChartSetInteger(0, CHART_COLOR_CHART_DOWN, clrIndianRed);
    ChartSetInteger(0, CHART_COLOR_STOP_LEVEL, clrGold);
    ChartSetInteger(0, CHART_SHOW_VOLUMES, false);

    return (INIT_SUCCEEDED);
}

void OnTick() {
    RSIHandle = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
    ArraySetAsSeries(RSIBuffer, true);
    // velas
    CopyRates(_Symbol, PERIOD_CURRENT, 0, 4, velas);
    ArraySetAsSeries(velas, true);

    // Defined MA1, MA2, MA3 - one line - currentcandle, 3 candles - store result
    CopyBuffer(mm_rapida, 0, 0, 3, arr_rapida);
    CopyBuffer(mm_media, 0, 0, 3, arr_media);
    CopyBuffer(mm_lenta, 0, 0, 3, arr_lenta);

    bool r0_maior_m0     = arr_rapida[0] > arr_media[0];
    bool r1_menor_m1     = arr_rapida[1] < arr_media[1];
    bool r0_maior_l0     = arr_rapida[0] > arr_lenta[0];
    bool r1_menor_l1     = arr_rapida[1] < arr_lenta[1];
    bool m0_maior_l0     = arr_media[0] > arr_lenta[0];
    bool m1_menor_lenta1 = arr_media[1] < arr_lenta[1];

    bool buy =
        (r0_maior_m0) &&
        (r1_menor_m1) &&
        (r0_maior_l0) &&
        (r1_menor_l1) &&
        (m0_maior_l0) &&
        (m1_menor_lenta1);

    bool sell =
        (arr_rapida[0] < arr_media[0]) &&
        (arr_rapida[1] > arr_media[1]) &&
        (arr_rapida[0] < arr_lenta[0]) &&
        (arr_rapida[1] > arr_lenta[1]) &&
        (arr_media[0] < arr_lenta[0]) &&
        (arr_media[1] > arr_lenta[1]);

    // Check if we have a buy entry signal
    if(buy) {
        Comment("BUY");
        draw_v_line(__BUY, velas[0].time);
    }

    // check if we have a sell entry signal
    if(sell) {
        Comment("SELL");
        draw_v_line(__SELL, velas[0].time);
    }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Checa Nova Barra                                                 |
//+------------------------------------------------------------------+
bool IsNewBar() {
    int bars = Bars(_Symbol, PERIOD_CURRENT);
    //---
    if(OldNumBars != bars) {
        OldNumBars = bars;
        //---
        return true;
    }
    return false;
}

void draw_v_line(TradeType type, datetime candle_time) {
    //---
    string trade_str   = (type == __BUY) ? "Compra" : "Venda";
    color  trade_color = (type == __BUY) ? clrLimeGreen : clrRed;
    string ObjVenda    = trade_str + " " + TimeToString(candle_time, TIME_DATE | TIME_MINUTES);
    //
    if(ObjectCreate(0, ObjVenda, OBJ_VLINE, 0, velas[0].time, 0)) {
        Print(candle_time);
        //---
        ObjectSetInteger(0, ObjVenda, OBJPROP_COLOR, trade_color);
        ObjectSetInteger(0, ObjVenda, OBJPROP_WIDTH, 1);

        Print("Oportunidade de, ", trade_str, " em ", TimeToString(candle_time));
    }
}