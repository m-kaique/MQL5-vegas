class EricaMovingAverage {
  public:
    int                ma_period;       //=10;                 // period of ma
    int                ma_shift;        //=0;                   // shift
    ENUM_MA_METHOD     ma_method;       //=MODE_SMA;           // type of smoothing
    ENUM_APPLIED_PRICE applied_price;   //=PRICE_CLOSE;    // type of price
    string             symbol;          //=" ";                   // symbol
    ENUM_TIMEFRAMES    period;          //=PERIOD_CURRENT;        // timeframe

    // EricaMovingAverage ma(9, 0, MODE_SMA, PRICE_CLOSE, Symbol(), PERIOD_CURRENT)

    EricaMovingAverage(
        int                e_ma_period,
        int                e_ma_shift,
        ENUM_MA_METHOD     e_ma_method,
        ENUM_APPLIED_PRICE e_applied_price,
        string             e_symbol,
        ENUM_TIMEFRAMES    e_period) {

        //--
        ma_period     = e_ma_period;
        ma_shift      = e_ma_shift;
        ma_method     = e_ma_method;
        applied_price = e_applied_price;
        symbol        = e_symbol;
        period        = e_period;
    }

    double calculate(ENUM_APPLIED_PRICE e_applied_price) {

        return iMA(symbol, period, ma_period, ma_shift, ma_method, applied_price);
    }
}