package com.optivem.test.systemtest.smoketest.rc;

import com.optivem.test.CalculatorService;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class SmokeTest {

    @Test
    public void shouldLoadLibrary() {
        var calculatorClass = CalculatorService.class;
        assertNotNull(calculatorClass);
    }
}