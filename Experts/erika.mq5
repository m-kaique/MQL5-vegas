//+------------------------------------------------------------------+
//|                                                       erika.mq5 |
//|                                                   marcelo kaique |
//|                                  marcelokaique.andrade@gmail.com |
//+------------------------------------------------------------------+
#property copyright "marcelo kaique"
#property link "marcelokaique.andrade@gmail.com"
#property version "1.00"

MqlRates velas[];   // Variável para armazenar velas
MqlTick  tick;      // variável para armazenar ticks

int doji_founds_count = 0;
int doji_venda_count  = 0;
int doji_compra_count = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    //---

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
    //---
    CopyRates(_Symbol, PERIOD_CURRENT, 0, 4, velas);
    // Ordem da mais recente (atual) a mais antiga, 0-1-2-3
    ArraySetAsSeries(velas, true);

    // Toda vez que existir uma nova vela entrar nesse 'if'
    if(TemosNovaVela()) {
        bool isDoji = IsDojiCandle(velas[2].open, velas[2].close, velas[2].high, velas[2].low);
        if(isDoji) {

            // DOJI,  1 = compra, 2 = venda
            int doji_color = GetDojiColor(velas[2].open, velas[2].close);

            if(doji_color == 2) {
                bool isRedCandle = IsStrongBearishCandle(velas[1].open, velas[1].close, velas[1].high, velas[1].low, velas[2].high, velas[2].low);
                if(isRedCandle) {
                    Print("RED CANDLE FORÇA " + velas[1].time + " RED DOJI " + velas[2].time);
                }
            } else if(doji_color == 1) {
                bool isGreenCandle = IsStrongBullishCandle(velas[1].open, velas[1].close, velas[1].high, velas[1].low, velas[2].high, velas[2].low);
                if(isGreenCandle) {
                    Print("GREEN CANDLE FORÇA " + velas[1].time + " GREEN DOJI " + velas[2].time);
                }
            }
        }
    }
}
//+------------------------------------------------------------------+

//--- Para Mudança de Candle
bool TemosNovaVela() {
    //--- memoriza o tempo de abertura da ultima barra (vela) numa variável
    static datetime last_time = 0;
    //--- tempo atual
    datetime lastbar_time = (datetime)SeriesInfoInteger(Symbol(), Period(), SERIES_LASTBAR_DATE);

    //--- se for a primeira chamada da função:
    if(last_time == 0) {
        //--- atribuir valor temporal e sair
        last_time = lastbar_time;
        return (false);
    }

    //--- se o tempo estiver diferente:
    if(last_time != lastbar_time) {
        //--- memorizar esse tempo e retornar true
        last_time = lastbar_time;
        return (true);
    }
    //--- se passarmos desta linha, então a barra não é nova; retornar false
    return (false);
}

bool IsDojiCandle(double open, double close, double high, double low) {
    double bodySize    = MathAbs(open - close);   // Tamanho do corpo da vela
    double candleRange = high - low;              // Intervalo total da vela

    // Verifica se o corpo da vela é pequeno o suficiente
    if(bodySize <= 22 * Point()) {
        double centroCorpo      = (open + close) / 2;   // Centro do corpo da vela
        double centroVela       = (high + low) / 2;     // Centro do intervalo da vela
        double diferencaCentros = MathAbs(centroCorpo - centroVela);

        // Verifica se o corpo da vela está centralizado
        if(diferencaCentros <= 0.1 * candleRange) {
            return true;   // A vela é um doji centralizado
        }
    }

    return false;   // A vela não é um doji centralizado
}

int GetDojiColor(double open, double close) {
    if(close > open) {
        return 1;   // Doji de compra
    } else if(close < open) {
        return 2;   // Doji de venda
    } else {
        return 3;   // Preço de abertura e fechamento iguais
    }
}

bool IsStrongBearishCandle(double open, double close, double high, double low, double dojiHigh, double dojiLow) {
    // Body size and range of the previous candle (Doji)
    double prevRange = dojiHigh - dojiLow;

    // Body size of the current candle
    double bodySize = MathAbs(close - open);

    // Conditions for a strong bearish (red) candle
    bool isStrongBearish =
        (close < open) &&                           // Bearish candle
        (bodySize >= prevRange) &&                  // Body size >= range of the Doji candle
        (MathAbs(high - open) <= 55 * Point()) &&   // High is close to or equal to the open
        (MathAbs(low - close) <= 55 * Point()) &&   // Low is close to or equal to the close
        (bodySize >= 0.75 * (high - low));          // Body is at least 75% of the candle range

    return isStrongBearish;
}

bool IsStrongBullishCandle(double open, double close, double high, double low, double dojiHigh, double dojiLow) {
    // Tamanho do corpo e intervalo da vela anterior (Doji)
    double prevRange = dojiHigh - dojiLow;

    // Tamanho do corpo da vela atual
    double bodySize = MathAbs(close - open);

    // Condições para uma vela forte de alta (bullish)
    bool isStrongBullish =
        (close > open) &&                            // bullish candle
        (bodySize >= prevRange) &&                   // Tamanho do corpo >= intervalo da vela Doji
        (MathAbs(low - open) <= 55 * Point()) &&     // Baixa é próxima ou igual à abertura
        (MathAbs(high - close) <= 55 * Point()) &&   // Alta é próxima ou igual ao fechamento
        (bodySize >= 0.75 * (high - low));           // Corpo é pelo menos 75% do intervalo da vela

    return isStrongBullish;
}
