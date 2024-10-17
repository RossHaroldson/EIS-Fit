function circuit = parseCircuitString(circuitStr)
    % Remove spaces
    circuitStr = strrep(circuitStr, ' ', '');
    [circuit, ~] = parseCircuit(circuitStr);
end