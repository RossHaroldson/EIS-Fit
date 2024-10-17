function isValid = isValidCircuitString(circuitStr)
    % Parse the circuit string into a structure
    circuit = parseCircuitString(circuitStr);
    % Check if the circuit is valid based on custom rules
    isValid = isValidCircuit(circuit);
end