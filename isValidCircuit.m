function isValid = isValidCircuit(circuit)
% Recursively search the circuit components until it finds a R,C, or L
% in series or parallel directly with a diffusion element W,T,O, or G
% and return false if it does find it or true if it doesn't
isValid = true;
if strcmp(circuit.type, 'element')
    % if circuit struct is a element type return true
    if ~isempty(circuit.value)
        return
    else
        isValid = false;
        return
    end
end
if isfield(circuit, 'components')
    comps = circuit.components;
    % The actual rule check(s)
    % Rule 1: Exclude R in series with C directly connected
    isValid = RC_Rule(circuit);
    if ~isValid
        return;
    end
    % Rule 2: Exclude R in parallel with L directly connected
    isValid = RL_Rule(circuit);
    if ~isValid
        return;
    end

    % Rule 3: Check if a R,C, or L in series or parallel directly with a 
    % diffusion element W,T,O, or G
    isValid = Diff_Rule(circuit);
    if ~isValid
        return;
    end

    % Rule 4: Limit diffusion elements W, O, T, G to 4
    isValid = Diff_Limit_Rule(circuit,4);
    if ~isValid
        return;
    end

    % Rule 5: Limit inductors L to 2
    isValid = L_Limit_Rule(circuit,2);
    if ~isValid
        return;
    end

    % Rule 6: Limit capacitors C to 4
    isValid = C_Limit_Rule(circuit,4);
    if ~isValid
        return;
    end

    % More Rules

    % Recursive search
    for i = 1:length(comps)
        subcomponent = circuit.components{i};
        isValid = isValidCircuit(subcomponent);
        if ~isValid
            return
        end
    end
end
end

%%% Rules and helper functions

function result = isElement(circuit, elementType)
    % Check if the circuit is a specific element type
    result = strcmp(circuit.type, 'element') && any(strcmp(circuit.value, elementType));
end

function isValid = Diff_Rule(circuit)
% Rule 6: see if there is a R,C, or L in direct series or parallel with a
% diffusion element
isValid=true;
if isfield(circuit, 'components')
    comps = circuit.components;
    types = string(cellfun(@(comp) getElementType(comp), comps, 'UniformOutput', false));
    if (any(ismember(types, {'R', 'C', 'L'})) && any(ismember(types, {'W', 'O', 'T', 'G'})))
        isValid = false;
        return;
    end
end
end

function isValid = RC_Rule(circuit)
% Rule 1: Exclude R in series with C directly connected
isValid = true;
if strcmp(circuit.type, 'series')
    comps = circuit.components;
    if length(comps) == 2
        if (isElement(comps{1}, 'R') && isElement(comps{2}, 'C')) || ...
                (isElement(comps{1}, 'C') && isElement(comps{2}, 'R'))
            isValid = false;
            return;
        end
    end
end
end

function isValid = RL_Rule(circuit)
% Rule 2: Exclude R in parallel with L directly connected
isValid = true;
if strcmp(circuit.type, 'parallel')
    comps = circuit.components;
    if length(comps) == 2
        if (isElement(comps{1}, 'R') && isElement(comps{2}, 'L')) || ...
                (isElement(comps{1}, 'L') && isElement(comps{2}, 'R'))
            isValid = false;
            return;
        end
    end
end
end

function isValid = Diff_Limit_Rule(circuit,n)
% Rule 3: Limit diffusion elements W, O, T, G to 4
isValid = true;
diffusionElements = {'W', 'O', 'T', 'G'};
numDiffusion = countElementType(circuit, diffusionElements);
if numDiffusion > n
    isValid = false;
    return;
end
end

function isValid = L_Limit_Rule(circuit,n)
% Rule 4: Limit inductors L to 2
isValid = true;
numL = countElementType(circuit, {'L'});
if numL > n
    isValid = false;
    return;
end
end

function isValid = C_Limit_Rule(circuit,n)
% Rule 5: Limit capacitors C to n
isValid=true;
numC = countElementType(circuit, {'C'});
if numC > n
    isValid = false;
    return;
end
end