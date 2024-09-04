//+------------------------------------------------------------------+
//|                                             SimpleTrade.mq5      |
//|                        Copyright 2024, Marcelokaique Andrade     |
//|                        https://www.mql5.com                      |
//+------------------------------------------------------------------+
#property copyright "marcelokaique.andrade@gmail.com"
#property link      "https://www.mql5.com"
#property version   "1.01"

//+------------------------------------------------------------------+
//| Inclusão da classe de negociação                                 |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>  // Inclui a biblioteca de trading

//+------------------------------------------------------------------+
//| Declaração de variáveis globais                                  |
//+------------------------------------------------------------------+
CTrade trade;  // Objeto da classe CTrade para execução de ordens

double highArray[3];
double lowArray[3];
double closeArray[3];
double openArray[3];
double num_lots = 0.01;
MqlTick tick;
int magic_number = 123456;  // Nº mágico do robô

sinput string s1; //-----------Parametros-------------
input double max_loss = 0.25;    // Prejuízo máximo tolerado por posição
input double max_earn = 0.5;     // Ganho máximo por posição
input double candleSTR = 0.70;   // Força do Candle de Reversão

//+------------------------------------------------------------------+
//| Função de inicialização do script                                |
//+------------------------------------------------------------------+
void OnInit()
  {
   EventSetTimer(300); // Chama a função OnTimer a cada 5 minutos
   Print("Iniciando o script e configurando o timer.");  // Log para verificar a inicialização
  }

//+------------------------------------------------------------------+
//| Função de finalização do script                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer(); // Desativa o timer quando o script é finalizado
   Print("Finalizando o script e desativando o timer.");  // Log para verificar a finalização
  }

//+------------------------------------------------------------------+
//| Função chamada a cada 5 minutos (timer)                          |
//+------------------------------------------------------------------+
void OnTimer()
  {
  
  }

//+------------------------------------------------------------------+
//| Função para verificar e fechar ordens com lucro ou prejuízo      |
//+------------------------------------------------------------------+
void FecharOrdensConformeCondicao()
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);  // Obtém o ticket da posição
        if (PositionSelectByTicket(ticket))
        {
            double lucro = PositionGetDouble(POSITION_PROFIT);  // Obtém o lucro flutuante da posição

            // Fechar posição se o prejuízo atingir o valor máximo permitido
            if (lucro <= -max_loss)
            {
                trade.PositionClose(ticket);  // Fecha a posição com prejuízo
                Print("Posição com prejuízo de ", lucro, " fechada. Ticket: ", ticket);
            }
            // Fechar posição se o lucro for igual ou superior ao lucro desejado
            else if (lucro >= max_earn)
            {
                trade.PositionClose(ticket);  // Fecha a posição com lucro
                Print("Posição com lucro de pelo menos ", max_earn, " dólar fechada. Ticket: ", ticket);
            }
        }
    }
}

  
void OnTick(void)
  {
   
   // Copie os preços dos últimos 3 candles
   if (CopyHigh(Symbol(), PERIOD_M5, 0, 3, highArray) != 3 ||
       CopyLow(Symbol(), PERIOD_M5, 0, 3, lowArray) != 3 ||
       CopyClose(Symbol(), PERIOD_M5, 0, 3, closeArray) != 3 ||
       CopyOpen(Symbol(), PERIOD_M5, 0, 3, openArray) != 3)
     {
      Print("Erro ao copiar dados dos candles.");
      return;  // Sai da função se houver erro ao copiar os dados
     }
   
   // Verifique se o padrão de indecisão seguido de um candle de força foi formado
   double corpoCandleIndecisao = MathAbs(closeArray[1] - openArray[1]); // Corpo do candle de indecisão
   double pavioCandleIndecisao = highArray[1] - lowArray[1]; // Tamanho total do candle de indecisão
   double corpoCandleForca = MathAbs(closeArray[0] - openArray[0]); // Corpo do candle de força
   
   if (corpoCandleIndecisao <= (pavioCandleIndecisao / 3) && // Candle de indecisão (corpo pequeno)
       corpoCandleForca > corpoCandleIndecisao * 2 && // Candle de força (corpo > 2x corpo do indecisão)
       corpoCandleForca >= candleSTR * (highArray[0] - lowArray[0])) // Corpo ocupa pelo menos 75% do tamanho total
     {
      // Verifique a tendência para a confirmação
      if (closeArray[0] > openArray[0] && // Candle de força é de alta
          openArray[2] < closeArray[1] && // Terceiro candle abre acima do fechamento do candle de indecisão
          closeArray[2] < openArray[2]) // Primeiro candle é de baixa
        {
         Print("Padrão de reversão de alta identificado!"); // Reversão para alta
         CompraAMercado();
        }
      else if (closeArray[0] < openArray[0] && // Candle de força é de baixa
               openArray[2] > closeArray[1] && // Terceiro candle abre abaixo do fechamento do candle de indecisão
               closeArray[2] > openArray[2]) // Primeiro candle é de alta
        {
         Print("Padrão de reversão de baixa identificado!"); // Reversão para baixa
         VendeAMercado();
        }
     }
               // Verifica e fecha ordens com lucro ou prejuízo conforme definido
   FecharOrdensConformeCondicao();

  }

//+------------------------------------------------------------------+
//| Função de compra a mercado                                       |
//+------------------------------------------------------------------+
void CompraAMercado()
  {
   trade.SetExpertMagicNumber(magic_number);  // Define o número mágico para o trade
   if(trade.Buy(num_lots, _Symbol))
     {
      Print("Ordem de Compra executada com sucesso!");
     }
   else
     {
      Print("Erro ao enviar Ordem de Compra. Erro = ", trade.ResultRetcode());
     }
  }

//+------------------------------------------------------------------+
//| Função de venda a mercado                                        |
//+------------------------------------------------------------------+
void VendeAMercado()
  {
   trade.SetExpertMagicNumber(magic_number);  // Define o número mágico para o trade
   if(trade.Sell(num_lots, _Symbol))
     {
      Print("Ordem de Venda executada com sucesso!");
     }
   else
     {
      Print("Erro ao enviar Ordem de Venda. Erro = ", trade.ResultRetcode());
     }
  }