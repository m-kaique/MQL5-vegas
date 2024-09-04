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
                Print("DOJI TIPO SINAL DE VENDA, Horário: " + TimeToString(velas[1].time) + " | doji_venda_count: " + IntegerToString(doji_venda_count));

                // Conferir se o candle na posição 0, atende aos criterios de força

            }
            // Se o preço de fechamento do Doji estiver acima do preço de abertura do candle anterior
            // ele pode ser considerado um sinal de compra

            else if(velas[1].close > velas[2].open) {

                doji_compra_count++;
                Print("DOJI TIPO, SINAL DE COMPRA, Horário: " + TimeToString(velas[1].time) + " | doji_compra_count: " + IntegerToString(doji_compra_count));

                // Conferir se o candle na posição 0, atende aos criterios de força
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
//|Verifica se é um DOJI                                             |
//+------------------------------------------------------------------+
bool IsDojiCandle(double open, double close, double high, double low) {

    // TODO: são iguais ou diferem por, no máximo, "xQualquerValor" ,22 pontos.
    //  Calcula o corpo da vela
    double body = MathAbs(open - close);

    // Calcula as sombras superior e inferior
    double upperShadow = high - MathMax(open, close);
    double lowerShadow = MathMin(open, close) - low;

    // Define um limiar para considerar a vela como indecisa
    double bodyThreshold   = 0.1 * (high - low);   // Corpo da vela deve ser pequeno
    double shadowThreshold = 0.4 * (high - low);   // Sombras devem ser longas

    // Verifica se o corpo da vela é pequeno e se as sombras são longas
    if(body <= bodyThreshold && (upperShadow >= shadowThreshold && lowerShadow >= shadowThreshold)) {
        return true;
    }

    return false;
}
//+------------------------------------------------------------------+
