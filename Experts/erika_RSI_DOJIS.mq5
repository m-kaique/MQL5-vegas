//+------------------------------------------------------------------+
//|                                                  RSI OBOS EA.mq5 |
//|                                                   marcelo kaique |
//|                                  marcelokaique.andrade@gmail.com |
//+------------------------------------------------------------------+
#property copyright "marcelo kaique"
#property link "marcelokaique.andrade@gmail.com"
#property version "1.00"

#include <Trade/Trade.mqh>

CTrade       *Trade;
CPositionInfo PositionInfo;

input group "General INPUTS";
input string          SymbolTraded = "EURUSD";
input ENUM_TIMEFRAMES PeriodTraded = PERIOD_M5;
input int             EAMagic      = 767565645;
input int             MaxSlippage  = 1;

input group "DOJI INPUTS";

input group "RSI INPUTS";
input int                RSIPeriod       = 14;
input ENUM_APPLIED_PRICE RSIAppliedPrice = PRICE_CLOSE;
input int                OverSoldLevel   = 30;
input int                OverBuyLevel    = 70;

// RSI
int    RSIHandle;
int    OldNumBars;
double RSIBuffer[];

// DOJI -------------------------------------------------------------
int total_doji_alta  = 0;
int total_doji_baixa = 0;

// Contadores para validações de compra e venda
int total_validacoes_compra = 0;
int total_validacoes_venda  = 0;

// Variável para armazenar se o último candle foi um Doji
bool ultimo_foi_doji_alta  = false;
bool ultimo_foi_doji_baixa = false;
//       -------------------------------------------------------------

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {

    //---
    ChartSetInteger(0, CHART_SHOW_GRID, false);
    ChartSetInteger(0, CHART_MODE, CHART_CANDLES);
    ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrBlack);
    ChartSetInteger(0, CHART_COLOR_FOREGROUND, clrWhite);
    ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, clrLightGreen);
    ChartSetInteger(0, CHART_COLOR_CHART_UP, clrSkyBlue);
    ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, clrRed);
    ChartSetInteger(0, CHART_COLOR_CHART_DOWN, clrIndianRed);
    ChartSetInteger(0, CHART_COLOR_STOP_LEVEL, clrGold);
    ChartSetInteger(0, CHART_SHOW_VOLUMES, false);

    Trade                   = new CTrade;
    ulong MaxSlippagePoints = MaxSlippage * 10;
    Trade.SetDeviationInPoints(MaxSlippage);
    Trade.SetExpertMagicNumber(EAMagic);

    RSIHandle = iRSI(SymbolTraded, PeriodTraded, RSIPeriod, RSIAppliedPrice);
    ArraySetAsSeries(RSIBuffer, true);

    //---
    return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    //---
    IndicatorRelease(RSIHandle);
    delete Trade;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    //---
    if(!IsNewBar())
        return;

    CopyBuffer(RSIHandle, 0, 0, 4, RSIBuffer);
    DojiSignal();
    // BUY SIGNAL
    if(BuySignal()) {
        double PriceClose = iClose(SymbolTraded, PeriodTraded, 1);
        string ObjName    = "ObjName" + (string)iTime(SymbolTraded, PeriodTraded, 1);

        if(!ObjectCreate(
               0, ObjName, OBJ_TREND, 0, iTime(SymbolTraded, PeriodTraded, 1),
               PriceClose, iTime(SymbolTraded, PeriodTraded, 0), PriceClose)) {
            return;
        }

        else {
            ObjectSetInteger(0, ObjName, OBJPROP_COLOR, clrCyan);
            ObjectSetInteger(0, ObjName, OBJPROP_WIDTH, 5);
        }
    } /*end Buy Signal*/

    // Sell SIGNAL
    if(SellSignal()) {
        double PriceClose = iClose(SymbolTraded, PeriodTraded, 1);
        string ObjName    = "ObjName" + (string)iTime(SymbolTraded, PeriodTraded, 1);

        if(!ObjectCreate(
               0, ObjName, OBJ_TREND, 0, iTime(SymbolTraded, PeriodTraded, 1),
               PriceClose, iTime(SymbolTraded, PeriodTraded, 0), PriceClose)) {
            return;
        } else {
            ObjectSetInteger(0, ObjName, OBJPROP_COLOR, clrRed);
            ObjectSetInteger(0, ObjName, OBJPROP_WIDTH, 5);
        }
    } /*end Buy Signal*/
}
//+------------------------------------------------------------------+
bool IsNewBar() {
    int bars = Bars(SymbolTraded, PeriodTraded);
    if(OldNumBars != bars) {
        OldNumBars = bars;
        return true;
    }
    return false;
}
//+------------------------------------------------------------------+

int NumberOfBuy() {
    int Num = 0;
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(!PositionInfo.SelectByIndex(i)) {
            continue;
        }
        if(PositionInfo.Magic() != EAMagic) {
            continue;
        }
        if(PositionInfo.Symbol() != SymbolTraded) {
            continue;
        }

        if(PositionInfo.PositionType() != POSITION_TYPE_BUY) {
            continue;
        }

        Num++;
    }
    return Num;
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
int NumberOfSell() {
    int Num = 0;
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(!PositionInfo.SelectByIndex(i)) {
            continue;
        }
        if(PositionInfo.Magic() != EAMagic) {
            continue;
        }
        if(PositionInfo.Symbol() != SymbolTraded) {
            continue;
        }

        if(PositionInfo.PositionType() != POSITION_TYPE_SELL) {
            continue;
        }

        Num++;
    }
    return Num;
}
//+------------------------------------------------------------------+
// Função para verificar se o candle é um Doji com proporções 50/50, 40/60, 60/40
bool IsDojiProporcional(double open, double close, double high, double low) {
    double corpo = MathAbs(close - open);

    double sombra_superior = 0.0;
    double sombra_inferior = 0.0;

    // Verifica se é um candle de alta (fechamento >= abertura)
    if(close >= open) {
        sombra_superior = high - close;   // Sombra superior para candle de alta
        sombra_inferior = open - low;     // Sombra inferior para candle de alta
    }
    // Verifica se é um candle de baixa (abertura > fechamento)
    else {
        sombra_superior = high - open;   // Sombra superior para candle de baixa
        sombra_inferior = close - low;   // Sombra inferior para candle de baixa
    }

    // Verificar se o corpo é pequeno em relação às sombras (não precisa ser zero)
    bool corpo_pequeno = corpo < (sombra_superior + sombra_inferior) * 0.1;

    // Verificar a proporção entre as sombras superior e inferior
    double proporcao_sombras = sombra_superior / (sombra_superior + sombra_inferior);

    // Considerar Doji válido se as sombras estiverem dentro das faixas aceitáveis (entre 40/60 e 60/40)
    bool sombras_equilibradas = (proporcao_sombras >= 0.4 && proporcao_sombras <= 0.6);

    // Retornar verdadeiro se o corpo for pequeno e as sombras estiverem equilibradas
    return corpo_pequeno && sombras_equilibradas;
}
//+------------------------------------------------------------------+
// Função para verificar se o próximo candle é um candle de força
bool IsCandleForca(double open, double close, double high, double low, double tamanho_doji) {
    double corpo         = MathAbs(close - open);
    double tamanho_total = high - low;

    // Verificar se o corpo é 75% do tamanho total
    bool corpo_75_pct = corpo >= (tamanho_total * 0.60);

    // Verificar se o tamanho total do candle de força é maior ou igual ao tamanho do Doji anterior
    bool tamanho_maior_ou_igual = tamanho_total >= tamanho_doji;

    // Retornar verdadeiro se ambas as condições forem atendidas
    return corpo_75_pct && tamanho_maior_ou_igual;
}
//+------------------------------------------------------------------+
bool BuySignal() {
    if(NumberOfBuy() == 0 && RSIBuffer[1] >= OverSoldLevel && RSIBuffer[2] <= OverSoldLevel) {
        Print("RSI - Sinal de Compra");
        return true;
    }

    return false;
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool SellSignal() {
    if(NumberOfSell() == 0 && RSIBuffer[1] <= OverBuyLevel && RSIBuffer[2] >= OverBuyLevel) {
        Print("RSI - Sinal de Venda");
        return true;
    }

    return false;
}

void DojiSignal() {
    static datetime lastTime     = 0;
    static double   tamanho_doji = 0.0;   // Para armazenar o tamanho do último Doji

    // Processar o candle anterior
    int    shift = 1;
    double open  = iOpen(_Symbol, _Period, shift);
    double close = iClose(_Symbol, _Period, shift);
    double high  = iHigh(_Symbol, _Period, shift);
    double low   = iLow(_Symbol, _Period, shift);

    // Se o último candle foi um Doji, verificar se o próximo é um candle de força
    if(ultimo_foi_doji_alta) {
        if(IsCandleForca(open, close, high, low, tamanho_doji)) {
            Print("Doji de alta seguido de Força de alta, abrir ordem de compra.");
            total_validacoes_compra++;   // Incrementar o contador de validações de compra
                                         // Aqui você pode colocar o código para abrir a ordem de compra
        }
        ultimo_foi_doji_alta = false;   // Reiniciar
    } else if(ultimo_foi_doji_baixa) {
        if(IsCandleForca(open, close, high, low, tamanho_doji)) {
            Print("Doji de baixa seguido de Força de baixa, abrir ordem de venda.");
            total_validacoes_venda++;   // Incrementar o contador de validações de venda
                                        // Aqui você pode colocar o código para abrir a ordem de venda
        }
        ultimo_foi_doji_baixa = false;   // Reiniciar
    }

    // Verificar se o candle atual é um Doji
    if(IsDojiProporcional(open, close, high, low)) {
        tamanho_doji = high - low;   // Armazenar o tamanho do Doji para a próxima validação

        if(close >= open)   // Doji de alta
        {
            Print("Encontrado Doji Proporcional de Alta em: ", TimeToString(iTime(_Symbol, _Period, shift), TIME_DATE | TIME_MINUTES));
            total_doji_alta++;
            ultimo_foi_doji_alta = true;   // Marcar que o próximo candle deve ser verificado como de força
        } else if(open > close)            // Doji de baixa
        {
            Print("Encontrado Doji Proporcional de Baixa em: ", TimeToString(iTime(_Symbol, _Period, shift), TIME_DATE | TIME_MINUTES));
            total_doji_baixa++;
            ultimo_foi_doji_baixa = true;   // Marcar que o próximo candle deve ser verificado como de força
        }
    }

    // Atualizar o tempo processado
    lastTime = iTime(_Symbol, _Period, shift);
}