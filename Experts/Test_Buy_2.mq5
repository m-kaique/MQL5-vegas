//+------------------------------------------------------------------+
//|                                                       DojiFinder |
//|                        Copyright 2024, MetaTrader 5 Demo         |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

CTrade trade;

int    total_doji_alta         = 0;      // Contador de Dojis de alta encontrados
int    total_validacoes_compra = 0;      // Contador de validações de compra (Doji seguido de força)
int    total_ordens_possiveis  = 0;      // Totalizador para ordens possíveis de compra
int    total_ordens_abertas    = 0;      // Totalizador de ordens de compra abertas
double total_lucro_perda       = 0.0;    // Acumulador para lucro/perda
double limite_lucro            = 0.10;   // Limite de lucro para fechar a ordem
int    OldNumBars              = 0;      // Armazena o número de barras para monitorar novas barras

// Variáveis para armazenar se o último candle foi um Doji ou um candle de força
double fechamento_forca_alta = 0.0;   // Armazenar o fechamento do candle de força
double maxima_forca_alta     = 0.0;   // Armazenar a máxima do candle de força
double tamanho_doji_global   = 0.0;   // Armazenar o tamanho do Doji (ajustado para evitar conflitos)

//
double open_doji   = 0.0;   // Open da vela 2 (Doji)
double close_doji  = 0.0;   // CLose da vela 2 (Doji)
double high_doji   = 0.0;   // High da vela 2 (Doji)
double low_doji    = 0.0;   // Low da vela 2 (Doji)
double open_forca  = 0.0;   // Open da vela 1 (Força)
double close_forca = 0.0;   // Close da vela 1 (Força)
double high_forca  = 0.0;   // High da vela 1 (Força)
double low_forca   = 0.0;   // Low da vela 1 (Força)
double open_atual  = 0.0;   // Open da vela atual (0)
//

// Função para verificar se é uma nova barra
bool IsNewBar() {
    int bars = Bars(_Symbol, _Period);
    if(OldNumBars != bars) {
        OldNumBars = bars;
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    Print("Iniciando análise de Doji Proporcional e Candles de Força...");
    OldNumBars = Bars(_Symbol, _Period);   // Inicializar a contagem de barras
    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print("Finalizando Expert Advisor.");
    Print("Total de validações de compra (Doji seguido de força de alta): ", total_validacoes_compra);
    Print("Total de ordens possíveis de compra: ", total_ordens_possiveis);
    Print("Total de ordens de compra abertas: ", total_ordens_abertas);
    Print("Lucro/Perda total: ", DoubleToString(total_lucro_perda, 2));
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    if(!IsNewBar())   // Verificar se há uma nova barra
        return;

    open_doji  = iOpen(_Symbol, PERIOD_CURRENT, 2);   // Pegar dados da vela 2 (Doji)
    close_doji = iClose(_Symbol, PERIOD_CURRENT, 2);
    high_doji  = iHigh(_Symbol, PERIOD_CURRENT, 2);
    low_doji   = iLow(_Symbol, PERIOD_CURRENT, 2);
    //
    open_forca  = iOpen(_Symbol, PERIOD_CURRENT, 1);   // Pegar dados da vela 1 (Força)
    close_forca = iClose(_Symbol, PERIOD_CURRENT, 1);
    high_forca  = iHigh(_Symbol, PERIOD_CURRENT, 1);
    low_forca   = iLow(_Symbol, PERIOD_CURRENT, 1);
    //
    open_atual = iOpen(_Symbol, PERIOD_CURRENT, 0);   // Vela atual (0)

    // Se o candle anterior (vela 1) for de força e precedido por um Doji (vela 2), definir a variável
    if(IsDojiProporcional(open_doji, close_doji, high_doji, low_doji)) {
        if(IsCandleForca(open_forca, close_forca, high_forca, low_forca, high_doji - low_doji)) {
            fechamento_forca_alta = close_forca;   // Armazenar o fechamento do candle de força
            maxima_forca_alta     = high_forca;    // Armazenar a máxima do candle de força
            AbrirOrdemCompra();
        }
    }
    MonitorarLucro();
}

// Função para verificar se o candle é um Doji com proporções 50/50, 40/60, 60/40
bool IsDojiProporcional(double open, double close, double high, double low) {
    double corpo           = MathAbs(close - open);
    double sombra_superior = (close >= open) ? high - close : high - open;
    double sombra_inferior = (close >= open) ? open - low : close - low;

    bool   corpo_pequeno     = corpo < (sombra_superior + sombra_inferior) * 0.1;
    double proporcao_sombras = sombra_superior / (sombra_superior + sombra_inferior);

    return corpo_pequeno && proporcao_sombras >= 0.4 && proporcao_sombras <= 0.6;
}

// Função para verificar se o próximo candle é um candle de força
bool IsCandleForca(double open, double close, double high, double low, double tamanho_doji) {
    double corpo         = MathAbs(close - open);
    double tamanho_total = high - low;

    // Verificar se o corpo é 75% do tamanho total e se o candle de força é 25% maior que o Doji
    bool corpo_75_pct     = corpo >= (tamanho_total * 0.60);
    bool tamanho_maior_25 = tamanho_total >= tamanho_doji * 1.25;   // Candle de força deve ser 25% maior que o Doji

    return corpo_75_pct && tamanho_maior_25;
}

// Função para validar o próximo candle após o candle de força
bool ValidarCandleAtual(double abertura_atual, double fechamento_forca) {
    if(abertura_atual >= fechamento_forca) {
        Print("Próximo candle abriu no mesmo valor ou acima do fechamento: ", DoubleToString(fechamento_forca, 5));
        return true;
    }
    return false;   // Não atende às condições
}

// Função para abrir a ordem de compra a preço de mercado
void AbrirOrdemCompra() {
    double preco_ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);   // Obter preço Ask atual
    if(trade.Buy(0.01, _Symbol, preco_ask, 0, 0)) {
        Print("Ordem de compra aberta a ", DoubleToString(preco_ask, 5));
        total_ordens_abertas++;   // Incrementar o total de ordens abertas
    } else {
        Print("Erro ao abrir ordem de compra.");
    }
}

// Função para monitorar o lucro e fechar a posição quando atingir o limite de lucro
void MonitorarLucro() {
    int total_positions = PositionsTotal();   // Obter o total de posições abertas

    // Percorrer todas as posições, do mais recente para o mais antigo
    for(int i = total_positions - 1; i >= 0; i--) {
        if(PositionSelect(PositionGetSymbol(i)))   // Selecionar a posição pelo símbolo
        {
            // Verificar se a posição é do símbolo atual
            if(PositionGetString(POSITION_SYMBOL) == _Symbol) {
                double lucro = PositionGetDouble(POSITION_PROFIT);   // Obter o lucro atual da posição
                Print("Lucro atual: ", DoubleToString(lucro, 2));

                // Verificar se o lucro atingiu ou excedeu o limite de lucro
                if(lucro >= limite_lucro) {
                    Print("Lucro de ", DoubleToString(lucro, 2), " atingido. Fechando a posição.");

                    // Fechar a posição usando o ticket
                    ulong ticket = PositionGetInteger(POSITION_TICKET);
                    if(trade.PositionClose(ticket)) {
                        Print("Posição fechada com sucesso.");
                        total_lucro_perda += lucro;   // Acumular o lucro total
                    } else {
                        Print("Erro ao fechar a posição.");
                    }
                }
            }
        }
    }
}