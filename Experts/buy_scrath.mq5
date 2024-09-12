//+------------------------------------------------------------------+
//|                                                   buy_scrath.mq5 |
//|                                                   marcelo kaique |
//|                                  marcelokaique.andrade@gmail.com |
//+------------------------------------------------------------------+
#property copyright "marcelo kaique"
#property link "marcelokaique.andrade@gmail.com"
#property version "1.00"

int      OldNumBars;
MqlRates velas[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    //---
    ChartSetInteger(0, CHART_SHOW_GRID, false);
    ChartSetInteger(0, CHART_MODE, CHART_CANDLES);
    ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrBlack);
    ChartSetInteger(0, CHART_COLOR_FOREGROUND, clrWhite);
    ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, clrLightGreen);
    ChartSetInteger(0, CHART_COLOR_CHART_UP, clrSkyBlue);
    ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, clrRed);
    ChartSetInteger(0, CHART_COLOR_CHART_DOWN, clrIndianRed);
    ChartSetInteger(0, CHART_COLOR_STOP_LEVEL, clrGold);
    ChartSetInteger(0, CHART_SHOW_VOLUMES, false);
    //---
    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    //---
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    CopyRates(_Symbol, PERIOD_CURRENT, 0, 4, velas);
    // Ordem da mais recente (atual) a mais antiga, 0-1-2-3
    ArraySetAsSeries(velas, true);
    //---
    if(!IsNewBar())
        return;

    // Força Alta
    bool str_candle = BuyStrongCandle_Signal(
        velas[1].open, velas[1].close, velas[1].high, velas[1].low, velas[2].high, velas[2].low);

    // Força Baixa
    bool down_candle = SellStrongCandle_Signal(
        velas[1].open, velas[1].close, velas[1].high, velas[1].low, velas[2].high, velas[2].low);

    // Doji Alta
    bool buy_doji = BuyDoji_Signal(
        velas[2].open, velas[2].close, velas[2].high, velas[2].low);

    bool sell_doji = SellDoji_Signal(
        velas[2].open, velas[2].close, velas[2].high, velas[2].low);

    if(down_candle && sell_doji) {
        Alert("Oportunidade de VENDA! ", velas[0].time);
        string ObjVenda = "Compra_" + TimeToString(velas[0].time, TIME_DATE | TIME_MINUTES);

        if(ObjectCreate(0, ObjVenda, OBJ_VLINE, 0, velas[0].time, 0)) {
            ObjectSetInteger(0, ObjVenda, OBJPROP_COLOR, clrIndianRed);
            ObjectSetInteger(0, ObjVenda, OBJPROP_WIDTH, 3);
        }
    }
    if(str_candle && buy_doji) {
        Alert("Oportunidade de COMPRA! ", velas[0].time);

        string ObjCompra = "Compra_" + TimeToString(velas[0].time, TIME_DATE | TIME_MINUTES);

        if(ObjectCreate(0, ObjCompra, OBJ_VLINE, 0, velas[0].time, 0)) {
            ObjectSetInteger(0, ObjCompra, OBJPROP_COLOR, clrGreen);
            ObjectSetInteger(0, ObjCompra, OBJPROP_WIDTH, 3);
        }
    }
}
//+------------------------------------------------------------------+
bool IsNewBar() {
    int bars = Bars(_Symbol, PERIOD_CURRENT);
    if(OldNumBars != bars) {
        OldNumBars = bars;
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Logica de Compra                                                 |
//+------------------------------------------------------------------+
bool BuyStrongCandle_Signal(double open, double close, double high, double low, double doji_high, double doji_low) {

    // Abre embaixo, fecha em cima.

    if(close > open) {
        double body_size            = (close - open);
        double range_size           = (high - low);
        bool   is_greater_than_doji = range_size >= (doji_high - doji_low);
        bool   is_perfect_body      = body_size >= (range_size * 0.60);
        if(is_perfect_body && is_greater_than_doji) {
            return true;
        }
    }
    return false;
}

bool BuyDoji_Signal(double open, double close, double high, double low) {
    if(close > open) {
        double corpo             = MathAbs(close - open);
        double sombra_superior   = high - close;
        double sombra_inferior   = open - low;
        bool   corpo_pequeno     = corpo < (sombra_superior + sombra_inferior) * 0.1;
        double proporcao_sombras = sombra_superior / (sombra_superior + sombra_inferior);
        bool   cond_40_60        = corpo_pequeno && proporcao_sombras >= 0.4 && proporcao_sombras <= 0.6;
        return cond_40_60;
    }
    return false;
}
//+------------------------------------------------------------------+
//| Logica de Venda                                                  |
//+------------------------------------------------------------------+
bool SellStrongCandle_Signal(double open, double close, double high, double low, double doji_high, double doji_low) {

    // Abre Em Cima, fecha em Baixo.

    if(open > close) {
        double body_size            = MathAbs(close - open);
        double range_size           = (high - low);
        bool   is_greater_than_doji = range_size >= (doji_high - doji_low);
        bool   is_perfect_body      = body_size >= (range_size * 0.60);
        if(is_perfect_body && is_greater_than_doji) {
            return true;
        }
    }

    return false;
}

bool SellDoji_Signal(double open, double close, double high, double low) {
    if(open > close) {
        double corpo           = MathAbs(open - close);
        double sombra_superior = high - open;
        double sombra_inferior = close - low;

        bool   corpo_pequeno     = corpo < (sombra_superior + sombra_inferior) * 0.1;
        double proporcao_sombras = sombra_superior / (sombra_superior + sombra_inferior);

        bool cond_40_60 = corpo_pequeno && proporcao_sombras >= 0.4 && proporcao_sombras <= 0.6;
        return cond_40_60;
    }
    return false;
}