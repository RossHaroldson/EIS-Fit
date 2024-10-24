% Equivalent Circuit Generator
% This test script is for generating all possible configurations of circuits
% given a max number of elements and element types, taking into account
% rules for valid circuit configurations. Circuit configurations are built 
% recursively to minimize the number of invalid configurations.

%% Clear everything to start from scratch
clear all
profile off
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
%% Tests
for i=1:length(CircStrOld)
    DiffCircStr{i}=CircStrNew{i}(~ismember(CircStrNew{i},CircStrOld{i}));
end
%% Configuration
prompt = {'Max number of elements: ',...
    'Element types (R, C, L, W, T, G,...): ',...
    'Parallel computing with more cores? (1 for yes, 0 for no): ',...
    'Parallel computing number of workers (Leave blank for default size): ',...
    'Batch Size for saving: '};
dlgtitle = 'Configuration';
fieldsize = [1 45; 1 45; 1 45; 1 45; 1 45];
definput = {'5','R,C,L,W,T,G','1','2','1000'};
answer = inputdlg(prompt,dlgtitle,fieldsize,definput);

% Go through answers
maxElements = str2double(answer{1});
elements = unique(answer{2}(isletter(answer{2})));
elementtypes = string(elements(:));

if str2double(answer{3})
    % Delete any existing pool
    p = gcp('nocreate');
    delete(p)
    parallelloop = true;
    % create cluster object c
    c = parcluster;
    if ~isnan(str2double(answer{4}))
        % Try to create pool with desired number of workers
        try
            p = c.parpool(str2double(answer{4}));
        catch ME
            disp(['Failed to create cluster with input size: ' num2str(answer{4})]);
            disp('Creating pool with default size');
            p = c.parpool;
            rethrow(ME)
        end
    else
        disp('Creating pool with default size');
        p = c.parpool;
    end
else
    parallelloop = false;
    p = gcp('nocreate');
    delete(p)
end
% Set batch size
batchSize = str2double(answer{5});

% Ask to load data from file
loaddatafolderpath = uigetdir('C:\', 'Choose which Tall data folder to load');

if ischar(loaddatafolderpath)
    d = dir(loaddatafolderpath);
    isub = [d(:).isdir]; %# returns logical vector
    nameSubFolds = {d(isub).name}';
    nameSubFolds(ismember(nameSubFolds,{'.','..'})) = [];
    disp('Loading saved data.')
    for i = 1:length(nameSubFolds)
        try
            tds.(nameSubFolds{i}) = datastore(fullfile(loaddatafolderpath, nameSubFolds{i}));
            t.(nameSubFolds{i}) = tall(tds.(nameSubFolds{i}));
            disp(['Loaded ' nameSubFolds{i}])
        catch ME
            disp(['Failed to datastore ' fullfile(loaddatafolderpath, nameSubFolds{i})])
            rethrow(ME)
        end
    end
    % load small data .mat file
    load(fullfile(loaddatafolderpath, 'circuit_data.mat'))
    loadeddata = true;
else
    loadeddata = false;
    currentNumElements = 1;
end

% Get save and load location for data
savefolder = uigetdir('C:\', 'Specify folder to save generated circuit configurations (Could be very large)');
if ischar(savefolder)
    %savefilepath = fullfile(savefolder, 'circuit_data.mat');
    savedata = true;
else
    %savefilepath = '';
    savefolder=loaddatafolderpath;
    savedata = false;
end

% Initialize or load variables
if ~loadeddata
    % Initialize variables in the MAT-file
    % matObj.currentNumElements = 1;
    currentNumElements = 1;
    CircStr1=strings(0,1);
    t.CircStr1 = tall(CircStr1);
    t.processedMask1 = tall(true(length(elementtypes)));
    write(fullfile(savefolder,'CircStr1'),t.CircStr1)
    write(fullfile(savefolder,'processedMask1'),t.processedMask1)
    tds.CircStr1 = datastore(fullfile(savefolder, 'CircStr1'));
    tds.processedMask1 = datastore(fullfile(savefolder, 'processedMask1'));
end

disp('Finished Configuration')
%% Build circuits of size 1 to n
if parallelloop
    mpiprofile on
else
    profile on
end

t1 = tic;
timestart=datetime;

% Initialize variables for timing
if ~exist('elapsedtime','var')
    elapsedtime = zeros(maxElements, 2);
end

% Main loop
hWaitbar = waitbar(0, 'Starting Circuit Generation.', 'Name', 'Generating Circuits','CreateCancelBtn','delete(gcbf)');
for numElements = currentNumElements:maxElements
    t2 = tic;
    fprintf('Processing circuits with %d elements\n', numElements);
    waitbar(0,hWaitbar, ['Processing circuits with ' num2str(numElements) ' elements.'], 'Name', 'Generating Circuits','CreateCancelBtn','delete(gcbf)');
    varname_curr = ['CircStr' num2str(numElements)];
    varname_prev = ['CircStr' num2str(numElements - 1)];
    varname_processedMask = ['processedMask' num2str(numElements)];

    if numElements == 1
        % Base case: circuits with a single element
        if ~isfield(t, varname_curr)
            t.(varname_curr) = elementtypes;
            t.(varname_processedMask) = true(length(elementtypes));
            currentCircuits = gather(t.(varname_curr));
        end

    else
        % Initialize or load current circuits
        if isfield(t,varname_curr)
            currentCircuits = gather(t.(varname_curr));
        else
            currentCircuits = strings(0,1);
        end

        % Load or initialize processedMask
        if isfield(t, varname_processedMask)
            processedMask = gather(t.(varname_processedMask));
        else
            processedMask = false(gather(length(t.(varname_prev))), 1);
        end

        % Determine unprocessed indices
        unprocessedIndices = find(~processedMask);

        % Total number of unprocessed circuits
        totalUnprocessed = length(unprocessedIndices);
        numBatches = ceil(totalUnprocessed / batchSize);
        waitbar(1/numBatches,hWaitbar, ['Iteration 1 out of ' num2str(numBatches)], 'Name', 'Generating Circuits','CreateCancelBtn','delete(gcbf)');

        for batchNum = 1:numBatches
            % Process GUI events to detect button presses
            pause(1);
            drawnow;

            % Check for cancellation before starting the batch
            if ~ishandle(hWaitbar)
                disp('Cancellation requested. Saving progress and exiting.');
                matObj.currentNumElements = numElements;
                matObj.elapsedtime = elapsedtime;
                matObj.(varname_processedMask) = processedMask;
                disp('Finished Saving and Returning');
                return
            else
                % Update the wait bar
                waitbar(batchNum/numBatches,hWaitbar, ['Processing batch ' num2str(batchNum) ' out of ' num2str(numBatches) ' batches of circuit size ' num2str(numElements)]);
                drawnow;
                pause(0.1);
                drawnow;
            end

            % Define batch indices
            batchStartIdx = (batchNum - 1) * batchSize + 1;
            batchEndIdx = min(batchNum * batchSize, totalUnprocessed);
            batchIndices = unprocessedIndices(batchStartIdx:batchEndIdx);

            previousCircuitsBatch = gather(t.(varname_prev)(batchIndices));
            tempCircuits = cell(length(previousCircuitsBatch), 1);

            if parallelloop
                parfor idx = 1:length(previousCircuitsBatch)
                    circuitStr = previousCircuitsBatch{idx};
                    circuit = parseCircuitString(circuitStr);
                    localNewCircuits = createNewCircuits(elementtypes, strings(0,1), circuit, numElements);
                    tempCircuits{idx} = localNewCircuits;
                end
            else
                for idx = 1:length(previousCircuitsBatch)
                    circuitStr = previousCircuitsBatch{idx};
                    circuit = parseCircuitString(circuitStr);
                    localNewCircuits = createNewCircuits(elementtypes, strings(0,1), circuit, numElements);
                    tempCircuits{idx} = localNewCircuits;
                end
            end

            % Concatenate results and update current circuits
            disp('Saving data after current batch')
            allNewCircuits = vertcat(tempCircuits{:});
            currentCircuits = [currentCircuits; allNewCircuits];

            % Remove duplicates in current batch to reduce data size
            t.(varname_curr) = unique(currentCircuits);

            % Update processedMask
            processedMask(batchIndices) = true;
            t.(varname_processedMask) = processedMask;

            % Update currentNumElements in matfile
            currentNumElements = numElements;
            
            save(fullfile(savefolderpath, 'circuit_data.mat'),currentNumElements,elapsedtime)
            write(t.(varname_curr))
            drawnow;
            disp([char(datetime) ' : Saved after processing batch ' num2str(batchNum) ' out of ' num2str(numBatches) ' batches of circuit size ' num2str(numElements)]);
        end
    end

    % Update elapsed time
    elapsedtime(numElements, 1) = toc(t1);
    elapsedtime(numElements, 2) = toc(t2);

    disp(['Number of circuits made with ' num2str(numElements) ' elements were ' num2str(gather(length(currentCircuits))) ' at ' char(datetime)]);
    if numElements > 3
        [fitresult, ~] = createExpFit((1:numElements)', elapsedtime(1:numElements, 2));
        [fitresult2, ~] = createExpFit((1:numElements)', elapsedtime(1:numElements, 1));
        timenow = datetime;
        estimatenextdatetime = timenow + seconds(fitresult.a * exp(fitresult.b * (numElements + 1)) + fitresult.c);
        estimatedfinishtime = timestart + seconds(fitresult2.a * exp(fitresult2.b * (maxElements)) + fitresult2.c);
        disp(['Estimated time when ' num2str(numElements + 1) ' element size circuits are complete: ' char(estimatenextdatetime)]);
        disp(['Estimated time when ' num2str(maxElements) ' element size circuits are complete: ' char(estimatedfinishtime)]);
    end

    % Check for cancellation after completing numElements
    drawnow; % Process GUI events
    if ~ishandle(hWaitbar)
        disp('Cancellation requested. Saving progress and exiting.');
        currentNumElements = numElements + 1;
        elapsedtime = elapsedtime;
        t.(varname_processedMask) = processedMask;
        save(fullfile(savefolderpath, 'circuit_data.mat'),currentNumElements,elapsedtime)
        disp('Finished Saving and Returning');
        return
    end
end

disp('Finished');
if parallelloop
    mpiprofile viewer
else
    profile viewer
end
