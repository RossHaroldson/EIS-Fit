function simplifiedCircuit = simplifyCircuit(circuit)
    % Simplify the circuit struct based on predefined rules
    % Returns the new simplified circuit struct

    % First, recursively simplify the components
    if isfield(circuit, 'components')
        for i = 1:length(circuit.components)
            circuit.components{i} = simplifyCircuit(circuit.components{i});
        end
    end

    simplifiedCircuit = circuit;

    % Simplify series or parallel configurations
    if (strcmp(circuit.type, 'series') || strcmp(circuit.type, 'parallel'))
        % Flatten components of the same type
        flatComps = flattenComponents(circuit, circuit.type);

        % Remove duplicates selectively
        uniqueComps = uniqueComponents(flatComps);

        % If only one component remains, return it
        if isscalar(uniqueComps)
            simplifiedCircuit = uniqueComps{1};
        else
            % Reconstruct the circuit
            simplifiedCircuit.type = circuit.type;
            simplifiedCircuit.components = uniqueComps;
        end
    end
end

 
function flatComps = flattenComponents(circuit, mode)
    % Recursively flatten components of the same type
    flatComps = {};
    for i = 1:length(circuit.components)
        comp = circuit.components{i};
        if strcmp(comp.type, mode)
            % Flatten further
            flatComps = [flatComps, flattenComponents(comp, mode)];
        else
            flatComps{end+1} = comp;
        end
    end
end


function uniqueComps = uniqueComponents(components)
    % Remove duplicate components based on their canonical forms,
    % but only for elements of types R, C, L, or W

    elementTypesToReduce = {'R', 'C', 'L', 'W'};
    uniqueComps = {};            % Cell array to store components
    seenReprs = strings(0, 1);   % Initialize as empty string array

    for i = 1:length(components)
        comp = components{i};
        repr = getCanonicalForm(comp);  % Assuming this returns a string

        % Determine if the component is an element of types to reduce
        if strcmp(comp.type, 'element') && ismember(comp.value, elementTypesToReduce)
            % Only remove duplicates for specified element types
            if ~ismember(repr, seenReprs)
                uniqueComps{end+1} = comp;
                seenReprs(end+1, 1) = repr;  % Append to string array
            end
        else
            % For other elements or circuits, include all
            uniqueComps{end+1} = comp;
        end
    end
end