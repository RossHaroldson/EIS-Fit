function num = getNumElements(circuit)
    % Get the number of elements in the circuit
    if strcmp(circuit.type, 'element')
        num = 1;
    else
        num = 0;
        for i = 1:length(circuit.components)
            num = num + getNumElements(circuit.components{i});
        end
    end
end