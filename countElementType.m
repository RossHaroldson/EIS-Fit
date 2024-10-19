function total = countElementType(circuit, elementTypes)
    % Count the number of elements in the circuit that match the given element types
    if strcmp(circuit.type, 'element')
        % Directly count if it's an element and matches one of the types
        total = ismember(circuit.value, elementTypes);  % No conversion needed
    else
        % Initialize total count to 0
        total = 0;
        % Loop over components manually, avoiding cellfun overhead
        for i = 1:length(circuit.components)
            total = total + countElementType(circuit.components{i}, elementTypes);
        end
    end
    % Method below calls getCanonicalForm and then that is the bottle neck.
    % total=0;
    % cirstr=getCanonicalForm(circuit);
    % for i = 1:length(elementTypes)
    %     total = total + sum(ismember(cirstr,elementTypes{i}));
    % end
end

