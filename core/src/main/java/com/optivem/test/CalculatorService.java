package com.optivem.test;

/**
 * A simple calculator that performs basic arithmetic operations.
 */
public class CalculatorService {
    
    /**
     * Adds two numbers.
     * @param a first number
     * @param b second number
     * @return sum of a and b
     */
    public double add(double a, double b) {
        return a + b;
    }
    
    /**
     * Subtracts second number from first number.
     * @param a first number
     * @param b second number
     * @return difference of a and b
     */
    public double subtract(double a, double b) {
        return a - b;
    }
    
    /**
     * Multiplies two numbers.
     * @param a first number
     * @param b second number
     * @return product of a and b
     */
    public double multiply(double a, double b) {
        return a * b;
    }
    
    /**
     * Divides first number by second number.
     * @param a dividend
     * @param b divisor
     * @return quotient of a and b
     * @throws IllegalArgumentException if divisor is zero
     */
    public double divide(double a, double b) {
        if (b == 0) {
            throw new IllegalArgumentException("Cannot divide by zero");
        }
        return a / b;
    }
}