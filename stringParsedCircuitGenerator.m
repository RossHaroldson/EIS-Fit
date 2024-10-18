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
strcir='s(R,L,p(p(s(R,p(R,R,C)),C),s(R,p(T,T),p(T,T))))'
flattenCircuit(strcir)
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
                    [canonicalCircuit, good] = processCircuit(newCircuit, numElements, CircStr{numElements}, elementTypes, numElementTypes);
                    if good
                        CircStr{numElements}{end+1} = canonicalCircuit;
                    end
                end
                % Insert element e into components of c
                [oc, numComps] = findParentheses(CircStr{numElements-1}{c});
                for idx = 1:numComps
                    newCircuit = insertAfter(CircStr{numElements-1}{c}, oc(idx,1), [elementTypes{e}, ',']);
                    [canonicalCircuit, good] = processCircuit(newCircuit, numElements, CircStr{numElements}, elementTypes, numElementTypes);
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
                            [canonicalCircuit, good] = processCircuit(newCircuit, numElements, CircStr{numElements}, elementTypes, numElementTypes);
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
    op = strfind(str, '(');
    cl = strfind(str, ')');
    
    % search for pairs until all are identified
    while ~isempty(op) && ~isempty(cl)
        % find '(' for first ')'
        idx = find(op < cl(1), 1, 'last');
        % append this pair to function output
        oc = [oc; op(idx), cl(1)];
        % remove paired '(' and ')'
        op(idx) = [];
        cl(1) = [];
    end
    numPairs = size(oc, 1);
end

function totalElements = findNumElements(charArray,elementTypes)
    totalElements = 0;
    for i = 1:length(elementTypes)
        totalElements = totalElements + sum(charArray == elementTypes{i});
    end
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

function [canonicalCircuit, good] = processCircuit(circuit, numElements, CircStr, elementTypes, numElementTypes)
    good = false;
    % Flatten elements and components
    flatCircuit = flattenCircuit(circuit);
    % Canonize
    canonicalCircuit = getCanonicalForm(flatCircuit, elementTypes, numElementTypes);
    % Check uniqueness
    if numElements == findNumElements(canonicalCircuit,elementTypes)
        if ~ismember(canonicalCircuit, CircStr)
            % Validate
            if isValidCircuit(canonicalCircuit)
                good = true;
            end
        end
    end
end

function flatCircuit = flattenCircuit(circuit)
    % Base case: if no parentheses, return the circuit
    if ~contains(circuit, '(')
        flatCircuit = circuit;
        return;
    end
    
    % Find components (parentheses pairs)
    [oc, numComps] = findParentheses(circuit);
    if numComps == 0
        flatCircuit = circuit;
        return;
    end

    flatCircuit = circuit;
    
    % Process components from the innermost outward
    for idx = numComps:-1:1
        % Extract the component (including the mode 's' or 'p')
        compStart = oc(idx, 1) - 1;
        compEnd = oc(idx, 2);
        comp = flatCircuit(compStart:compEnd);
        innerMode = comp(1);  % 's' or 'p'
        
        % Recursively flatten the component
        innerContent = comp(3:end-1); % Extract content inside parentheses
        flatComp = flattenCircuit(innerContent);
        subComps = splitComponents(flatComp);  % Get individual sub-components
        
        % Check if we can reduce 's(...)' or 'p(...)' containing only R, L, C
        reducedComp = reduceSeriesParallel(innerMode, subComps);
        
        % **New Check for Single-Element Components**
        if isscalar(reducedComp)
            % Replace the entire component with the single element
            replacement = reducedComp(1);
        else
            % Recombine the reduced components into a string
            %reducedCompStr = append(reducedComp, ',');
            reducedCompStr = reducedComp;
            % Reconstruct the component
            replacement = append(innerMode, '(', reducedCompStr, ')');
        end
        
        % Replace the original component with the reduced version
        leftStr = flatCircuit(1:oc(idx, 1)-2);
        rightStr = flatCircuit(oc(idx, 2)+1:end);
        flatCircuit = append(leftStr, replacement, rightStr);
        
        % Recalculate parentheses positions since the string has changed
        [oc, numComps] = findParentheses(flatCircuit);
    end
end


function reducedComp = reduceSeriesParallel(mode, subComps)
    % Only apply reduction for R, C, L elements, not T
    elementsToReduce = {'R', 'C', 'L','W'};
    
    if all(ismember(subComps, elementsToReduce))
        if strcmp(mode, 's') || strcmp(mode, 'p')
            % Remove identical elements in series/parallel
            reducedComp = unique(subComps);
        else
            reducedComp = subComps;
        end
    else
        reducedComp = subComps;  % No reduction if 'T' is involved
    end
    
    % Recombine the reduced components into a string
    reducedComp = strjoin(reducedComp, ',');
end

function subComps = splitComponents(str)
    % Separate components within a string like 'R,L,C'
    subComps = strsplit(str, ',');
end

function canonicalCircuit = getCanonicalForm(circuit, elementTypes, numElementTypes)
    % Get a canonical string representation of the circuit
    canonicalCircuit = circuit;
    [oc, numComps] = findParentheses(circuit);

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
            compCanonical = getCanonicalForm(part, elementTypes, numElementTypes);
            comps{end+1} = compCanonical;
        end
    end

    % Sort elements and components separately
    elem = sort(elem);
    comps = sort(comps);

    % Combine elements and components back into a string
    combined = strjoin([elem, comps], ',');

    % Construct the canonical circuit string
    canonicalCircuit = [mode '(' combined ')'];
end

function result = isElement(part, elementTypes)
    % Check if the part is one of the element types
    result = any(strcmp(part, elementTypes));
end

function parts = splitByCommaConsideringParentheses(str)
    % Split the string by commas, but consider nested parentheses
    parts = {};
    bracketLevel = 0;
    lastSplit = 1;
    for i = 1:length(str)
        if str(i) == '('
            bracketLevel = bracketLevel + 1;
        elseif str(i) == ')'
            bracketLevel = bracketLevel - 1;
        elseif str(i) == ',' && bracketLevel == 0
            parts{end+1} = str(lastSplit:i-1);
            lastSplit = i + 1;
        end
    end
    % Add the last part
    parts{end+1} = str(lastSplit:end);
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
            % [~,numDiffTypes] = findElements(component,{'W','T','O','G'});
            numDiffTypes=findNumElements(component,{'W','T','O','G'});
            % [~,numStandardTypes] = findElements(component,{'R','L','C'});
            numStandardTypes=findNumElements(component,{'R','L','C'});
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
    % [~,nums] = findElements(circuit, {'W','T','O','G'});
    % n = sum(nums);
    n=findNumElements(circuit,{'W','T','O','G'});
    if n > numDiff
        isValid = false;
        return;
    end
end

function isValid = L_Limit_Rule(circuit)
    % Rule 5: Limit inductors L to n
    isValid = true;
    numL = 2;
    % [~,n] = findElements(circuit, {'L'});
    n=findNumElements(circuit,{'L'});
    if n > numL
        isValid = false;
        return;
    end
end

function isValid = C_Limit_Rule(circuit)
    % Rule 6: Limit capacitors C to n
    isValid=true;
    numC = 4;
    %[~,n] = findElements(circuit, {'C'});
    n=findNumElements(circuit,{'C'});
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
