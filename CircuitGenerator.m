% Equivalent Circuit Generator
% This test script is for generating all possible configurations of circuits
% given a max number of elements and element types, taking into account
% rules for valid circuit configurations. Circuit configurations are built 
% recursively to minimize the number of invalid configurations.

%% Clear everything to start from scratch
clear all

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
maxElements = 10;
loadsave = false;
parallelloop=true;
c = parcluster;
c.NumWorkers = 22;
p = c.parpool(18);

elementtypes = {'R','C','L','W','T','G'}';

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
[file, loaddatafilepath] = uigetfile('C:\', 'Choose which data file to load');
if ischar(loaddatafilepath)
    load([loaddatafilepath file]);
    loadeddata = true;
else
    loadeddata = false;
end

% Initialize circuit storage
CircStr = cell(maxElements, 1);
circuitCount = 0; % Total number of circuits

%% Build circuits of size 1 to n
mpiprofile on
t1=tic;
elapsedtime=zeros(maxElements,2);
for numElements = 1:maxElements
    t2=tic;
    fprintf('Processing circuits with %d elements\n', numElements);
    if numElements == 1
        % Base case: circuits with a single element
        CircStr{1} = elementtypes;
    else
        % Initialize storage for circuits of current size
        tempCircuits = cell(1, length(CircStr{numElements-1}) * length(elementtypes)); % Preallocate cell array

        previousCircuits = CircStr{numElements-1};  % Only broadcast the relevant slice
        if parallelloop
            % randomize the order of previously made circuits to even out
            % the usage of workers.
            previousCircuits = previousCircuits(randperm(length(previousCircuits)));
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
            % Do single core method
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
    elapsedtime(numElements,1) = toc(t1);
    elapsedtime(numElements,2) = toc(t2)
    disp(length(CircStr{numElements}))
    if numElements > 3
        timenow = datetime;
        [fitresult, gof] = createExpFit(1:numElements,elapsedtime(1:numElements,2));
        [fitresult2, gof] = createExpFit(1:numElements,elapsedtime(1:numElements,1));
        estimatenextdatetime = timenow + seconds(fitresult.a*exp(fitresult.b*(numElements+1))+fitresult.c)
        estimatedfinishtime = timenow + seconds(fitresult2.a*exp(fitresult2.b*(maxElements))+fitresult2.c)
    end
end
disp('Finished');
mpiprofile viewer

%% Display results
% may take forever if max elements is greater than 4
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