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

    // Toda vez que existir uma nova vela entrar nessa condição
    if(TemosNovaVela()) {
        bool isDoji = IsDojiCandle_dev(velas[2].open, velas[2].close, velas[2].high, velas[2].low);
        if(isDoji) {

            // DOJI,  1 = compra, 2 = venda
            int doji_color = GetDojiColor(velas[2].open, velas[2].close);

            // RED SIGNAL
            if(doji_color == 2) {
                Print("RED DOJI");
                bool isRedCandle = IsStrongBearishCandle(velas[1].open, velas[1].close, velas[1].high, velas[1].low, velas[2].high, velas[2].low);
                if(isRedCandle) {
                    // Print("RED CANDLE FORÇA " + TimeToString(velas[1].time) + " RED DOJI " + TimeToString(velas[2].time));
                    // Print(" Open " + velas[2].open + " Close " + velas[2].close + " High " + velas[2].high + " Low " + velas[2].low);
                    // PrintShadowPercentages(velas[2].open, velas[2].close, velas[2].high, velas[2].low, doji_color);
                    doji_venda_count++;

                    /**
                     * VERMELHO: Candle atual tem que ter a abertura no mesmo valor do fechamento ou a abaixo ou um pouco bem pouco acima do fechamento**/

                    // Abertura do Candle Atual é igual ao fechamento do candle de força?
                    bool isOpenLessEqualsLastClose = velas[0].open <= velas[1].close;

                    // Abertura do Candle Atual é pelo menos 1 pip menor que o fechamento anterior?

                    // Obtém o valor de 1 pip dinamicamente para o símbolo atual
                    double pipSize                 = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
                    double openMinusClose          = MathAbs(velas[0].open - velas[1].close);
                    bool   isOpenAtLeastOnePipLess = (openMinusClose) >= pipSize && (openMinusClose) <= pipSize * 2;

                    // Print("is sell ABERTURA: " + velas[0].open + "X Fechamento Anterior: " + velas[1].close + "diff: " + openMinusClose + "Condição: " + isOpenAtLeastOnePipLess);

                    if(isOpenLessEqualsLastClose || isOpenAtLeastOnePipLess) {
                        // Print("Abrir uma ordem de Venda...!" + _Symbol + " - " + SYMBOL_POINT);
                    }
                }
            } else if(doji_color == 1) {
                Print("!!!!!!!!!!!!!!!!!!!!");
                Print("!!!!!!!!!!!!!!!!!!!! GREEN DOJI OK!");
                bool isGreenCandle = IsStrongBullishCandle(velas[1].open, velas[1].close, velas[1].high, velas[1].low, velas[2].high, velas[2].low);
                if(isGreenCandle) {

                    Print("GREEN CANDLE FORÇA " + TimeToString(velas[1].time) + " GREEN DOJI " + TimeToString(velas[2].time));
                    //  Print(" Open " + velas[2].open + " Close " + velas[2].close + " High " + velas[2].high + " Low " + velas[2].low);
                    // PrintShadowPercentages(velas[2].open, velas[2].close, velas[2].high, velas[2].low, doji_color);

                    doji_compra_count++;

                    // velas[0]
                    /**
                     * VERDE: Candle atual tem que ter a abertura no mesmo valor do fechamento ou a cima do candle de força, ou um pouco bem pouco abaixo do fechamento**/

                    // Abertura do Candle Atual é igual ao fechamento do candle de força?

                    bool isOpenMoreEqualsLastClose = velas[1].close <= velas[0].open;

                    // Abertura do Candle Atual é pelo menos 1 pip menor que o fechamento anterior?

                    // Obtém o valor de 1 pip dinamicamente para o símbolo atual
                    double pipSize                 = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
                    double closeMinusOpen          = MathAbs(velas[1].close - velas[0].open);
                    bool   isOpenAtLeastOnePipLess = (closeMinusOpen) >= pipSize && (closeMinusOpen) <= pipSize * 2;

                    // Print("is buy ABERTURA: " + velas[0].open + " X Fechamento Anterior: " + velas[1].close + " diff: " + closeMinusOpen + "Condição: " + isOpenAtLeastOnePipLess);
                    // Print("close<=open: " + isOpenMoreEqualsLastClose);

                    if(isOpenMoreEqualsLastClose || isOpenAtLeastOnePipLess) {
                        Print("Abrir uma ordem de Compra...!");
                    }
                }
            }
        }
    }
}
//+------------------------------------------------------------------+

//--- FN Para Mudança de Candle
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

//--- FN Para Classificar se o candle é um DOJI
bool IsDojiCandle(double open, double close, double high, double low) {
    double bodySize    = MathAbs(open - close);   // Tamanho do corpo da vela
    double candleRange = high - low;              // Intervalo total da vela

    bool tailOverBody = candleRange > bodySize;

    bool is_valid_shadow     = candleRange >= 20 * Point();
    bool is_valid_imperfeito = bodySize <= 10 * Point();

    // ##DEPRECATED##Verifica se o corpo da vela é pequeno o suficiente
    if(is_valid_imperfeito && is_valid_shadow) {
        double centroCorpo      = (open + close) / 2;   // Centro do corpo da vela
        double centroVela       = (high + low) / 2;     // Centro do intervalo da vela
        double diferencaCentros = MathAbs(centroCorpo - centroVela);

        // Verifica se o corpo da vela está centralizado
        if(diferencaCentros <= 0.4 * candleRange) {
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

//--- FN Para Classificar Candle com Força de Baixa
bool IsStrongBearishCandle(double open, double close, double high, double low, double dojiHigh, double dojiLow) {
    // Body size and range of the previous candle (Doji)
    double prevRange = dojiHigh - dojiLow;

    // Body size of the current candle
    double bodySize = MathAbs(close - open);

    // Conditions for a strong bearish (red) candle
    bool isStrongBearish =
        (close < open) &&                    // Bearish candle
        (bodySize >= prevRange) &&           // Body size >= range of the Doji candle
        (bodySize >= 0.70 * (high - low));   // Body is at least 75% of the candle range

    return isStrongBearish;
}

//--- FN Para Classificar Candle com Força de Alta
bool IsStrongBullishCandle(double open, double close, double high, double low, double dojiHigh, double dojiLow) {
    // Tamanho do corpo e intervalo da vela anterior (Doji)
    double prevRange = dojiHigh - dojiLow;

    // Tamanho do corpo da vela atual
    double bodySize = MathAbs(close - open);

    // Condições para uma vela forte de alta (bullish)
    bool isStrongBullish =
        (close > open) &&                    // bullish candle
        (bodySize >= prevRange) &&           // Tamanho do corpo >= intervalo da vela Doji
        (bodySize >= 0.70 * (high - low));   // Corpo é pelo menos 75% do intervalo da vela

    return isStrongBullish;
}

//--- FN Para Classificar se o candle é um DOJI
bool IsDojiCandle_dev(double open, double close, double high, double low) {

    int doji_state = GetDojiColor(open, close);

    double bodySize    = (open - close);   // Tamanho do corpo da vela
    double candleRange = high - low;       // Intervalo total da vela

    if(doji_state == 1) {
        // Dif entre max e o fechamento
        double high_x_close = (high - close);
        // Dif entre abertura e a minima
        double open_x_low = (open - low);

        // Caso o corpo "bodySize" da Vela Seja MAIOR QUE 0

        bool is_valid_shadow = false;

        if(bodySize >= 0) {
            bool ideal_max_shadow = high_x_close >= 0.25 * candleRange;
            bool ideal_low_shadow = open_x_low >= 0.25 * candleRange;

            if(ideal_low_shadow && ideal_max_shadow) {
                is_valid_shadow = true;
            }

        } else if(bodySize == 0) {
            bool ideal_max_shadow = high - close >= 0.25 * high;
            bool ideal_low_shadow = low - open >= 0.25 * low;

            if(ideal_low_shadow && ideal_max_shadow) {
                is_valid_shadow = true;
            }
        }

        if(is_valid_shadow && open_x_low != 0 && high_x_close != 0) {
            return true;
        }
    } else if(doji_state == 2) {
        // Dif entre max e a abertura
        double high_x_open = (high - open);
        // Dif entre fechamento e a minima
        double close_x_low = (close - low);

        // Caso o corpo "bodySize" da Vela Seja MAIOR QUE 0

        bool is_valid_shadow = false;

        if(bodySize > 0) {
            bool ideal_max_shadow = high_x_open >= 0.25 * candleRange;
            bool ideal_low_shadow = close_x_low >= 0.25 * candleRange;

            if(ideal_low_shadow && ideal_low_shadow) {
                is_valid_shadow = true;
            }

        } else if(bodySize == 0) {
            bool ideal_max_shadow = high - close >= 0.25 * high;
            bool ideal_low_shadow = low - open >= 0.25 * low;

            if(ideal_low_shadow && ideal_low_shadow) {
                is_valid_shadow = true;
            }
        }

        if(is_valid_shadow && high_x_open != 0 && close_x_low != 0) {

            return true;
        }
    }

    return false;   // A vela não é um doji centralizado
}

// Função para calcular e imprimir as porcentagens
void PrintShadowPercentages(double open, double close, double high, double low, int doji_type) {

    double bodySize    = (open - close);   // Tamanho do corpo da vela
    double upperShadow = 0;
    double lowerShadow = 0;

    double candleRange = high - low;   // Intervalo total da vela
    // Diferença entre máxima e o fechamento
    double high_x_close = (high - close);
    // Diferença entre abertura e a mínima
    double open_x_low = (open - low);

    // Dif entre max e a abertura
    double high_x_open = (high - open);
    // Dif entre fechamento e a minima
    double close_x_low = (close - low);

    if(doji_type == 1) {
        upperShadow = high_x_close;
        lowerShadow = open_x_low;

    } else if(doji_type == 2) {
        upperShadow = high_x_open;
        lowerShadow = close_x_low;
    }

    if(doji_type == 1 || doji_type == 2) {
        double upperShadowPercent = (upperShadow / candleRange) * 100.0;
        double lowerShadowPercent = (lowerShadow / candleRange) * 100.0;
        double bodySizePercent    = MathAbs(bodySize / candleRange) * 100.0;

        // Imprime as porcentagens
        Print("Upper shadow: ", upperShadowPercent, "%");
        Print("Lower shadow: ", lowerShadowPercent, "%");
        Print("Body Size ", bodySizePercent, "%");
    }
}
