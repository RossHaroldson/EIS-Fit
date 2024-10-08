% Equivilent Circuit Generator
% This script is for generating all possible configurations of circuits
% given a max number of elements and element types and taking into account
% rules for valid circuit configuration. Circuit configurations are build 
% recursively to minimize the number of invalid configurations. 

% test

%% Clear everything to start from scratch
clear all
clc
%% Test commands
for i=1:6
    DiffCircStr{i}=CircStrOld{i}(~ismember(CircStrOld{i},CircStrNew{i}));
end
%% Configuration

% Initialize parameters
maxElements = 6;
loadsave = false;
elementtypes = {'R','C','W','T','L'}';

% Get save and load location for data
savefolder = uigetdir('C:\', 'Specify folder to save and read generated circuit configurations (Could be very large)');
if ischar(savefolder)
    savefilepath = {savefolder '\' 'circuit_data.mat'};
    savedata = true;
else
    savefilepath = {savefolder '\' 'circuit_data.mat'};
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
        % Generate combinations of circuits that sum up to numElements
        for sizeA = 1:numElements-1
            sizeB = numElements - sizeA;
            % Generate all combinations
            for idxA = 1:length(CircStr{sizeA})
                for idxB = 1:length(CircStr{sizeB})
                    % Combine in series and parallel
                    modes = {'s', 'p'};
                    for m = 1:length(modes)
                        newCircuit = [modes{m}, '(', CircStr{sizeA}{idxA}, ',', CircStr{sizeB}{idxB}, ')'];
                        % Simplify and validate the new circuit
                        simplifiedCircuit = simplifyCircuitString(newCircuit);
                        if isValidCircuitString(simplifiedCircuit)
                            % Avoid duplicates
                            if ~ismember(simplifiedCircuit, newCircuits) && getNumElements(parseCircuitString(simplifiedCircuit)) == numElements
                                newCircuits{end+1} = simplifiedCircuit;
                            end
                        end
                    end
                end
            end
        end
        % Store unique circuits of current size
        CircStr{numElements} = unique(newCircuits)';
        newCircuits={};
    end
    % Optionally save progress
    if savedata
        disp('Saving data');
        save(savefilepath, 'CircStr', '-v7.3');
    end
    toc
    disp(length(CircStr{end}))
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

function isValid = isValidCircuit(circuit)
    % Check if the circuit is valid based on custom rules
    isValid = true;

    % Rule 1: Exclude R in series with C directly connected
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

    % Rule 2: Exclude R in parallel with L directly connected
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

    % Rule 3: Limit diffusion elements W, O, T, G to 4
    diffusionElements = {'W', 'O', 'T', 'G'};
    numDiffusion = countElementType(circuit, diffusionElements);
    if numDiffusion > 4
        isValid = false;
        return;
    end

    % Rule 4: Limit inductors L to 2
    numL = countElementType(circuit, {'L'});
    if numL > 2
        isValid = false;
        return;
    end

    % Rule 5: Limit capacitors C to 4
    numC = countElementType(circuit, {'C'});
    if numC > 4
        isValid = false;
        return;
    end

    % Rule 6: Exclude diffusion elements in direct parallel or series with
    % R, C, L element types
    if strcmp(circuit.type, 'series') || strcmp(circuit.type, 'parallel')
        comps = circuit.components;
        if length(comps) == 2
            types = cellfun(@(comp) getElementType(comp), comps, 'UniformOutput', false);
            if (any(ismember(types, {'R', 'C', 'L'})) && any(ismember(types, {'W', 'O', 'T', 'G'})))
                isValid = false;
                return;
            end
        end
    end

    % Rule 7: All circuits must have a single resistor in series with the
    % rest of the circuit if the circuit has more than 1 element. 
    % (Geared more toward EIS data)
    % Doesn't work how i want it because of how it builds circuits
    % if getNumElements(circuit) >  
    % if strcmp(circuit.type, 'series')
    %     comps = circuit.components;
    %     types = cellfun(@(comp) getElementType(comp), comps, 'UniformOutput', false);
    %     if any(ismember(types, {'R'}))
    %         isValid = true;
    %     else
    %         isValid = false;
    %         return;
    %     end
    % elseif strcmp(circuit.type, 'parallel')
    %     isValid = false;
    %     return;
    % end
    % end
end

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
