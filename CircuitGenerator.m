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
    'Element types (R, C, L, W, T, O, G,...): ',...
    'Parallel computing with more cores? (1 for yes, 0 for no): ',...
    'Parallel computing number of workers (Leave blank for default size): ',...
    'Batch Size for saving: '};
dlgtitle = 'Configuration';
fieldsize = [1 45; 1 45; 1 45; 1 45; 1 45];
definput = {'10','R,C,L,W,T,G','1','16','4000'};
answer = inputdlg(prompt,dlgtitle,fieldsize,definput);

% Go through answers
maxElements = str2double(answer{1});
elements = unique(answer{2}(isletter(answer{2})));
elementtypes=cell(length(elements),1);
for i=1:length(elements)
    elementtypes{i,1} = elements(i);
end
if str2double(answer{3})
    % Delete any exisiting pool
    p = gcp('nocreate');
    delete(p)
    parallelloop=true;
    % create cluster object c
    c = parcluster;
    if ~isnan(str2double(answer{4}))
        % Try to create pool with desired number of workers
        try
            p = c.parpool(str2double(answer{4}));
        catch ME
            disp(['Failed to create cluster with input size: ' num2str(answer{4})]);
            disp('Creating pool with default size');
            p=c.parpool;
            rethrow(ME)
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
% Set batch size
batchSize = str2double(answer{5});

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
% We'll use a matfile object for incremental saving
matObj = matfile(savefilepath, 'Writable', true);

% Ask to load data from file
[loadFileName, loaddatafilepath] = uigetfile('*.mat', 'Choose which data file to load');
if ischar(loaddatafilepath)
    disp('Loading saved data.')
    matObj = matfile(fullfile(loaddatafilepath, loadFileName), 'Writable', true);
    loadeddata = true;
else
    loadeddata = false;
end

% Initialize or load variables
if loadeddata
    % Load existing variables from the MAT-file
    variablesInMatFile = who(matObj);
    if ismember('currentNumElements', variablesInMatFile)
        currentNumElements = matObj.currentNumElements;
    else
        currentNumElements = 1;
        matObj.currentNumElements = currentNumElements;
    end
else
    % Initialize variables in the MAT-file
    matObj.currentNumElements = 1;
    currentNumElements = 1;
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
variablesInMatFile = who(matObj);
if ismember('elapsedtime', variablesInMatFile)
    elapsedtime = matObj.elapsedtime;
else
    elapsedtime = zeros(maxElements, 2);
    matObj.elapsedtime = elapsedtime;
end

% Main loop
hWaitbar = waitbar(0, 'Starting Circuit Generation.', 'Name', 'Generating Circuits','CreateCancelBtn','delete(gcbf)');
for numElements = currentNumElements:maxElements
    t2 = tic;
    fprintf('Processing circuits with %d elements\n', numElements);
    waitbar(0,hWaitbar, ['Processing circuits with ' num2str(numElements) ' elements.'], 'Name', 'Generating Circuits','CreateCancelBtn','delete(gcbf)');
    if numElements == 1
        % Base case: circuits with a single element
        varname_curr = ['CircStr' num2str(numElements)];
        variablesInMatFile = who(matObj);
        if ~ismember(varname_curr, variablesInMatFile)
            currentCircuits = string(elementtypes);
            matObj.(varname_curr) = currentCircuits;
        else
            currentCircuits = matObj.(varname_curr);
        end

    else
        % Load previous circuits
        varname_prev = ['CircStr' num2str(numElements - 1)];
        variablesInMatFile = who(matObj);
        if ismember(varname_prev, variablesInMatFile)
            previousCircuits = matObj.(varname_prev);
        else
            error(['Previous circuits for numElements = ' num2str(numElements - 1) ' not found in the MAT-file.']);
        end

        % Initialize or load current circuits
        varname_curr = ['CircStr' num2str(numElements)];
        if ismember(varname_curr, variablesInMatFile)
            currentCircuits = matObj.(varname_curr);
        else
            currentCircuits = strings(0);
        end

        % Load or initialize processedMask
        varname_processedMask = ['processedMask' num2str(numElements)];
        if ismember(varname_processedMask, variablesInMatFile)
            processedMask = matObj.(varname_processedMask);
        else
            processedMask = false(length(previousCircuits), 1);
            matObj.(varname_processedMask) = processedMask;
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

            previousCircuitsBatch = previousCircuits(batchIndices);
            tempCircuits = cell(length(previousCircuitsBatch), 1);

            if parallelloop
                parfor idx = 1:length(previousCircuitsBatch)
                    circuitStr = previousCircuitsBatch{idx};
                    circuit = parseCircuitString(circuitStr);
                    localNewCircuits = createNewCircuits(elementtypes, {}, circuit, numElements);
                    tempCircuits{idx} = localNewCircuits;
                end
            else
                for idx = 1:length(previousCircuitsBatch)
                    circuitStr = previousCircuitsBatch{idx};
                    circuit = parseCircuitString(circuitStr);
                    localNewCircuits = createNewCircuits(elementtypes, {}, circuit, numElements);
                    tempCircuits{idx} = localNewCircuits;
                end
            end

            % Concatenate results and update current circuits
            disp('Saving data after current batch')
            allNewCircuits = [tempCircuits{:}];
            currentCircuits = [currentCircuits; allNewCircuits'];

            % Remove duplicates in current batch to reduce data size
            currentCircuits = unique(currentCircuits);

            % Update processedMask
            processedMask(batchIndices) = true;
            matObj.(varname_processedMask) = processedMask;

            % Convert currentCircuits to string array
            currentCircuits_str = string(currentCircuits);

            % Write currentCircuits to matfile
            matObj.(varname_curr) = currentCircuits_str;

            % Update currentNumElements in matfile
            matObj.currentNumElements = numElements;

            % Save elapsed time
            matObj.elapsedtime = elapsedtime;
            
            drawnow;
            disp([char(datetime) ' : Saved after processing batch ' num2str(batchNum) ' out of ' num2str(numBatches) ' batches of circuit size ' num2str(numElements)]);
        end
    end

    % Update elapsed time
    elapsedtime(numElements, 1) = toc(t1);
    elapsedtime(numElements, 2) = toc(t2);

    % Save elapsed time to matfile
    matObj.elapsedtime = elapsedtime;

    disp(['Number of circuits made with ' num2str(numElements) ' elements were ' num2str(length(currentCircuits)) ' at ' char(datetime)]);
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
        matObj.currentNumElements = numElements + 1;
        matObj.elapsedtime = elapsedtime;
        matObj.(varname_processedMask) = processedMask;
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

%% Display results
% % may take forever if max elements is greater than 4
% disp('Unique and Simplified Circuit Configurations:');
% for k = 1:maxElements
%     fprintf('\nCircuits with %d element(s):\n', k);
%     circuits = CircStr{k};
%     % Sort and display
%     sortedCircuits = sort(circuits);
%     for i = 1:length(sortedCircuits)
%         disp([' - ' sortedCircuits{i}]);
%     end
% end
% clear circuits sortedCircuits

%% helper functions
% Function to perform the save operation
% function saveDataFunction(filepath, dataStruct)
%     save(filepath, '-struct', 'dataStruct', '-v7.3');
%     disp([char(datetime) ' Finished saving data'])
% end