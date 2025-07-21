# IRR Genius - Calculation Specifications

This document defines the mathematical formulas and business logic used in both iOS and Android versions of IRR Genius.

## Core Formulas

### 1. Internal Rate of Return (IRR)

**Formula**: `IRR = (FV / PV)^(1/n) - 1`

Where:
- `FV` = Future Value (outcome)
- `PV` = Present Value (initial investment)
- `n` = Number of years

**Implementation**: Both platforms use this exact formula for basic IRR calculations.

### 2. Future Value Calculation

**Formula**: `FV = PV × (1 + IRR)^n`

Where:
- `PV` = Present Value (initial investment)
- `IRR` = Internal Rate of Return (as decimal)
- `n` = Number of years

### 3. Present Value Calculation

**Formula**: `PV = FV / (1 + IRR)^n`

Where:
- `FV` = Future Value (target outcome)
- `IRR` = Internal Rate of Return (as decimal)
- `n` = Number of years

### 4. Blended IRR Calculation

For investments with follow-on investments, the calculation becomes more complex:

1. **Tag-Along Investments**: Follow the same IRR trajectory as the initial investment
2. **Custom Valuations**: Use specified valuations at the time of follow-on investment
3. **Time-Weighted Returns**: Account for the timing of each investment

**Method**: Money-weighted return calculation using all cash flows and their timing.

## Data Models

### FollowOnInvestment

Common structure across platforms:

```
- id: String (UUID)
- amount: Double
- investmentType: Buy | Sell | BuySell
- timingType: Absolute | Relative
- absoluteDate: Date
- relativeTime: Double
- relativeTimeUnit: Days | Months | Years
- valuationMode: TagAlong | Custom
- valuationType: Computed | Specified
- customValuation: Double
```

### GrowthPoint

Chart data structure:

```
- month: Float (0-based month index)
- value: Float (investment value at that time)
```

## Calculation Modes

### Mode 1: Calculate IRR
- **Inputs**: Initial Investment, Outcome Value, Years
- **Output**: IRR percentage
- **Formula**: Basic IRR formula

### Mode 2: Calculate Outcome
- **Inputs**: Initial Investment, Target IRR, Years
- **Output**: Future Value
- **Formula**: Future Value formula

### Mode 3: Calculate Initial Investment
- **Inputs**: Target Outcome, Target IRR, Years
- **Output**: Required Initial Investment
- **Formula**: Present Value formula

### Mode 4: Calculate Blended IRR
- **Inputs**: Initial Investment, Final Outcome, Years, Follow-on Investments
- **Output**: Blended IRR percentage
- **Formula**: Complex time-weighted calculation

## Number Formatting Standards

### Currency
- Format: `$#,##0` (no decimals for whole amounts)
- Example: `$1,000,000`

### Percentages
- Format: `0.##%` (up to 2 decimal places)
- Example: `15.75%`

### Numbers
- Format: `#,##0.##` (commas for thousands, up to 2 decimals)
- Example: `2.5` for years, `1,234.56` for multiples

## Error Handling

### Input Validation
- All monetary values must be > 0
- Years must be > 0
- IRR percentages can be negative but should be validated for reasonableness
- Follow-on investment dates must be logical

### Edge Cases
- Zero values return 0
- Very large numbers should be handled gracefully
- Negative IRR results should be displayed properly

## Chart Generation

### Growth Points
- Generate monthly data points (0 to total_years × 12)
- Use exponential growth formula: `value = initial × (1 + IRR)^(month/12)`
- Include impact of follow-on investments at their respective timing

### Follow-On Investment Visualization
- Show investment timing markers on charts
- Adjust growth trajectory based on additional investments
- Handle different valuation modes correctly

## Testing Standards

### Required Test Cases
1. **Basic IRR**: $100 → $150 in 2 years = 22.47% IRR
2. **Future Value**: $100 at 15% for 3 years = $152.09
3. **Initial Investment**: $200 target at 10% in 5 years = $124.18 initial
4. **Round-trip**: Calculate outcome, then IRR from outcome should match original IRR
5. **Zero values**: Should return 0 without errors
6. **Edge cases**: Very small/large numbers, negative IRR

### Precision Requirements
- Financial calculations should be accurate to at least 4 decimal places
- Display precision can be lower (2 decimal places for percentages)
- Use epsilon comparison for floating-point tests (0.0001)

## Platform-Specific Notes

### iOS (Swift)
- Use `Double` for all calculations
- `Calendar` for date arithmetic
- `NumberFormatter` for display formatting

### Android (Kotlin)
- Use `Double` for all calculations  
- `LocalDate` and `ChronoUnit` for date arithmetic
- `DecimalFormat` for display formatting

Both platforms should produce identical results for the same inputs.