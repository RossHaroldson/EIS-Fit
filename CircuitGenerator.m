% Equivalent Circuit Generator
% This test script is for generating all possible configurations of circuits
% given a max number of elements and element types, taking into account
% rules for valid circuit configurations. Circuit configurations are built 
% recursively to minimize the number of invalid configurations.

%% Clear everything to start from scratch
clear all

%% Tests
%strcir='s(R,L,p(p(s(R,p(R,C)),C),s(R,p(O,O),p(O,O))))'
strcir='s(R,L,p(p(s(R,p(R,C)),C,s(p(O,O),p(O,O)))))'
%strcir='p(T,s(R,T))'
%strcir='s(R,O,L)'
cir=parseCircuitString(strcir);
simpcir=simplifyCircuitString(strcir)
concir=getCanonicalForm(cir)
cir=parseCircuitString(concir);
isValidCircuit(cir)
A='asdlkfjovnwoinasldknvuwbivas;dkjowiefasd;kvwoabvoiadklkanasdlkfjovnwoinasldknvuwbivas;dkjowiefasd;kvwoabvoiadklkanasdlkfjovnwoinasldknvuwbivas;dkjowiefasd;kvwoabvoiadklkanasdlkfjovnwoinasldknvuwbivas;dkjowiefasd;kvwoabvoiadklkan';
B={'a','b'};
f=@() contains(A,B);
f2=@() ismember(A,B);
 timeit(f)
timeit(f2)

%% Tests
for i=1:length(CircStrOld)
    DiffCircStr{i}=CircStrNew{i}(~ismember(CircStrNew{i},CircStrOld{i}));
end
%% Configuration
prompt = {'Max number of elements: ',...
    'Element types (R, C, L, W, T, O, G,...): ',...
    'Parallel computing with more cores? (1 for yes, 0 for no): ',...
    'Parallel computing number of workers (Leave blank for default size): '};
dlgtitle = 'Configuration';
fieldsize = [1 45; 1 45; 1 45; 1 45];
definput = {'6','R,C,L,W,T','0',''};
answer = inputdlg(prompt,dlgtitle,fieldsize,definput);

% Go through answers
maxElements = str2double(answer{1});
elements = unique(answer{2}(isletter(answer{2})));
elementtypes=cell(length(elements),1);
for i=1:length(elements)
    elementtypes{i,1} = elements(i);
end
if answer{3}
    % Delete any exisiting pool
    p = gcp('nocreate');
    delete(p)
    parallelloop=true;
    % create cluster object c
    c = parcluster;
    if isscalar(answer{4})
        % Try to create pool with desired number of workers
        try
            p = c.parpool(answer{4});
        catch
            disp(['Failed to create cluster with input size: ' num2str(answer{4})]);
            disp('Creating pool with default size');
            p=c.parpool;
        end
    else
        disp('Creating pool with default size');
        p=c.parpool;
    end
else
    parallelloop = false;
    p = gcp('nocreate');
    delete(p)
end

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

% Ask to load data from file
% NOT implemented yet
[file, loaddatafilepath] = uigetfile('C:\', 'Choose which data file to load');
if ischar(loaddatafilepath)
    load([loaddatafilepath file]);
    loadeddata = true;
else
    loadeddata = false;
end
disp('Finished Configuration')
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
                
                localNewCircuits = createNewCircuits(elementtypes,localNewCircuits,circuit,numElements);

                % Collect local results into the preallocated array
                tempCircuits{idx} = localNewCircuits;
            end
        else
            % Do single core method
            for idx = randperm(length(previousCircuits)) % Broadcast only previousCircuits
                localNewCircuits = {}; % Local to this parfor iteration
                circuitStr = previousCircuits{idx};   % Only work on the relevant slice
                circuit = parseCircuitString(circuitStr);

                localNewCircuits = createNewCircuits(elementtypes,localNewCircuits,circuit,numElements);

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
    disp(['Number of circuits made with ' num2str(numElements) ' elements were ' num2str(length(CircStr{numElements})) ' at ' char(datetime)])
    if numElements > 3
        [fitresult, ~] = createExpFit((1:numElements)',elapsedtime(1:numElements,2));
        [fitresult2, ~] = createExpFit((1:numElements)',elapsedtime(1:numElements,1));
        timenow = datetime;
        estimatenextdatetime = timenow + seconds(fitresult.a*exp(fitresult.b*(numElements+1))+fitresult.c);
        estimatedfinishtime = timenow + seconds(fitresult2.a*exp(fitresult2.b*(maxElements))+fitresult2.c);
        disp(['Estimated time when ' num2str(numElements+1) ' element size circuits are complete: ' char(estimatenextdatetime)])
        disp(['Estimated time when ' num2str(maxElements) ' element size circuits are complete: ' char(estimatedfinishtime)])
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