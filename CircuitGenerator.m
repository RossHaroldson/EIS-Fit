% Equivalent Circuit Generator
% This script is for generating all possible configurations of circuits
% given a max number of elements and element types, taking into account
% rules for valid circuit configurations. Circuit configurations are built 
% recursively to minimize the number of invalid configurations.

%% Clear everything to start from scratch
clear all
clc
%% Tests
%strcir='s(R,L,p(p(s(R,p(R,C)),C),s(R,p(O,O),p(O,O))))'
%strcir='s(R,L,p(p(s(R,p(R,C)),C),s(p(R,O,O),p(O,O))))'
strcir='p(T,s(R,T))'
%strcir='s(R,O,L)'
cir=parseCircuitString(strcir);
concir=getCanonicalForm(cir)
cir=parseCircuitString(concir);
isValidCircuit(cir)
%% Tests
for i=1:length(CircStrOld)
    DiffCircStr{i}=CircStrNew{i}(~ismember(CircStrNew{i},CircStrOld{i}));
end
%% Configuration

% Initialize parameters
maxElements = 5;
loadsave = false;
elementtypes = {'R','C','W','T','L'}';

% Get save and load location for data
savefolder = uigetdir('C:\', 'Specify folder to save and read generated circuit configurations (Could be very large)');
if ischar(savefolder)
    savefilepath = fullfile(savefolder, 'circuit_data.mat');
    savedata = true;
else
    savefilepath = '';
    savedata = false;
end

% Initialize circuit storage
CircStr = cell(maxElements, 1);
circuitCount = 0; % Total number of circuits

%% Build circuits of size 1 to n
tic
for numElements = 1:maxElements
    fprintf('Processing circuits with %d elements\n', numElements);
    if numElements == 1
        % Base case: circuits with a single element
        CircStr{1} = elementtypes;
    else
        % Initialize storage for circuits of current size
        newCircuits = {};
        % Generate circuits by adding one element to existing circuits
        for idx = 1:length(CircStr{numElements-1})
            circuitStr = CircStr{numElements-1}{idx};
            circuit = parseCircuitString(circuitStr);
            for e = 1:length(elementtypes)
                element = elementtypes{e};
                % Insert element into the circuit
                newCircuitStructs = insertElement(circuit, element);
                for c = 1:length(newCircuitStructs)
                    newCircuit = newCircuitStructs{c};
                    %simplifiedCircuit = simplifyCircuit(newCircuit);
                    totalElements = getNumElements(newCircuit);
                    if totalElements == numElements
                        % Simplify and validate
                        canonicalStr = getCanonicalForm(newCircuit);
                        %if isValidCircuit(simplifiedCircuit)
                            if ~ismember(canonicalStr, newCircuits)
                                newCircuits{end+1} = canonicalStr;
                            else
                                %disp('this check is useful?')
                            end
                        %else
                        %    disp(['Bad circuit got through: ' getCanonicalForm(simplifiedCircuit)])
                        %end
                    end
                end
            end
        end
        % Store unique circuits of current size
        CircStr{numElements} = unique(newCircuits)';
    end
    % Optionally save progress
    if savedata
        disp('Saving data');
        save(savefilepath, 'CircStr', '-v7.3');
    end
    toc
    disp(length(CircStr{numElements}))
end
disp('Finished');
%% Display results
disp('Unique and Simplified Circuit Configurations:');
for k = 1:maxElements
    fprintf('\nCircuits with %d element(s):\n', k);
    circuits = CircStr{k};
    % Sort and display
    sortedCircuits = sort(circuits);
    for i = 1:length(sortedCircuits)
        disp([' - ' sortedCircuits{i}]);
    end
end
clear circuits sortedCircuits
%% Helper Functions

function isValid = isValidCircuitString(circuitStr)
    % Parse the circuit string into a structure
    circuit = parseCircuitString(circuitStr);
    % Check if the circuit is valid based on custom rules
    isValid = isValidCircuit(circuit);
end

function simplifiedStr = simplifyCircuitString(circuitStr)
    % Parse the circuit string into a structure
    circuit = parseCircuitString(circuitStr);
    % Simplify the circuit
    simplifiedCircuit = simplifyCircuit(circuit);
    % Get the canonical form
    simplifiedStr = getCanonicalForm(simplifiedCircuit);
end

% function isValid = isValidCircuit(circuit)
%     % Check if the circuit is valid based on custom rules
%     isValid = true;
% 
%     % Rule 1: Exclude R in series with C directly connected
%     % broken in new method
%     isValid = RC_Rule(circuit);
%     if ~isValid
%         return;
%     end
%     % Rule 2: Exclude R in parallel with L directly connected
%     % broken in new method
%     isValid = RL_Rule(circuit);
%     if ~isValid
%         return;
%     end
% 
%     % Rule 3: Limit diffusion elements W, O, T, G to 4
%     isValid = Diff_Limit_Rule(circuit,4);
%     if ~isValid
%         return;
%     end
% 
%     % Rule 4: Limit inductors L to 2
%     isValid = L_Limit_Rule(circuit,2);
%     if ~isValid
%         return;
%     end
% 
%     % Rule 5: Limit capacitors C to 4
%     isValid = C_Limit_Rule(circuit,4);
%     if ~isValid
%         return;
%     end
% 
%     % Rule 6: Exclude diffusion elements in direct parallel or series with
%     % R, C, L element types
%     isValid = Recursive_Rule_Check(circuit);
%     if ~isValid
%         return;
%     end
% 
%     % Rule 7: All circuits must have a single resistor in series with the
%     % rest of the circuit if the circuit has more than 1 element. 
%     % (Implement this rule if needed)
% end

function count = countElementType(circuit, elementTypes)
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
end

function result = isElement(circuit, elementType)
    % Check if the circuit is a specific element type
    result = strcmp(circuit.type, 'element') && any(strcmp(circuit.value, elementType));
end

function simplifiedCircuit = simplifyCircuit(circuit)
    % Simplify the circuit based on predefined rules

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
    uniqueComps = {};
    seenReprs = {};

    for i = 1:length(components)
        comp = components{i};
        repr = getCanonicalForm(comp);

        % Determine if the component is an element of types to reduce
        if strcmp(comp.type, 'element') && ismember(comp.value, elementTypesToReduce)
            % Only remove duplicates for specified element types
            if ~ismember(repr, seenReprs)
                uniqueComps{end+1} = comp;
                seenReprs{end+1} = repr;
            end
        else
            % For other elements or circuits, include all
            uniqueComps{end+1} = comp;
        end
    end
end

function repr = getCanonicalForm(circuit)
    % Get a canonical string representation of the circuit
    if strcmp(circuit.type, 'element')
        repr = circuit.value;
    else
        compReprs = cellfun(@getCanonicalForm, circuit.components, 'UniformOutput', false);
        % Sort the representations to account for commutativity
        compReprs = sort(compReprs);
        if strcmp(circuit.type, 'series')
            operatorstr = 's';
        elseif strcmp(circuit.type, 'parallel')
            operatorstr = 'p';
        end
        repr = [operatorstr, '(', strjoin(compReprs, ','), ')'];
    end
end

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

function circuit = parseCircuitString(circuitStr)
    % Remove spaces
    circuitStr = strrep(circuitStr, ' ', '');
    [circuit, ~] = parseCircuit(circuitStr);
end

function [circuit, idx] = parseCircuit(str, idx)
    if nargin < 2
        idx = 1;
    end
    if idx > length(str)
        circuit = [];
        return;
    end
    if str(idx) == 's' || str(idx) == 'p'
        circuit.type = connectionType(str(idx));
        idx = idx + 1; % Move past 's' or 'p'
        assert(str(idx) == '(', 'Expected ( after %s', str(idx-1));
        idx = idx + 1; % Move past '('
        components = {};
        while idx <= length(str) && str(idx) ~= ')'
            [comp, idx] = parseCircuit(str, idx);
            components{end+1} = comp;
            if idx <= length(str) && str(idx) == ','
                idx = idx + 1; % Move past ','
            end
        end
        assert(str(idx) == ')', 'Expected ) at position %d', idx);
        idx = idx + 1; % Move past ')'
        circuit.components = components;
    else
        % Parse element
        elemType = '';
        while idx <= length(str) && isLetter(str(idx))
            elemType = [elemType, str(idx)];
            idx = idx + 1;
        end
        circuit.type = 'element';
        circuit.value = elemType;
    end
end

function isLetter = isLetter(c)
    isLetter = ismember(c, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz');
end

function connType = connectionType(c)
    if c == 's'
        connType = 'series';
    elseif c == 'p'
        connType = 'parallel';
    else
        error('Unknown connection type: %s', c);
    end
end

function elemType = getElementType(circuit)
    % Get the element type of a circuit component
    if strcmp(circuit.type, 'element')
        elemType = circuit.value;
    else
        elemType = '';
    end
end

function newCircuits = insertElement(circuit, element)
    newCircuits = {};
    elementNode = struct('type', 'element', 'value', element);
    modes = {'series', 'parallel'};
    % Combine element with entire circuit
    for m = 1:length(modes)
        mode = modes{m};
        newCircuit = struct('type', mode, 'components', {{elementNode, circuit}});
        newCircuit = simplifyCircuit(newCircuit);
        % apply rules 1 and 2 here when it adds them.
        %if RC_Rule(newCircuit) && RL_Rule(newCircuit) && Diff_Rule(newCircuit)
        if isValidCircuit(newCircuit)
            newCircuits{end+1} = newCircuit;
        else
            %disp(['Bad circuit found in outer: ' getCanonicalForm(newCircuit)])
        end
    end
    % Recurse into components
    if isfield(circuit, 'components')
        for i = 1:length(circuit.components)
            subcomponent = circuit.components{i};
            % Recurse into subcomponent
            subNewCircuits = insertElement(subcomponent, element);
            for j = 1:length(subNewCircuits)
                newSubcomponent = subNewCircuits{j};
                % Create new circuit by replacing subcomponent
                newCircuit = circuit;
                newCircuit.components{i} = newSubcomponent;
                newCircuit = simplifyCircuit(newCircuit);
                if isValidCircuit(newCircuit)
                    newCircuits{end+1} = newCircuit;
                else
                    %disp(['Bad circuit found in inner: ' getCanonicalForm(newCircuit)])
                end
            end
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

function isValid = isValidCircuit(circuit)
% Recursively search the circuit components until it finds a R,C, or L
% in series or parallel directly with a diffusion element W,T,O, or G
% and return false if it does find it or true if it doesn't
isValid = true;
if strcmp(circuit.type, 'element')
    % if circuit struct is a element type return true
    return
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

function isValid = Diff_Rule(circuit)
% Rule 6: see if there is a R,C, or L in direct series or parallel with a
% diffusion element
isValid=true;
if isfield(circuit, 'components')
    comps = circuit.components;
    types = cellfun(@(comp) getElementType(comp), comps, 'UniformOutput', false);
    if (any(ismember(types, {'R', 'C', 'L'})) && any(ismember(types, {'W', 'O', 'T', 'G'})))
        isValid = false;
        return;
    end
end
end