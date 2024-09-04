//+------------------------------------------------------------------+
//|                                                        study.mq5 |
//|                                                   marcelo kaique |
//|                                  marcelokaique.andrade@gmail.com |
//+------------------------------------------------------------------+
#property copyright "marcelo kaique"
#property link      "marcelokaique.andrade@gmail.com"
#property version   "1.00"

// Variáveis globais
datetime lastCandleTime = 0; // Variável para armazenar o horário do último candle processado
double last_open = 0; // Variável para armazenar o preço de abertura do último candle fechado

//+------------------------------------------------------------------+
//| Função de inicialização do Expert                                |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Inicializa lastCandleTime com o horário do último candle completado
   lastCandleTime = iTime(_Symbol, PERIOD_M5, 0);

   // Inicializa last_open com o preço de abertura do último candle fechado
   last_open = iOpen(_Symbol, PERIOD_M5, 1);
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Função de desinicialização do Expert                             |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
//| Função chamada a cada tick                                       |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Pega o horário do último candle completado
   datetime currentLastCandleTime = iTime(_Symbol, PERIOD_M5, 0);

   // Verifica se um novo candle apareceu
   if (currentLastCandleTime != lastCandleTime)
     {
      // Atualiza o horário do último candle processado
      lastCandleTime = currentLastCandleTime;

      // Dados da última vela fechada
      double open = iOpen(_Symbol, PERIOD_M5, 1); // Índice 1 para a última vela fechada
      double high = iHigh(_Symbol, PERIOD_M5, 1);
      double low = iLow(_Symbol, PERIOD_M5, 1);
      double close = iClose(_Symbol, PERIOD_M5, 1);

      // Define o limite de diferença em pontos (22 pontos)
      double DiffLimit = 22 * _Point;

      if (IsDojiCandle(open, close, high, low, DiffLimit)) {
          // Se o preço de fechamento do DOJI estiver abaixo do preço de abertura do candle anterior, ele pode ser considerado um sinal de venda.
          if (close < last_open) {
              Print("Doji de Venda! - Vela Vermelha --- Fechamento Atual: ", close, " | Abertura Anterior: ", last_open);
          } 
          // Se o preço de fechamento do Doji estiver acima do preço de abertura do candle anterior, ele pode ser considerado um sinal de compra
          else if (close > last_open) {
              Print("Doji de Compra! - Vela Verde --- Fechamento Atual: ", close, " | Abertura Anterior: ", last_open);
          } 
      }else
         {
          Print("Aguardando DOJI...");
         }

      // Atualiza last_open para o próximo ciclo
      last_open = open;
     }
  }

//+------------------------------------------------------------------+
//| Verificar se o último candle é um candle de indecisão |
//+------------------------------------------------------------------+
bool IsDojiCandle(double open, double close, double high, double low, double DiffLimit)
{
    // Calcula o corpo da vela
    double body = MathAbs(open - close);

    // Calcula as sombras superior e inferior
    double upperShadow = high - MathMax(open, close);
    double lowerShadow = MathMin(open, close) - low;

    // Define um limiar para considerar a vela como indecisa
    double bodyThreshold = 0.1 * (high - low); // Corpo da vela deve ser pequeno
    double shadowThreshold = 0.4 * (high - low); // Sombras devem ser longas

    // Verifica se o corpo da vela é pequeno e se as sombras são longas
    if (body <= bodyThreshold && (upperShadow >= shadowThreshold && lowerShadow >= shadowThreshold)) {
        return true;
    }

    return false;
} 
//+------------------------------------------------------------------+
