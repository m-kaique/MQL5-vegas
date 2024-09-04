//+------------------------------------------------------------------+
//|                                                       mayumi.mq5 |
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
    // Ordem da mais recente a mais antiga, 0-1-2-3
    ArraySetAsSeries(velas, true);

    // Toda vez que existir uma nova vela entrar nesse 'if'
    if(TemosNovaVela()) {
        // Print("Vela Mais Recente, " + TimeToString(velas[0].time));

        // Checar se a penultima vela é um DOJI
        bool is_doji = IsDojiCandle(velas[1].open, velas[1].close, velas[1].high, velas[1].low);
        if(is_doji) {
            doji_founds_count++;
            // Print("Penultimo Candle é um Doji, " + IntegerToString(doji_founds_count) + " Encontrados...");

            // Classificar doji venda ou compra
            // Se o preço de fechamento do DOJI estiver abaixo do preço de abertura do candle anterior
            // ele pode ser considerado um sinal de venda.

            if(velas[1].close < velas[2].open) {

                doji_venda_count++;
                // Print("DOJI TIPO SINAL DE VENDA, Horário: " + TimeToString(velas[1].time) + " | doji_venda_count: " + IntegerToString(doji_venda_count));

                // Conferir se o candle na posição 0, atende aos critérios de força
                if(IsCandleDeForcaVermelho(velas[0].open, velas[0].close, velas[0].high, velas[0].low, velas[1].high, velas[1].low)) {
                    Print("! Abra ordem de venda. " + TimeToString(velas[0].time));
                    Alert("! Abra ordem de venda. " + TimeToString(velas[0].time));
                    // Aqui você pode adicionar a lógica para abrir uma ordem de venda
                }

            }
            // Se o preço de fechamento do Doji estiver acima do preço de abertura do candle anterior
            // ele pode ser considerado um sinal de compra

            else if(velas[1].close > velas[2].open) {

                doji_compra_count++;
                // Print("DOJI TIPO, SINAL DE COMPRA, Horário: " + TimeToString(velas[1].time) + " | doji_compra_count: " + IntegerToString(doji_compra_count));

                // Conferir se o candle na posição 0, atende aos criterios de força
                if(IsCandleDeForcaVerde(velas[0].open, velas[0].close, velas[0].high, velas[0].low, velas[1].high, velas[1].low)) {
                    Print("! Abra ordem de compra. " + TimeToString(velas[0].time));
                    Alert("! Abra ordem de compra. " + TimeToString(velas[0].time));
                    // Adicionar lógica para abrir uma ordem de compra
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
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Verifica se é um DOJI (Candle de Indecisão)                      |
//+------------------------------------------------------------------+
bool IsDojiCandle(double open, double close, double high, double low) {
    // Define the pip value for EURUSD (1 pip = 0.0001)
    double pipValue = 0.0001;

    // Set the tolerance to 22 pips
    double tolerance = 22 * pipValue;

    // Rest of the function remains the same
    bool   isSmallBody = MathAbs(open - close) <= tolerance;
    double middle      = (high + low) / 2.0;
    bool   isInMiddle  = (MathAbs(open - middle) <= MathAbs(high - low) / 4.0) &&
                      (MathAbs(close - middle) <= MathAbs(high - low) / 4.0);

    return isSmallBody && isInMiddle;
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Verifica se é um Candle de Força Vermelho                        |
//+------------------------------------------------------------------+
bool IsCandleDeForcaVermelho(double open, double close, double high, double low, double dojiHigh, double dojiLow) {
    double pipValue = 0.0001;   // Define the pip value for EURUSD (1 pip = 0.0001)

    double corpoCandleDeForca = MathAbs(open - close);
    double rangeDoji          = dojiHigh - dojiLow;
    double rangeCandleDeForca = high - low;

    // Condição 1: Corpo do Candle de Força maior ou igual ao range do Doji
    bool cond1 = corpoCandleDeForca >= rangeDoji;

    // Condição 2: A máxima do Candle de Força deve estar a uma distância máxima de 55 pip do open
    bool cond2 = MathAbs(high - open) <= 55 * pipValue;

    // Condição 3: A mínima do Candle de Força deve estar a uma distância máxima de 55 pip do close
    bool cond3 = MathAbs(low - close) <= 55 * pipValue;

    // Condição 4: Corpo do Candle de Força corresponde a 75% do intervalo entre a máxima e a mínima
    bool cond4 = corpoCandleDeForca >= 0.75 * rangeCandleDeForca;

    // Se todas as condições forem atendidas, é um Candle de Força Vermelho
    return (cond1 && cond2 && cond3 && cond4);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Verifica se é um Candle de Força Verde                           |
//+------------------------------------------------------------------+
bool IsCandleDeForcaVerde(double open, double close, double high, double low, double dojiHigh, double dojiLow) {
    double pipValue = 0.0001;   // Define the pip value for EURUSD (1 pip = 0.0001)

    double corpoCandleDeForca = MathAbs(open - close);
    double rangeDoji          = dojiHigh - dojiLow;
    double rangeCandleDeForca = high - low;

    // Condição 1: Corpo do Candle de Força maior ou igual ao range do Doji
    bool cond1 = corpoCandleDeForca >= rangeDoji;

    // Condição 2: A máxima do Candle de Força deve estar a uma distância máxima de 1 pip do close
    bool cond2 = MathAbs(high - close) <= 55 * pipValue;

    // Condição 3: A mínima do Candle de Força deve estar a uma distância máxima de 1 pip do open
    bool cond3 = MathAbs(low - open) <= 55 * pipValue;

    // Condição 4: Corpo do Candle de Força corresponde a 75% do intervalo entre a máxima e a mínima
    bool cond4 = corpoCandleDeForca >= 0.75 * rangeCandleDeForca;

    // Se todas as condições forem atendidas, é um Candle de Força Verde
    return (cond1 && cond2 && cond3 && cond4);
}
//+------------------------------------------------------------------+