% Equivalent Circuit Generator
% This script is for generating all possible configurations of circuits
% given a max number of elements and element types, taking into account
% rules for valid circuit configurations. Circuit configurations are built 
% recursively to minimize the number of invalid configurations.

%% Clear everything to start from scratch
clear

% add filepath to access helper functions
addpath('helper_funcs')

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

elementTypes = {'R','C','W','T','L'};
numElementTypes = length(elementTypes);
modes = {'s','p'};

strcir1 = 's(R,L,p(p(s(R,p(R,R,C)),C),s(R,p(T,T),p(T,T))))'
flatcir1 = flattenCircuit(strcir1,modes,elementTypes)
canoncir1 = getCanonicalForm(flatcir1, elementTypes, numElementTypes, modes)

strcir2 = 's(R,L,p(p(p(R,p(R,R,C)),C),s(R,p(T,T),p(T,T))))'
flatcir2 = flattenCircuit(strcir2,modes,elementTypes)
canoncir2 = getCanonicalForm(flatcir2, elementTypes, numElementTypes, modes)
%}

%% Configuration

% Initialize parameters
maxElements = 5;

loadsave = false;
elementTypes = {'R','C','W','T','L','G'};
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
profile off
profile on -historysize 5e7
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
                    newCircuit = [modes{m} '(' elementTypes{e} ',' CircStr{numElements-1}{c} ')'];
                    [canonicalCircuit, good] = processCircuit(newCircuit, numElements, CircStr{numElements}, elementTypes, numElementTypes, modes);
                    if good
                        CircStr{numElements}{end+1} = canonicalCircuit;
                    end
                end
                % Insert element e into components of c
                [oc, numComps] = findParentheses(CircStr{numElements-1}{c});
                for idx = 1:numComps
                    newCircuit = insertAfter(CircStr{numElements-1}{c}, oc(idx,2)-1, [',', elementTypes{e}]);
                    [canonicalCircuit, good] = processCircuit(newCircuit, numElements, CircStr{numElements}, elementTypes, numElementTypes, modes);
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
                            str = [modes{m} '(' elementTypes{e} ','];
                            bigstr = insertAfter(CircStr{numElements-1}{c}, elem{el}(idx), ')');
                            newCircuit = insertAfter(bigstr, elem{el}(idx)-1, str);
                            % Process circuit
                            [canonicalCircuit, good] = processCircuit(newCircuit, numElements, CircStr{numElements}, elementTypes, numElementTypes, modes);
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
profsave
profile viewer

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
