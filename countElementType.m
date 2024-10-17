function total = countElementType(circuit, elementTypes)
    % Count the number of elements in the circuit that match the given element types
    if strcmp(circuit.type, 'element')
        if any(strcmp(circuit.value, elementTypes))
            count = 1;
        else
            count = 0;
        end
    else
        % Recurse on components
        count = 0;
        for i = 1:length(circuit.components)
            count = count + countElementType(circuit.components{i}, elementTypes);
        end
    end
    % circuitstr=getCanonicalForm(circuit);
    % total = 0;
    % for i=1:length(elementTypes)
    %     total = total + count(circuitstr,elementTypes(i));
    % end
end