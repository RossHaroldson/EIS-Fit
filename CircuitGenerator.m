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
definput = {'6','R,C,L,W,T,G','1','2','1000'};
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
saveFiles=struct();
% Get save and load location for data
savefolder = uigetdir('C:\', 'Specify folder to save generated circuit configurations (Could be very large)');
if ischar(savefolder)
    savedata = true;
else
    savedata = false;
end

% Ask to load data from file
loadfolder = uigetdir(savefolder, 'Choose which data folder to load');
if ischar(loadfolder)
    disp('Loading saved data.')
    list=dir(fullfile(loadfolder,'*.mat'));
    if length(list) >= 0
        for i=1:length(list)
            saveFiles.(list(i).name(1:end-4)) = matfile(fullfile(loadfolder,list(i).name), 'Writable', true);
        end
    end
    loadeddata = true;
else
    loadeddata = false;
end

% Initialize or load variables
if loadeddata
    % Load existing variables from the MAT-file
    if isfield('currentNumElements', saveFiles)
        currentNumElements = saveFiles.currentNumElements.currentNumElements;
    else
        currentNumElements = 1;
        if savedata
            saveFiles.currentNumElements = matfile(fullfile(savefolder,'currentNumElements.mat'), 'Writable', true);
            saveFiles.currentNumElements.currentNumElements = currentNumElements;
        end
    end
    if isfield('elapsedTime', saveFiles)
        elapsedTime = saveFiles.elapsedTime.elapsedTime;
    else
        elapsedTime = zeros(maxElements, 2);
        saveFiles.elapsedTime.elapsedTime = elapsedTime;
        if savedata
            saveFiles.elapsedTime = matfile(fullfile(savefolder,'elapsedTime.mat'), 'Writable', true);
            saveFiles.elapsedTime.elapsedTime = elapsedTime;
        end
    end
else
    % Initialize variables in the MAT-file
    currentNumElements = 1;
    elapsedTime = zeros(maxElements, 2);
    if savedata
        saveFiles.currentNumElements = matfile(fullfile(savefolder,'currentNumElements.mat'), 'Writable', true);
        saveFiles.currentNumElements.currentNumElements = currentNumElements;
        saveFiles.elapsedTime = matfile(fullfile(savefolder,'elapsedTime.mat'), 'Writable', true);
        saveFiles.elapsedTime.elapsedTime = elapsedTime;
    end
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
        if ~isfield(saveFiles,varname_curr)
            currentCircuits = string(elementtypes);
        else
            currentCircuits = saveFiles.(varname_curr).(varname_curr);
        end
        if ~isfield(saveFiles,varname_processedMask)
            processedMask = true(length(elementtypes), 1);
        else
            processedMask = saveFiles.(varname_processedMask).(varname_processedMask);
        end

    else
        % Load previous circuits
        if isfield(saveFiles,varname_prev)
            previousCircuits = saveFiles.(varname_prev).(varname_prev);
        else
            error(['Previous circuits for numElements = ' num2str(numElements - 1) ' not found in the MAT-file.']);
        end

        % Initialize or load current circuits
        varname_curr = ['CircStr' num2str(numElements)];
        if isfield(saveFiles, varname_curr)
            currentCircuits = saveFiles.(varname_curr).(varname_curr);
        else
            currentCircuits = strings(0,1);
        end

        % Load or initialize processedMask
        if isfield(saveFiles,varname_processedMask)
            processedMask = saveFiles.(varname_processedMask).(varname_processedMask);
        else
            processedMask = false(length(previousCircuits), 1);
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
                disp('Cancellation requested.');
                if savedata
                    disp('Saving progress and exiting.');
                    % save current data
                    saveFiles.currentNumElements.currentNumElements=numElements;
                    saveFiles.elapsedTime.elapsedTime=elapsedTime;
                    disp(['Saving ' varname_processedMask])
                    if isfield(saveFiles,varname_processedMask)
                        saveFiles.(varname_processedMask).(varname_processedMask)  = processedMask;
                    else
                        saveFiles.(varname_processedMask) = matfile(fullfile(savefolder,[varname_processedMask '.mat']), 'Writable', true);
                        saveFiles.(varname_processedMask).(varname_processedMask)  = processedMask;
                    end
                    disp(['Saving ' varname_curr])
                    if isfield(saveFiles,varname_curr)
                        saveFiles.(varname_curr).(varname_curr)  = currentCircuits;
                    else
                        saveFiles.(varname_curr) = matfile(fullfile(savefolder,[varname_curr '.mat']), 'Writable', true);
                        saveFiles.(varname_curr).(varname_curr)  = currentCircuits;
                    end
                    disp('Finished Saving and Returning');
                else
                    disp('Finished and didnt save data');
                end
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
            disp('Adding new circuits from this batch to main list of current circuits')
            allNewCircuits = unique(vertcat(tempCircuits{:}));
            currentCircuits = [currentCircuits; allNewCircuits];

            % Remove duplicates in current batch to reduce data size
            currentCircuits = unique(currentCircuits);

            % Update processedMask
            processedMask(batchIndices) = true;
            if savedata && batchNum ~= numBatches
                disp('Saving progress and exiting.');
                % save current data
                saveFiles.currentNumElements.currentNumElements=numElements;
                saveFiles.elapsedTime.elapsedTime=elapsedTime;
                disp(['Saving ' varname_processedMask])
                if isfield(saveFiles,varname_processedMask)
                    saveFiles.(varname_processedMask).(varname_processedMask)  = processedMask;
                else
                    saveFiles.(varname_processedMask) = matfile(fullfile(savefolder,[varname_processedMask '.mat']), 'Writable', true);
                    saveFiles.(varname_processedMask).(varname_processedMask)  = processedMask;
                end
                % disp(['Saving ' varname_curr])
                % if isfield(saveFiles,varname_curr)
                %     saveFiles.(varname_curr).(varname_curr)  = currentCircuits;
                % else
                %     saveFiles.(varname_curr) = matfile(fullfile(savefolder,[varname_curr '.mat']), 'Writable', true);
                %     saveFiles.(varname_curr).(varname_curr)  = currentCircuits;
                % end
                disp('Finished Saving per batch');
            else
                saveFiles.currentNumElements.currentNumElements=numElements;
                saveFiles.elapsedTime.elapsedTime=elapsedTime;
                %saveFiles.(varname_processedMask).(varname_processedMask)  = processedMask;
                disp(['updating ' varname_curr])
                %saveFiles.(varname_curr).(varname_curr)  = currentCircuits;
                disp('Finished updating in memory')
            end
            drawnow;
            disp([char(datetime) ' : Saved after processing batch ' num2str(batchNum) ' out of ' num2str(numBatches) ' batches of circuit size ' num2str(numElements)]);
        end
        processedMask(:) = true;
    end
    % Update elapsed time
    elapsedTime(numElements, 1) = toc(t1);
    elapsedTime(numElements, 2) = toc(t2);

    disp(['Number of circuits made with ' num2str(numElements) ' elements were ' num2str(length(currentCircuits)) ' at ' char(datetime)]);
    if numElements > 3
        [fitresult, ~] = createExpFit((1:numElements)', elapsedTime(1:numElements, 2));
        [fitresult2, ~] = createExpFit((1:numElements)', elapsedTime(1:numElements, 1));
        timenow = datetime;
        estimatenextdatetime = timenow + seconds(fitresult.a * exp(fitresult.b * (numElements + 1)) + fitresult.c);
        estimatedfinishtime = timestart + seconds(fitresult2.a * exp(fitresult2.b * (maxElements)) + fitresult2.c);
        disp(['Estimated time when ' num2str(numElements + 1) ' element size circuits are complete: ' char(estimatenextdatetime)]);
        disp(['Estimated time when ' num2str(maxElements) ' element size circuits are complete: ' char(estimatedfinishtime)]);
    end
    % save or update data
    if savedata
        disp('Saving progress');
        % save current data
        saveFiles.currentNumElements.currentNumElements=numElements;
        saveFiles.elapsedTime.elapsedTime=elapsedTime;
        disp(['Saving ' varname_processedMask])
        if isfield(saveFiles,varname_processedMask)
            saveFiles.(varname_processedMask).(varname_processedMask)  = processedMask;
        else
            saveFiles.(varname_processedMask) = matfile(fullfile(savefolder,[varname_processedMask '.mat']), 'Writable', true);
            saveFiles.(varname_processedMask).(varname_processedMask)  = processedMask;
        end
        disp(['Saving ' varname_curr])
        if isfield(saveFiles,varname_curr)
            saveFiles.(varname_curr).(varname_curr)  = currentCircuits;
        else
            saveFiles.(varname_curr) = matfile(fullfile(savefolder,[varname_curr '.mat']), 'Writable', true);
            saveFiles.(varname_curr).(varname_curr)  = currentCircuits;
        end
        disp('Finished Saving');
    else
        saveFiles.currentNumElements.currentNumElements=numElements;
        saveFiles.elapsedTime.elapsedTime=elapsedTime;
        saveFiles.(varname_processedMask).(varname_processedMask)  = processedMask;
        saveFiles.(varname_curr).(varname_curr)  = currentCircuits;
        disp('Updated data');
    end
    % Check for cancellation after completing numElements
    drawnow; % Process GUI events
    if ~ishandle(hWaitbar)
        disp('Cancellation requested.');
        return
    else
        
    end
end
delete(hWaitbar);
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