function [canonicalCircuit, good] = processCircuit(circuit, numElements, CircStr, elementTypes, numElementTypes, modes)
    good = false;
    % Flatten components
    flatCircuit = flattenCircuit(circuit, modes);
    % Reduce elements
    
    % Canonize
    canonicalCircuit = getCanonicalForm(flatCircuit, elementTypes, numElementTypes, modes);
    % Check numElements
    if numElements == findNumElements(canonicalCircuit, elementTypes)
        % Check uniqueness
        if ~ismember(canonicalCircuit, CircStr)
            % Validate
            if isValidCircuit(canonicalCircuit, elementTypes)
                good = true;
            end
        end
    end
end
