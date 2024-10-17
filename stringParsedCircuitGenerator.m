% Equivalent Circuit Generator
% This script is for generating all possible configurations of circuits
% given a max number of elements and element types, taking into account
% rules for valid circuit configurations. Circuit configurations are built 
% recursively to minimize the number of invalid configurations.

%% Clear everything to start from scratch
clear

%{
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
%}

%% Configuration

% Initialize parameters
maxElements = 5;

loadsave = false;
elementTypes = {'R','C','W','T','L'};
numElementTypes = length(elementTypes);
modes = {'s','p'};
numModes = length(modes);

% Get save and load location for data
% savefolder = uigetdir('C:\', 'Specify folder to save and read generated circuit configurations (Could be very large)');
savefolder = [];
if ischar(savefolder)
    savefilepath = fullfile(savefolder, 'stringParsedCircuits.mat');
    savedata = true;
else
    savefilepath = '';
    savedata = false;
end

% Initialize circuit storage
CircStr = cell(maxElements, 1);
circuitCount = 0; % Total number of circuits

%% Build circuits of size 1 to n
for numElements = 1:maxElements
    fprintf('\nProcessing circuits with %d elements...\n', numElements);
    tic
    if numElements == 1
        % Base case: circuits with a single element
        CircStr{1} = elementTypes;
    else
        % Initialize storage for circuits of current size
        CircStr{numElements} = {};
        newCircuits = {};
        % Generate circuits by adding one element to existing circuits
        numCircuits = length(CircStr{numElements-1});
        for c = 1:numCircuits
            for e = 1:numElementTypes
                % Combine element e with circuit c
                for m = 1:numModes
                    newCircuit = append(modes{m}, '(', elementTypes{e}, ',', CircStr{numElements-1}{c}, ')');
                    [canonicalCircuit, good] = processCircuit(newCircuit, CircStr{numElements}, elementTypes, numElementTypes);
                    if good
                        CircStr{numElements}{end+1} = canonicalCircuit;
                    end
                end
                % Insert element e into components of c
                [oc, numComps] = findParentheses(CircStr{numElements-1}{c});
                for idx = 1:numComps
                    newCircuit = insertAfter(CircStr{numElements-1}{c}, oc(idx,1), elementTypes{e} + ',');
                    [canonicalCircuit, good] = processCircuit(newCircuit, CircStr{numElements}, elementTypes, numElementTypes);
                    if good
                        CircStr{numElements}{end+1} = canonicalCircuit;
                    end
                end
                % Combine e directly with other elements el of c
                [elem, numElem] = findElements(CircStr{numElements-1}{c}, elementTypes);
                for el = 1:numElementTypes
                    for idx = 1:numElem(el)
                        for m = 1:numModes
                            % Insert chars
                            str = append(modes{m}, '(', elementTypes{e}, ',');
                            bigstr = insertAfter(CircStr{numElements-1}{c}, elem{el}(idx), ')');
                            newCircuit = insertAfter(bigstr, elem{el}(idx)-1, str);
                            newcircuit = newCircuit;
                            % Process circuit
                            [canonicalCircuit, good] = processCircuit(newCircuit, CircStr{numElements}, elementTypes, numElementTypes);
                            if good
                                % Save good circuit
                                CircStr{numElements}{end+1} = canonicalCircuit;
                            end
                        end
                    end
                end
            end
        end
    end
    toc
    numNewCircuits = length(CircStr{numElements});
    fprintf('\n%d circuits found\n', numNewCircuits);

    CircStr{numElements} = sort(CircStr{numElements});
    % Optionally save progress
    if savedata
        disp('Saving data...');
        tic
        save(savefilepath, 'CircStr', '-v7.3');
        toc
    end
end
disp('Finished');

%% Display results
%{
disp('Unique and Simplified Circuit Configurations:');
for k = 1:maxElements
    fprintf('\nCircuits with %d element(s):\n', k);
    circuits = CircStr{k};
    % Sort and display
    % sortedCircuits = sort(circuits);
    for i = 1:length(circuits)
        disp([' - ' circuits{i}]);
    end
end
clear circuits sortedCircuits
%}

%% Helper Functions

function [oc, numPairs] = findParentheses(str)
    % column 1 = index of '(' in str
    % column 2 = index of ')' in str
    % rows are pairs of '(' and ')' indices
    oc = [];
    % find '(' and ')' in the string
    op=strfind(str,'(');
    cl=strfind(str,')');
    % search for pairs until all are identified
    while ~isempty(op) || ~isempty(cl)
        % find '(' for first ')'
        idx = find(op < cl(1), 1, 'last');
        % append this pair to function output
        oc = [oc; op(idx) cl(1)];
        % remove paired '(' from vector
        op(idx) = [];
        % remove paired ')' from vector
        cl(1) = [];
    end
    % sort pairs by index of '('
    oc = sortrows(oc);
    numPairs = size(oc,1);
end

function [idx, numElem] = findElements(str,elem)
    idx = {};
    numElemTypes = length(elem);
    numElem = zeros(size(elem));
    % get indices of each elem in str
    for e = 1:numElemTypes
        loc = strfind(str,elem(e));
        idx{end+1} = loc; 
        numElem(e) = length(loc);
    end
end

function [canonicalCircuit, good] = processCircuit(circuit, CircStr, elementTypes, numElementTypes)
    good = false;
    % Flatten elements and components
    flatCircuit = flattenCircuit(circuit);
    % Canonize
    canonicalCircuit = getCanonicalForm(flatCircuit, elementTypes, numElementTypes);
    % Check uniqueness
    if ~ismember(canonicalCircuit, CircStr)
        % Validate
        if isValidCircuit(canonicalCircuit)
            good = true;
        end
    end
end

function flatCircuit = flattenCircuit(circuit)
    % Recursively flatten nested components of the same mode, from inside out
    flatCircuit = circuit;
    % Look for components
    [oc,numComps] = findParentheses(circuit);
    while numComps > 1
        flagStringChange = false;
        % Step through components
        for idx = 1:numComps
            outerMode = flatCircuit(1);
            % Extract component
            comp = flatCircuit(oc(idx,1)-1:oc(idx,2));
            % Recursively flatten component
            flatComp = flattenCircuit(comp);
            innerMode = flatComp(1);
            % Check if connection matches
            if innerMode == outerMode
                subComps = flatComp(3:end-1);
                % replace component with its subcomponents
                leftStr = flatCircuit(1:oc(idx,1)-2);
                rightStr = flatCircuit(oc(idx,2)+1:end);
                flatCircuit = append(leftStr, subComps, rightStr);
                % Update indices and flag the change
                [oc,numComps] = findParentheses(flatCircuit);
                flagStringChange = true;
            end
            % if the string changed, break out of the 'for' statement
            if flagStringChange
                break;
            end
        end
    end
end

function canonicalCircuit = getCanonicalForm(circuit, elementTypes, numElementTypes)
    % Get a canonical string representation of the circuit
    canonicalCircuit = circuit;
    [oc,numComps] = findParentheses(circuit);

    % for nested components
    if numComps > 1
        elem = {};
        % start at first '(', stop at next '('
        startIdx = 1;
        stopIdx = startIdx + 1;
        % extract elements and modes between components and outer parentheses
        block = extractBetween(circuit, oc(startIdx,1)+1, oc(stopIdx,1)-1);
        while stopIdx ~= 1
            for e = 1:numElementTypes
                currentElem = extract(circuit, elementTypes{e});
                if ~isempty(currentElem)
                    elem{end+1} = currentElem{1};
                end
            end
            % step to next block of elements
            startIdx = stopIdx;
            % if reached final block
            if oc(startIdx,2) == max(oc(2:end),2)
                stopIdx = 1;
                block = extractBetween(circuit, oc(startIdx,2)+1, oc(stopIdx,2)-1);
            else
                stopIdx = startIdx + 1;
                block = extractBetween(circuit, oc(startIdx,2)+1, oc(stopIdx,1)-1);
            end
        end
        % extract final block of elements
        block = extractBetween(circuit, oc(startIdx,2)+1, oc(stopIdx,2)-1);
        for e = 1:numElementTypes
            currentElem = extract(circuit, elementTypes{e});
            if ~isempty(currentElem)
                elem{end+1} = currentElem{1};
            end
        end
        elemCanon = join(sort(elem),',');

        % apply recursively to components
        comps = {};
        for c = 1:numComps
            % get component
            comp = circuit(oc(c,1)-1:oc(c,2));
            % canonize component
            comps{end+1} = getCanonicalForm(comp);
        end
        compsCanon = join(sort(comps),',');

        % update repr
        canonicalCircuit = replaceBetween(circuit, 3, length(circuit)-1, append(elemCanon, ',', compsCanon));
        
    % if circuit has only elements
    elseif numComps == 1
        elem = {};
        % extract elements
        for e = 1:numElementTypes
            currentElem = extract(circuit, elementTypes{e});
            if ~isempty(currentElem)
                elem{end+1} = currentElem{1};
            end
        end
        elemCanon = join(sort(elem),',');
        % update repr
        canonicalCircuit = replaceBetween(circuit, 3, length(circuit)-1, elemCanon);
    end
end

function isValid = RC_Rule(circuit)
    % Rule 1: Exclude R in series with C directly connected
    isValid = true;
    % find series components
    [oc, numComps] = findParentheses(circuit);
    for idx = 1:numComps
        if circuit(oc(idx,1)-1) == 's'
            % isolate the series component
            component = circuit(oc(idx,1)-1:oc(idx,2));
            % check for subcomponents
            if ~any(ismember(['s','p'], component(2:end)))
                % if no subcomponents, check for other element types
                if ~any(ismember(['L','W','T','O','G'], component))
                    % if none, series component must only contain R and C
                    isValid = false;
                    return;
                end
            end
        end
    end
end

function isValid = RL_Rule(circuit)
    % Rule 2: Exclude R in parallel with L directly connected
    isValid = true;
    % find parallel components
    [oc, numComps] = findParentheses(circuit);
    for idx = 1:numComps
        if circuit(oc(idx,1)-1) == 'p'
            % isolate the parallel component
            component = circuit(oc(idx,1)-1:oc(idx,2));
            % check for subcomponents
            if ~any(ismember(['s','p'], component(2:end)))
                % if no subcomponents, check for other element types
                if ~any(ismember(['C','W','T','O','G'], component))
                    % if none, parallel component must only contain R and L
                    isValid = false;
                    return;
                end
            end
        end
    end
end
        
function isValid = Diff_Rule(circuit)
    % Rule 3: see if there is a R,C, or L in direct series or parallel with a
    % diffusion element
    isValid = true;
    % find components
    [oc, numComps] = findParentheses(circuit);
    for idx = 1:numComps
        % isolate the component
        component = circuit(oc(idx,1)-1:oc(idx,2));
        % check for subcomponents
        if ~any(ismember(['s','p'], component(2:end)))
            % if no subcomponents, count element types
            [~,numDiffTypes] = findElements(component,{'W','T','O','G'});
            [~,numStandardTypes] = findElements(component,{'R','L','C'});
            % check for single R, L, or C in component with single
            % diffusion element
            totNumDiff = sum(numDiffTypes);
            totNumStandard = sum(numStandardTypes);
            if totNumDiff == 1 && totNumStandard == 1
                isValid = false;
                return;
            end
        end
    end
end

function isValid = Diff_Limit_Rule(circuit)
    % Rule 4: Limit diffusion elements W, O, T, G to n
    isValid = true;
    numDiff = 4;
    [~,nums] = findElements(circuit, {'W','T','O','G'});
    n = sum(nums);
    if n > numDiff
        isValid = false;
        return;
    end
end

function isValid = L_Limit_Rule(circuit)
    % Rule 5: Limit inductors L to n
    isValid = true;
    numL = 2;
    [~,n] = findElements(circuit, {'L'});
    if n > numL
        isValid = false;
        return;
    end
end

function isValid = C_Limit_Rule(circuit)
    % Rule 6: Limit capacitors C to n
    isValid=true;
    numC = 4;
    [~,n] = findElements(circuit, {'C'});
    if n > numC
        isValid = false;
        return;
    end
end


% Rule 7: replaces uniqueComponents -- should be called first in validation.
% Check for RR, CC, LL, and WW components. 
% Since duplicates are reduced, numElements is violated. 
% So instead of reducing, just find and confirm invalidity.
function isValid = reductionRule(circuit)
    % Rule 7: see if there is a R,C,L, or W in direct series or parallel
    % with a like element
    isValid = true;
    % find elements of reducible type
    [Redidx, numRed] = findElements(circuit, {'R','L','C','W'});
    numRedTypes = length(numRed);
    for e = 1:numRedTypes
        for i = 1:numRed(e)-1
            % Assuming a flattened, canonically ordered circuit:
            % If sorted elements of the same type are two indices
            % away, then they are directly connected and reducible.
            if Redidx{e}(i) + 2 == Redidx{e}(i+1)
                isValid = false;
                return;
            end
        end
    end
end

function isValid = isValidCircuit(circuit)
% Recursively search the circuit components until it finds a R,C, or L
% in series or parallel directly with a diffusion element W,T,O, or G
% and return false if it does find it or true if it doesn't

    % Rule 7: should be called first -- other rules were written under the
    % assumption that components are irreducible.
    % Dump circuits with reducible elements, since numElements is
    % violated by reducing elements to canonical form.
    isValid = reductionRule(circuit);
    if ~isValid
        return;
    end

    % Rule 5: Limit inductors L to numL
    isValid = L_Limit_Rule(circuit);
    if ~isValid
        return;
    end

    % Rule 6: Limit capacitors C to numC
    isValid = C_Limit_Rule(circuit);
    if ~isValid
        return;
    end

    % Rule 4: Limit diffusion elements W, O, T, G to numDiff
    isValid = Diff_Limit_Rule(circuit);
    if ~isValid
        return;
    end

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
end
