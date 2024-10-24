function canonicalCircuit = getCanonicalForm(circuit, elementTypes, numElementTypes, modes)
    % Get a canonical string representation of the circuit
    canonicalCircuit = circuit;
    numComps = findNumComponents(circuit, modes);

    % Base case: if there are no parentheses, return the circuit as is
    if numComps == 0
        return;
    end

    % Initialize storage for elements and components
    elem = {};
    comps = {};

    % Extract mode ('s' or 'p') from the circuit
    mode = circuit(1);

    % Extract the content inside the outermost parentheses
    content = circuit(3:end-1);

    % Split the content by commas, considering the parentheses
    parts = splitByCommaConsideringParentheses(content);

    % Process each part
    for i = 1:length(parts)
        part = strtrim(parts{i});
        if isElement(part, elementTypes)
            % If it's an element, add it to the element list
            elem{end+1} = part;
        else
            % If it's a component (starts with 's' or 'p'), process it recursively
            compCanonical = getCanonicalForm(part, elementTypes, numElementTypes, modes);
            comps{end+1} = compCanonical;
        end
    end

    % Sort elements and components separately
    elem = sort(elem);
    comps = sort(comps);

    % Combine elements and components back into a string
    canonicalContent = strjoin([elem, comps], ',');

    % Construct the canonical circuit string
    canonicalCircuit = [mode '(' canonicalContent ')'];
end
