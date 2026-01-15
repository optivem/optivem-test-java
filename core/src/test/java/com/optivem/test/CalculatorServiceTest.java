package com.optivem.test;

import org.junit.Before;
import org.junit.Test;
import static org.junit.Assert.*;

/**
 * Unit tests for CalculatorService.
 */
public class CalculatorServiceTest {
    
    private CalculatorService calculator;
    
    @Before
    public void setUp() {
        calculator = new CalculatorService();
    }
    
    @Test
    public void testAdd() {
        assertEquals(5.0, calculator.add(2.0, 3.0), 0.001);
        assertEquals(0.0, calculator.add(-5.0, 5.0), 0.001);
        assertEquals(-8.0, calculator.add(-3.0, -5.0), 0.001);
    }
    
    @Test
    public void testSubtract() {
        assertEquals(-1.0, calculator.subtract(2.0, 3.0), 0.001);
        assertEquals(5.0, calculator.subtract(10.0, 5.0), 0.001);
        assertEquals(-2.0, calculator.subtract(-5.0, -3.0), 0.001);
    }
    
    @Test
    public void testMultiply() {
        assertEquals(6.0, calculator.multiply(2.0, 3.0), 0.001);
        assertEquals(0.0, calculator.multiply(0.0, 5.0), 0.001);
        assertEquals(-15.0, calculator.multiply(-3.0, 5.0), 0.001);
    }
    
    @Test
    public void testDivide() {
        assertEquals(2.0, calculator.divide(6.0, 3.0), 0.001);
        assertEquals(-2.0, calculator.divide(-10.0, 5.0), 0.001);
        assertEquals(0.5, calculator.divide(1.0, 2.0), 0.001);
    }
    
    @Test(expected = IllegalArgumentException.class)
    public void testDivideByZero() {
        calculator.divide(5.0, 0.0);
    }
    
    @Test(expected = IllegalArgumentException.class)
    public void testDivideByZeroWithNegative() {
        calculator.divide(-5.0, 0.0);
    }
}