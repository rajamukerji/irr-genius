package com.irrgenius.android.data.database

import androidx.room.TypeConverter
import com.irrgenius.android.data.models.*
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

class Converters {
    
    @TypeConverter
    fun fromLocalDateTime(value: LocalDateTime?): String? {
        return value?.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME)
    }
    
    @TypeConverter
    fun toLocalDateTime(value: String?): LocalDateTime? {
        return value?.let { LocalDateTime.parse(it, DateTimeFormatter.ISO_LOCAL_DATE_TIME) }
    }
    
    @TypeConverter
    fun fromCalculationMode(value: CalculationMode): String {
        return value.name
    }
    
    @TypeConverter
    fun toCalculationMode(value: String): CalculationMode {
        return CalculationMode.valueOf(value)
    }
    
    @TypeConverter
    fun fromInvestmentType(value: InvestmentType): String {
        return value.name
    }
    
    @TypeConverter
    fun toInvestmentType(value: String): InvestmentType {
        return InvestmentType.valueOf(value)
    }
    
    @TypeConverter
    fun fromTimingType(value: TimingType): String {
        return value.name
    }
    
    @TypeConverter
    fun toTimingType(value: String): TimingType {
        return TimingType.valueOf(value)
    }
    
    @TypeConverter
    fun fromTimeUnit(value: TimeUnit?): String? {
        return value?.name
    }
    
    @TypeConverter
    fun toTimeUnit(value: String?): TimeUnit? {
        return value?.let { TimeUnit.valueOf(it) }
    }
    
    @TypeConverter
    fun fromValuationMode(value: ValuationMode): String {
        return value.name
    }
    
    @TypeConverter
    fun toValuationMode(value: String): ValuationMode {
        return ValuationMode.valueOf(value)
    }
    
    @TypeConverter
    fun fromValuationType(value: ValuationType): String {
        return value.name
    }
    
    @TypeConverter
    fun toValuationType(value: String): ValuationType {
        return ValuationType.valueOf(value)
    }
}