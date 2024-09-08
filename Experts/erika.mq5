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

sinput string s2;                      //-----------Candle de Força -------------
input double  str_candle_size = 0.6;   // Tamanho Min do Corpo (%)

sinput string s3;                                // -----------Candle de Indecisão -------------
input double  indecision_candle_shadow = 0.20;   // Tamanho Min de Cada Sombra (%)

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
    PrintFinalLog();
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

            // RED SIGNAL
            if(GetDojiColor(velas[2].open, velas[2].close) == 2) {

                // Print("Indesição" + velas[2].time);
                doji_venda_count++;

                bool isRedCandle = IsStrongBearishCandle(velas[1].open, velas[1].close, velas[1].high, velas[1].low, velas[2].high, velas[2].low);
                if(isRedCandle) {
                    // Print("Força Venda" + velas[1].time);

                    doji_venda_count++;

                    /**
                     * VERMELHO: Candle atual tem que ter a abertura no mesmo valor do fechamento
                     * ou abaixo ou um pouco bem pouco acima do fechamento
                     **/

                    // Abertura do Candle Atual é igual ao fechamento do candle de força?
                    bool isOpenLessEqualsLastClose = velas[0].open <= velas[1].close;

                    // Abertura do Candle Atual é pelo menos 1 pip menor que o fechamento anterior?

                    // Obtém o valor de 1 pip dinamicamente para o símbolo atual
                    double pipSize                 = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
                    double openMinusClose          = MathAbs(velas[0].open - velas[1].close);
                    bool   isOpenAtLeastOnePipLess = (openMinusClose) >= pipSize && (openMinusClose) <= pipSize * 2;

                    if(isOpenLessEqualsLastClose || isOpenAtLeastOnePipLess) {
                        doji_venda_sucesso++;
                        if(is_valid_MM_venda) {
                            // Print("+-----------------------------------------------------------------------+");
                            // Print("MM: Atual: " + DoubleToString(mm_rapida_Buffer[0]) + " MM Força: " + DoubleToString(mm_rapida_Buffer[1]));
                            // Alert("Abrir uma ordem de Venda...!");
                        }
                    }
                }
            } else if(GetDojiColor(velas[2].open, velas[2].close) == 1) {
                doji_compra_count++;

                bool isGreenCandle = IsStrongBullishCandle(velas[1].open, velas[1].close, velas[1].high, velas[1].low, velas[2].high, velas[2].low);
                if(isGreenCandle) {
                    Print("Força Compra" + velas[1].time);
                    doji_compra_count++;

                    /**
                     * VERDE: Candle atual tem que ter a abertura no mesmo valor do fechamento,
                     * acima do candle de força, ou um pouco bem pouco abaixo do fechamento
                     **/

                    // Checa se Abertura do Candle Atual é igual ao fechamento do candle de força
                    bool isOpenMoreEqualsLastClose = velas[1].close <= velas[0].open;

                    // Checa se Abertura do Candle Atual é pelo menos 1 pip menor que o fechamento anterior
                    double pipSize                 = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
                    double closeMinusOpen          = MathAbs(velas[1].close - velas[0].open);
                    bool   isOpenAtLeastOnePipLess = (closeMinusOpen) >= pipSize && (closeMinusOpen) <= pipSize * 2;

                    if(isOpenMoreEqualsLastClose || isOpenAtLeastOnePipLess) {
                        doji_compra_sucesso++;

                        if(is_valid_MM_compra) {

                            // Print("+-----------------------------------------------------------------------+");
                            // Print("MM: Atual: " + DoubleToString(mm_rapida_Buffer[0]) + " MM Força: " + DoubleToString(mm_rapida_Buffer[1]));
                            // Alert("Abrir uma ordem de Compra...!");
                        }
                    }
                }
            }
        }
    }
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
    double range    = high - low;

    // Conditions for a strong bearish (red) candle
    bool isStrongBearish =
        (close < open) &&                               // Bearish candle
        (range >= prevRange) &&                         // range size >= range of the Doji candle
        (bodySize >= str_candle_size * (high - low));   // Body is at least 75% of the candle range

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
    double range    = high - low;

    // Condições para uma vela forte de alta (bullish)
    bool isStrongBullish =
        (close > open) &&                               // bullish candle
        (range >= prevRange) &&                         // range >= intervalo da vela Doji
        (bodySize >= str_candle_size * (high - low));   // Corpo é pelo menos 75% do intervalo da vela

    return isStrongBullish;
}

//+------------------------------------------------------------------+
//| Fn Para Classificar Candle Tipo DOJI                             |
//+------------------------------------------------------------------+

bool IsDojiCandle_dev(double open, double close, double high, double low) {

    int    doji_state = GetDojiColor(open, close);
    double percentualCorpo, percentualPavioSuperior, percentualPavioInferior;

    // Calcula os percentuais
    CalcularPercentuaisIndecisao(open, high, low, close, percentualCorpo, percentualPavioSuperior, percentualPavioInferior, doji_state);

    // Critérios para uma boa venda:
    // 1. O corpo deve ser <= 30% do tamanho total do candle.
    // 2. O corpo não pode estar a menos de 20% da máxima ou da mínima.
    // 3. O corpo deve estar centralizado entre o pavio superior e inferior, respeitando as distâncias de 20%.
    if(percentualCorpo <= 30 &&
       percentualPavioSuperior >= 20 &&
       percentualPavioInferior >= 20) {
        // Exibe no console os valores calculados e uma mensagem informando que o candle é bom para venda
        // Print("Candle atende aos critérios para venda:");
        // Print("Percentual do Corpo: ", DoubleToString(percentualCorpo, 2), "%");
        // Print("Percentual do Pavio Superior: ", DoubleToString(percentualPavioSuperior, 2), "%");
        // Print("Percentual do Pavio Inferior: ", DoubleToString(percentualPavioInferior, 2), "%");
        return true;
    }

    // Caso o candle não atenda aos critérios, exibe uma mensagem no console
    // Print("Candle NÃO atende aos critérios para venda.");
    return false;
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

//+------------------------------------------------------------------+
//| Fn Para Exibir Logs ao Final da Simulação                         |
//+------------------------------------------------------------------+
void PrintFinalLog() {
    PrintDojiReport();
}

//+------------------------------------------------------------------+
//| Fn Para Calcular Quantidade de Indecições Filtradas              |
//+------------------------------------------------------------------+
void PrintDojiReport() {
    double doji_venda_porcentagem  = 0.0;
    double doji_compra_porcentagem = 0.0;

    if(doji_founds_count != 0) {
        doji_venda_porcentagem  = ((double)doji_venda_sucesso / doji_founds_count) * 100;
        doji_compra_porcentagem = ((double)doji_compra_sucesso / doji_founds_count) * 100;
    }

    Print("#########################################################################");
    Print("##   RELAÇÃO DE INDECIÇÕES ENCONTRADOS POR ERIKA ");
    Print("##                                       ");
    Print("##   TIPO VENDA: " + IntegerToString(doji_venda_count));
    Print("##   Chegaram até a ordem: " + IntegerToString(doji_venda_sucesso) + "|  %: " + DoubleToString(doji_venda_porcentagem, 2) + " %");
    Print("##                                       ");
    Print("##   TIPO COMPRA: " + IntegerToString(doji_compra_count));
    Print("##   Chegaram até a ordem: " + IntegerToString(doji_compra_sucesso) + "| %: " + DoubleToString(doji_compra_porcentagem, 2) + " %");
    Print("##                                       ");
    Print("##   TOTAL ENCONTRADO: " + IntegerToString(doji_founds_count));
    Print("#########################################################################");
}
// Função para calcular as porcentagens do corpo e dos pavios do candle
void CalcularPercentuaisIndecisao(double open, double high, double low, double close, double &percentualCorpo, double &percentualPavioSuperior, double &percentualPavioInferior, int doji_state) {

    int state = doji_state;

    // Venda
    if(state == 2) {
        double tamanhoTotal  = high - low;
        double corpoCandle   = MathAbs(close - open);
        double pavioSuperior = high - MathMax(open, close);
        double pavioInferior = MathMin(open, close) - low;

        percentualCorpo         = (corpoCandle / tamanhoTotal) * 100;
        percentualPavioSuperior = (pavioSuperior / tamanhoTotal) * 100;
        percentualPavioInferior = (pavioInferior / tamanhoTotal) * 100;
    }
    // Compra
    else if(state == 1) {
        double tamanhoTotal  = high - low;              // Tamanho total do candle (máxima - mínima)
        double corpoCandle   = MathAbs(close - open);   // Tamanho do corpo (fechamento - abertura)
        double pavioSuperior = high - close;            // Pavio superior (máxima - fechamento)
        double pavioInferior = open - low;              // Pavio inferior (abertura - mínima)

        // Calculando os percentuais em relação ao tamanho total do candle
        percentualCorpo         = (corpoCandle / tamanhoTotal) * 100;
        percentualPavioSuperior = (pavioSuperior / tamanhoTotal) * 100;
        percentualPavioInferior = (pavioInferior / tamanhoTotal) * 100;
    }
}