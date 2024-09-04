// Variável global para armazenar o timestamp do último candle processado
datetime lastCandleTime = 0;

// Função para obter e imprimir as informações dos últimos três candles
void GetLastThreeCandlesInfo()
{
    datetime time[3];
    double open[3], high[3], low[3], close[3];
    
    // Copiar dados dos candles dos últimos três candles
    if (CopyTime(_Symbol, PERIOD_M5, 0, 3, time) != 3 ||
        CopyOpen(_Symbol, PERIOD_M5, 0, 3, open) != 3 ||
        CopyHigh(_Symbol, PERIOD_M5, 0, 3, high) != 3 ||
        CopyLow(_Symbol, PERIOD_M5, 0, 3, low) != 3 ||
        CopyClose(_Symbol, PERIOD_M5, 0, 3, close) != 3)
    {
        Print("Falha ao recuperar os dados dos candles.");
        return;
    }

    Print("Novo Candle Adicionado - m5");
    // Imprimir as informações dos últimos três candles
    for (int i = 0; i < 3; i++)
    {
        bool isIndecision = IsIndecisionCandle(open[i], close[i], high[i], low[i]);
        string indecisionStatus = isIndecision ? "Indecisão" : "Não Indecisão";
        PrintFormat("Candle %d - Hora: %s, Abertura: %.5f, Máxima: %.5f, Mínima: %.5f, Fechamento: %.5f, Status: %s",
                    i + 1, TimeToString(time[i], TIME_DATE | TIME_MINUTES), open[i], high[i], low[i], close[i], indecisionStatus);
    }

    // Verificar se o candle na segunda posição do array é de indecisão
    if (IsIndecisionCandle(open[1], close[1], high[1], low[1]))
    {
        // Verificar se o último candle tem força de compra ou venda
        bool isBullish = (close[2] > open[2]); // Último candle é de alta se o fechamento for maior que a abertura
        bool isBearish = (close[2] < open[2]); // Último candle é de baixa se o fechamento for menor que a abertura

        if (isBullish)
        {
            Print("O último candle tem força de compra.");
        }
        else if (isBearish)
        {
            Print("O último candle tem força de venda.");
        }
        else
        {
            Print("O último candle é neutro.");
        }
    }
}

//+------------------------------------------------------------------+
//| Função de inicialização do Expert                                 |
//+------------------------------------------------------------------+
int OnInit()
  {
    // Código de inicialização, se necessário
    return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Função de desinicialização do Expert                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
    // Código de limpeza, se necessário
  }

//+------------------------------------------------------------------+
//| Função chamada a cada tick                                        |
//+------------------------------------------------------------------+
void OnTick()
  {
    // Obter o timestamp do último candle atual
    datetime currentLastCandleTime = iTime(_Symbol, PERIOD_M5, 0);

    // Verificar se um novo candle apareceu
    if (currentLastCandleTime != lastCandleTime)
    {
        // Atualizar o timestamp do último candle processado
        lastCandleTime = currentLastCandleTime;
        
        // Chamar a função para obter e imprimir as informações dos últimos três candles
        GetLastThreeCandlesInfo();
    }
  }

//+------------------------------------------------------------------+
//| Função para verificar se o candle é de indecisão                 |
//+------------------------------------------------------------------+
bool IsIndecisionCandle(double open, double close, double high, double low)
{
    // Calcular o corpo do candle
    double body = MathAbs(close - open);
    
    // Calcular o comprimento total do candle
    double totalLength = high - low;
    
    // Calcular o comprimento das sombras
    double upperShadow = high - MathMax(open, close);
    double lowerShadow = MathMin(open, close) - low;
    
    // Verificar se o corpo é pequeno comparado com o comprimento total
    if (body / totalLength < 0.3 && upperShadow > body && lowerShadow > body)
    {
        return true; // É um candle de indecisão
    }
    return false; // Não é um candle de indecisão
}
