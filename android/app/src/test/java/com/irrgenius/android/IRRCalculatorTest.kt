package com.irrgenius.android

import com.irrgenius.android.domain.calculator.IRRCalculator
import org.junit.Test
import org.junit.Assert.*
import kotlin.math.abs

class IRRCalculatorTest {
    private val calculator = IRRCalculator()
    private val epsilon = 0.0001 // For floating point comparison
    
    @Test
    fun testBasicIRRCalculation() {
        // Test: $100 investment becomes $150 in 2 years
        // Expected IRR = (150/100)^(1/2) - 1 = 0.2247 (22.47%)
        val irr = calculator.calculateIRRValue(100.0, 150.0, 2.0)
        val expected = 0.2247448714
        assertTrue("IRR should be approximately 22.47%", abs(irr - expected) < epsilon)
    }
    
    @Test
    fun testOutcomeCalculation() {
        // Test: $100 at 15% IRR for 3 years should be $152.09
        val outcome = calculator.calculateOutcomeValue(100.0, 0.15, 3.0)
        val expected = 152.0875
        assertTrue("Outcome should be approximately $152.09", abs(outcome - expected) < 0.01)
    }
    
    @Test
    fun testInitialCalculation() {
        // Test: To get $200 at 10% IRR in 5 years, need initial investment of $124.18
        val initial = calculator.calculateInitialValue(200.0, 0.10, 5.0)
        val expected = 124.1841442
        assertTrue("Initial should be approximately $124.18", abs(initial - expected) < 0.01)
    }
    
    @Test
    fun testZeroValues() {
        assertEquals("IRR should be 0 for zero initial", 0.0, calculator.calculateIRRValue(0.0, 100.0, 1.0), epsilon)
        assertEquals("IRR should be 0 for zero outcome", 0.0, calculator.calculateIRRValue(100.0, 0.0, 1.0), epsilon)
        assertEquals("IRR should be 0 for zero years", 0.0, calculator.calculateIRRValue(100.0, 150.0, 0.0), epsilon)
    }
    
    @Test
    fun testGrowthPoints() {
        // Test growth points generation
        val points = calculator.growthPoints(100.0, 0.10, 1.0)
        
        assertTrue("Should have 13 points (0-12 months)", points.size == 13)
        assertEquals("First point should be initial value", 100.0, points[0].value, 0.01)
        assertTrue("Last point should be ~110 (10% growth)", abs(points[12].value - 110.0) < 0.5)
    }
    
    @Test
    fun testRoundTripCalculations() {
        // Test that calculations are consistent
        val initial = 1000.0
        val irr = 0.20
        val years = 3.0
        
        // Calculate outcome
        val outcome = calculator.calculateOutcomeValue(initial, irr, years)
        
        // Calculate IRR back from outcome
        val calculatedIRR = calculator.calculateIRRValue(initial, outcome, years)
        
        // Should be very close to original IRR
        assertTrue("Round-trip IRR calculation should be consistent", 
                  abs(irr - calculatedIRR) < epsilon)
    }
}