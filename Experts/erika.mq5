//+------------------------------------------------------------------+
//|                                                       erika.mq5  |
//|                                                   Marcelo Kaique |
//|                                  marcelokaique.andrade@gmail.com |
//+------------------------------------------------------------------+
#property copyright "marcelo kaique"
#property link "marcelokaique.andrade@gmail.com"
#property version "1.00"

//+------------------------------------------------------------------+
//| Sessão de Includes                                               |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Sessão de Declaração de Variáveis                                |
//+------------------------------------------------------------------+
MqlRates velas[];                    // Variável para armazenar velas
MqlTick  tick;                       // variável para armazenar ticks
int      doji_founds_count   = 0;    // Variável Para Guardar A quantidade Total de DOJIS.
int      doji_venda_count    = 0;    // Variável Para Guardar A quantidade de DOJIS de Venda Encontrados.
int      doji_venda_sucesso  = 0;    // Variável Para Guardar A quantidade de DOJIS de Compra com Candle de Força Vermelha Encontrados.
int      doji_compra_sucesso = 0;    // Variável Para Guardar A quantidade de DOJIS de Compra com Candle de Força Verde Encontrados.
int      doji_compra_count   = 0;    // Variável Para Guardar A quantidade de DOJIS de Compra Encontrados
int      doji_state_color    = 99;   // Variável Para Sinalizar a Tendência (Verde ou Vermelha) do DOJI.

sinput string            s1;                                   //-----------Médias Móveis-------------
input int                mm_rapida_periodo = 3;                // Periodo Média Rápida
input int                mm_lenta_periodo  = 9;                // Periodo Média Lenta
input ENUM_TIMEFRAMES    mm_tempo_grafico  = PERIOD_CURRENT;   // Tempo Gráfico
input ENUM_MA_METHOD     mm_metodo         = MODE_EMA;         // Método
input ENUM_APPLIED_PRICE mm_preco          = PRICE_CLOSE;      // Preço Aplicado
//+------------------------------------------------------------------+
//|  Variáveis para os indicadores                                   |
//+------------------------------------------------------------------+
//--- Médias Móveis
// RÁPIDA - menor período
int    mm_rapida_Handle;     // Handle controlador da média móvel rápida
double mm_rapida_Buffer[];   // Buffer para armazenamento dos dados das médias

// LENTA - maior período
int    mm_lenta_Handle;     // Handle controlador da média móvel lenta
double mm_lenta_Buffer[];   // Buffer para armazenamento dos dados das médias

// RÁPIDA Força - menor período
int    mm_rapida_Handle_forca;     // Handle controlador da média móvel rápida
double mm_rapida_força_Buffer[];   // Buffer para armazenamento dos dados das médias

// LENTA Força- maior período
int    mm_lenta_Handle_forca;     // Handle controlador da média móvel lenta
double mm_lenta_força_Buffer[];   // Buffer para armazenamento dos dados das médias
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {

    mm_rapida_Handle = iMA(_Symbol, mm_tempo_grafico, mm_rapida_periodo, 0, mm_metodo, mm_preco);
    mm_lenta_Handle  = iMA(_Symbol, mm_tempo_grafico, mm_lenta_periodo, 0, mm_metodo, mm_preco);

    mm_rapida_Handle_forca = iMA(_Symbol, mm_tempo_grafico, mm_rapida_periodo, 1, mm_metodo, mm_preco);
    mm_lenta_Handle_forca  = iMA(_Symbol, mm_tempo_grafico, mm_lenta_periodo, 1, mm_metodo, mm_preco);

    if(mm_rapida_Handle < 0 || mm_lenta_Handle < 0) {
        Alert("Erro ao tentar criar Handles para o indicador - erro: ", GetLastError(), "!");
        return (-1);
    }

    // Para adicionar no gráfico o indicador:
    ChartIndicatorAdd(0, 0, mm_rapida_Handle);
    ChartIndicatorAdd(0, 0, mm_lenta_Handle);
    ChartIndicatorAdd(0, 0, mm_rapida_Handle_forca);
    ChartIndicatorAdd(0, 0, mm_lenta_Handle_forca);
    //---

    //---
    Alert("Procurando Por Oportunidades...");
    //---
    return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    //---
    IndicatorRelease(mm_rapida_Handle);
    IndicatorRelease(mm_lenta_Handle);
    IndicatorRelease(mm_rapida_Handle_forca);
    IndicatorRelease(mm_lenta_Handle_forca);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    // Copiar um vetor de dados tamanho três para o vetor mm_Buffer
    CopyBuffer(mm_rapida_Handle, 0, 0, 4, mm_rapida_Buffer);
    CopyBuffer(mm_lenta_Handle, 0, 0, 4, mm_lenta_Buffer);
    ArraySetAsSeries(mm_rapida_Buffer, true);
    ArraySetAsSeries(mm_lenta_Buffer, true);

    // Copiar um vetor de dados tamanho três para o vetor mm_Buffer_força
    CopyBuffer(mm_rapida_Handle_forca, 0, 0, 4, mm_rapida_força_Buffer);
    CopyBuffer(mm_lenta_Handle_forca, 0, 0, 4, mm_lenta_força_Buffer);
    ArraySetAsSeries(mm_rapida_força_Buffer, true);
    ArraySetAsSeries(mm_lenta_força_Buffer, true);

    // Alimentar com dados variável de tick
    SymbolInfoTick(_Symbol, tick);
    //
    CopyRates(_Symbol, PERIOD_CURRENT, 0, 4, velas);
    // Ordem da mais recente (atual) a mais antiga, 0-1-2-3
    ArraySetAsSeries(velas, true);

    // Toda vez que existir uma nova vela entrar nessa condição
    //---
    if(TemosNovaVela()) {
        bool is_valid_MM_compra = mm_rapida_Buffer[0] > mm_rapida_Buffer[1] &&
                                  mm_lenta_Buffer[0] > mm_lenta_Buffer[1];

        bool is_valid_MM_venda = mm_rapida_Buffer[0] < mm_rapida_Buffer[1] &&
                                 mm_lenta_Buffer[0] < mm_lenta_Buffer[1];

        bool isDoji = IsDojiCandle_dev(velas[2].open, velas[2].close, velas[2].high, velas[2].low);

        if(isDoji) {

            doji_founds_count++;
            // DOJI,  1 = compra, 2 = venda
            // int doji_color = GetDojiColor(velas[2].open, velas[2].close);
            // Print("doji_color in TEMOS VELA IS: " + GetDojiColor(velas[2].open, velas[2].close));

            // RED SIGNAL
            if(GetDojiColor(velas[2].open, velas[2].close) == 2) {

                doji_venda_count++;

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

                    // Print("is sell ABERTURA: " + DoubleToString(velas[0].open) + "X Fechamento Anterior: " + DoubleToString(velas[1].close) + "diff: " + DoubleToString(openMinusClose) + "Condição: " + (string)isOpenAtLeastOnePipLess);

                    if(isOpenLessEqualsLastClose || isOpenAtLeastOnePipLess) {
                        doji_venda_sucesso++;
                        if(is_valid_MM_venda) {
                            Print("Abrir uma ordem de Venda...!");
                            Alert("Abrir uma ordem de Venda...!");
                        }

                        // Alert("Abrir uma ordem de Venda...!" + _Symbol + " - " + (string)SYMBOL_POINT);
                        // Exibir o valor do M9 no diário (opcional)
                    }
                }
            } else if(GetDojiColor(velas[2].open, velas[2].close) == 1) {
                doji_compra_count++;
                // Print("!!!!!!!!!!!!!!!!!!!!");
                // Print("!!!!!!!!!!!!!!!!!!!! GREEN DOJI OK!");
                bool isGreenCandle = IsStrongBullishCandle(velas[1].open, velas[1].close, velas[1].high, velas[1].low, velas[2].high, velas[2].low);
                if(isGreenCandle) {

                    //  Print("GREEN CANDLE FORÇA " + TimeToString(velas[1].time) + " GREEN DOJI " + TimeToString(velas[2].time));
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

                    // Print("is buy ABERTURA: " + DoubleToString(velas[0].open) + " X Fechamento Anterior: " + DoubleToString(velas[1].close) + " diff: " + DoubleToString(closeMinusOpen) + "Condição: " + (string)isOpenAtLeastOnePipLess);
                    //  Print("close<=open: " + isOpenMoreEqualsLastClose);

                    if(isOpenMoreEqualsLastClose || isOpenAtLeastOnePipLess) {
                        doji_compra_sucesso++;

                        if(is_valid_MM_compra) {
                            Print("Abrir uma ordem de Compra...!");
                            Alert("Abrir uma ordem de Compra...!");
                        }
                    }
                }
            }
        }
    }
    // Print("Total Doji: " + IntegerToString(doji_founds_count) + " | Doji Venda: " + IntegerToString(doji_venda_count) + "| Doji Compra: " + IntegerToString(doji_compra_count) + "| Doji Venda Sucesso: " + IntegerToString(doji_venda_sucesso) + "| Doji Compra Sucesso : " + IntegerToString(doji_compra_sucesso));
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Fn Para Detectar Quando Uma Nova Vela Aparece                    |
//+------------------------------------------------------------------+
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
//| Fn Para Detectar Se o DOJI é Verde ou Vermelho                   |
//+------------------------------------------------------------------+
int GetDojiColor(double open, double close) {

    if(close >= open) {
        return 1;   // Doji de compra
    } else if(close <= open) {
        return 2;   // Doji de venda
    } else {
        return 3;   // Preço de abertura e fechamento iguais
    }
}

//+------------------------------------------------------------------+
//| Fn Para Classificar Candle de Força de Baixa                     |
//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
//| Fn Para Classificar Candle de Força de Alta                      |
//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
//| Fn Para Classificar Candle Tipo DOJI                             |
//+------------------------------------------------------------------+

bool IsDojiCandle_dev(double open, double close, double high, double low) {

    int doji_state = GetDojiColor(open, close);

    double bodySize    = (open - close);   // Tamanho do corpo da vela
    double candleRange = high - low;       // Intervalo total da vela

    if(doji_state == 1) {

        // Print("GREEN DOJI, IS DOJI FN!");
        //  Dif entre max e o fechamento
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
            doji_state_color = doji_state;
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

        if(is_valid_shadow) {
            return true;
        }
    }

    return false;   // A vela não é um doji centralizado
}

//+------------------------------------------------------------------+
//| Fn Para Calcular e Informar Porcentagens de Sombra do DOJI       |
//+------------------------------------------------------------------+
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
        // Print("Upper shadow: ", upperShadowPercent, "%");
        // Print("Lower shadow: ", lowerShadowPercent, "%");
        // Print("Body Size ", bodySizePercent, "%");
    }
}
