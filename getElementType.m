function elemType = getElementType(circuit)
    % Get the element type of a circuit component
    if strcmp(circuit.type, 'element')
        elemType = circuit.value;
    else
        elemType = '';
    end
end