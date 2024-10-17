function simplifiedStr = simplifyCircuitString(circuitStr)
    % Parse the circuit string into a structure
    circuit = parseCircuitString(circuitStr);
    % Simplify the circuit
    simplifiedCircuit = simplifyCircuit(circuit);
    % Get the canonical form
    simplifiedStr = getCanonicalForm(simplifiedCircuit);
end