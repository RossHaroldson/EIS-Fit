function localNewCircuits = createNewCircuits(elementtypes, localNewCircuits, circuit, numElements)
for e = 1:length(elementtypes)
    element = elementtypes(e);
    % Insert element into the circuit
    newCircuitStructs = insertElement(circuit, element);

    for c = 1:length(newCircuitStructs)
        newCircuit = newCircuitStructs{c};
        totalElements = getNumElements(newCircuit);

        if totalElements == numElements
            % Simplify and validate
            canonicalStr = getCanonicalForm(newCircuit);
            if ~ismember(canonicalStr, localNewCircuits)
                localNewCircuits(end+1,1) = canonicalStr;
            end
        end
    end
end
end