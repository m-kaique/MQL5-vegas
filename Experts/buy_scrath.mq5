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

int vendas  = 0;
int compras = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
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
    //---
    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    //---
    Print("Finalizando Expert Advisor.");
    Print("Total de Possíveis Compras: ", (string)compras);
    Print("Total de Possíveis Vendas: ", (string)vendas);
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

    // Doji Coringa
    bool coringa_doji = IsDojiCoringa(
        velas[2].open, velas[2].close, velas[2].high, velas[2].low);

    // FORÇA DE BAIXA + SELL DOJI
    if(is_sell_possible(velas[0].open, velas[1].close)) {
        if((down_candle && sell_doji) || (down_candle && coringa_doji)) {
            vendas++;
            Alert("Oportunidade de VENDA! ", velas[0].time);
            //  V Line
            string ObjVenda = "Venda: " + TimeToString(velas[0].time, TIME_DATE | TIME_MINUTES);
            if(ObjectCreate(0, ObjVenda, OBJ_VLINE, 0, velas[0].time, 0)) {
                ObjectSetInteger(0, ObjVenda, OBJPROP_COLOR, clrRed);
                ObjectSetInteger(0, ObjVenda, OBJPROP_WIDTH, 3);
            }
        }
    }

    // FORÇA DE ALTA + BUY DOJI
    if(is_buy_possible(velas[0].open, velas[1].close)) {
        // se compra valida.
        if((str_candle && buy_doji) || (str_candle && coringa_doji)) {
            compras++;
            Alert("Oportunidade de COMPRA! ", velas[0].time);
            //  V Line
            string ObjCompra = "Compra: " + TimeToString(velas[0].time, TIME_DATE | TIME_MINUTES);
            if(ObjectCreate(0, ObjCompra, OBJ_VLINE, 0, velas[0].time, 0)) {
                ObjectSetInteger(0, ObjCompra, OBJPROP_COLOR, clrLimeGreen);
                ObjectSetInteger(0, ObjCompra, OBJPROP_WIDTH, 3);
            }
        }
    }

    // DOJI CORINGA
    /*
    if(coringa_doji) {
        // Alert("Coringa!  ", velas[2].time);
        //   V Line
        string ObjCoringa = "Coringa: " + TimeToString(velas[2].time, TIME_DATE | TIME_MINUTES);
        if(ObjectCreate(0, ObjCoringa, OBJ_VLINE, 0, velas[2].time, 0)) {
            ObjectSetInteger(0, ObjCoringa, OBJPROP_COLOR, clrWhite);
            ObjectSetInteger(0, ObjCoringa, OBJPROP_WIDTH, 1);
        }
    }
    */
}
//+------------------------------------------------------------------+
//| Checa Nova Barra                                                 |
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

//+------------------------------------------------------------------+
//| Doji Coringa                                                     |
//+------------------------------------------------------------------+
bool IsDojiCoringa(double open, double close, double high, double low) {
    if(close == open) {
        double corpo             = MathAbs(close - open);
        double sombra_superior   = high - open;
        double sombra_inferior   = close - low;
        double proporcao_sombras = sombra_superior / (sombra_superior + sombra_inferior);

        return proporcao_sombras >= 0.4 && proporcao_sombras <= 0.6;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Liberação Para Compra                                            |
//+------------------------------------------------------------------+
bool is_buy_possible(double open_atual, double close_anterior) {
    bool tolerance = MathAbs(open_atual - close_anterior) <= (1 * _Point);
    if((open_atual >= close_anterior) || tolerance) {
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Liberação Para Venda                                             |
//+------------------------------------------------------------------+
bool is_sell_possible(double open_atual, double close_anterior) {
    bool tolerance = MathAbs(close_anterior - open_atual) <= (1 * _Point);
    if((open_atual <= close_anterior) || tolerance) {
        return true;
    }
    return false;
}