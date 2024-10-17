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
maxElements = 4;
loadsave = false;
parallelloop=false;
elementtypes = {'R','C','L','W','T'}';

% Get save and load location for data
savefolder = uigetdir('C:\', 'Specify folder to save and read generated circuit configurations (Could be very large)');
if ischar(savefolder)
    savefilepath = fullfile(savefolder, 'circuit_data.mat');
    savedata = true;
else
    savefilepath = '';
    savedata = false;
end

% Ask to load data from file
loaddatafilepath = uigetfile('C:\', 'Choose which data file to load');
if ischar(loaddatafilepath)
    load(loaddatafilepath);
    loadeddata = true;
else
    loadeddata = false;
end

% Initialize circuit storage
CircStr = cell(maxElements, 1);
circuitCount = 0; % Total number of circuits

%% Build circuits of size 1 to n
profile on
tic
for numElements = 1:maxElements
    fprintf('Processing circuits with %d elements\n', numElements);
    if numElements == 1
        % Base case: circuits with a single element
        CircStr{1} = elementtypes;
    else
        % Initialize storage for circuits of current size
        tempCircuits = cell(1, length(CircStr{numElements-1}) * length(elementtypes)); % Preallocate cell array

        previousCircuits = CircStr{numElements-1};  % Only broadcast the relevant slice
        if parallelloop
            parfor idx = 1:length(previousCircuits) % Broadcast only previousCircuits
                localNewCircuits = {}; % Local to this parfor iteration
                circuitStr = previousCircuits{idx};   % Only work on the relevant slice
                circuit = parseCircuitString(circuitStr);

                for e = 1:length(elementtypes)
                    element = elementtypes{e};
                    % Insert element into the circuit
                    newCircuitStructs = insertElement(circuit, element);

                    for c = 1:length(newCircuitStructs)
                        newCircuit = newCircuitStructs{c};
                        totalElements = getNumElements(newCircuit);

                        if totalElements == numElements
                            % Simplify and validate
                            canonicalStr = getCanonicalForm(newCircuit);
                            if ~ismember(canonicalStr, localNewCircuits)
                                localNewCircuits{end+1} = canonicalStr;
                            end
                        end
                    end
                end

                % Collect local results into the preallocated array
                tempCircuits{idx} = localNewCircuits;
            end
        else
            % Do single CPU method
            for idx = randperm(length(previousCircuits)) % Broadcast only previousCircuits
                localNewCircuits = {}; % Local to this parfor iteration
                circuitStr = previousCircuits{idx};   % Only work on the relevant slice
                circuit = parseCircuitString(circuitStr);

                for e = 1:length(elementtypes)
                    element = elementtypes{e};
                    % Insert element into the circuit
                    newCircuitStructs = insertElement(circuit, element);

                    for c = 1:length(newCircuitStructs)
                        newCircuit = newCircuitStructs{c};
                        totalElements = getNumElements(newCircuit);

                        if totalElements == numElements
                            % Simplify and validate
                            canonicalStr = getCanonicalForm(newCircuit);
                            if ~ismember(canonicalStr, localNewCircuits)
                                localNewCircuits{end+1} = canonicalStr;
                            end
                        end
                    end
                end

                % Collect local results into the preallocated array
                tempCircuits{idx} = localNewCircuits;
            end
        end
        % Concatenate results from all workers
        allNewCircuits = [tempCircuits{:}];
        % Store unique circuits of current size
        CircStr{numElements} = unique(allNewCircuits)';
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
profile viewer

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