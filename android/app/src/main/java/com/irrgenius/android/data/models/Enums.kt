package com.irrgenius.android.data.models

enum class CalculationMode {
    CALCULATE_IRR,
    CALCULATE_OUTCOME,
    CALCULATE_INITIAL,
    CALCULATE_BLENDED,
    PORTFOLIO_UNIT_INVESTMENT
}

enum class ValuationType {
    COMPUTED,
    SPECIFIED
}

enum class ValuationMode {
    TAG_ALONG,
    CUSTOM
}

enum class InvestmentType {
    BUY,
    SELL,
    BUY_SELL
}

enum class TimingType {
    ABSOLUTE,
    RELATIVE
}

enum class TimeUnit {
    DAYS,
    MONTHS,
    YEARS
}