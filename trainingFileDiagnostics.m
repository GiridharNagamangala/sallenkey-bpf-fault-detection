% --- Diagnostic & repair script for Classification Learner response issues ---
% Assumes your table variable is named 'features' or 'allFeatures'. Adjust names if needed.
if exist('features','var')
    T = features;
elseif exist('allFeatures','var')
    T = allFeatures;
else
    error('No table named "features" or "allFeatures" found in workspace. Load your table first.');
end

fprintf('Table found: rows=%d, vars=%d\n', height(T), width(T));

% 1) Does Label exist?
if ~ismember('Label', T.Properties.VariableNames)
    fprintf('>>> No variable named "Label" in the table. Variables: %s\n', strjoin(T.Properties.VariableNames, ', '));
    error('Add a variable named "Label" to the table (categorical labels).');
else
    fprintf('Label variable present.\n');
end

% 2) Show class and few values
lab = T.Label;
fprintf(' class(Label) = %s\n', class(lab));
if iscell(lab)
    fprintf(' Label is a cell array - converting to string first.\n');
end
numExamples = numel(lab);
fprintf(' First 10 label values (or fewer):\n');
disp(lab(1:min(10,numExamples)));

% 3) Common problematic types: char matrix or cellstr or missing values
% Convert common types safely to categorical
if ischar(lab)         % char matrix where each row is a label
    fprintf(' Converting char array to cellstr -> categorical.\n');
    T.Label = categorical(cellstr(lab));
elseif iscell(lab)     % cell array (maybe cellstr)
    % check content
    if all(cellfun(@(x) ischar(x) || isstring(x), lab))
        fprintf(' Converting cell array of strings to categorical.\n');
        T.Label = categorical(string(lab));
    else
        error('Label is a cell array but not string/char cells. Inspect contents.');
    end
elseif isstring(lab)
    fprintf(' Converting string array to categorical.\n');
    T.Label = categorical(lab);
elseif ~iscategorical(lab)
    fprintf(' Label is not categorical (%s). Converting numeric to categorical if sensible.\n', class(lab));
    if isnumeric(lab) || islogical(lab)
        T.Label = categorical(lab);    % numeric -> categorical (0,1,2...)
    else
        error('Label type unsupported: %s', class(lab));
    end
else
    fprintf(' Label is already categorical.\n');
end

% 4) Check for missing or empty labels
numMissing = sum(ismissing(T.Label));
if numMissing>0
    fprintf(' >>> Warning: %d missing label(s) detected. Removing those rows.\n', numMissing);
    T = T(~ismissing(T.Label), :);
end

% 5) Check row count match with predictors
fprintf(' After sanitizing labels: rows=%d\n', height(T));

% 6) Are predictors numeric? Classification Learner expects numeric predictors (or categorical).
predNames = T.Properties.VariableNames;
predNames(strcmp(predNames,'Label')) = [];
nonNumeric = {};
for i=1:numel(predNames)
    if ~(isnumeric(T.(predNames{i})) || islogical(T.(predNames{i})) || iscategorical(T.(predNames{i})))
        nonNumeric{end+1} = predNames{i}; %#ok<SAGROW>
    end
end
if ~isempty(nonNumeric)
    fprintf(' >>> Non-numeric predictors found: %s\n', strjoin(nonNumeric, ', '));
    fprintf('Try converting them to numeric or removing them before launching the app.\n');
else
    fprintf(' All predictors are numeric or categorical-good.\n');
end

% 7) Check that Label has more than one category
cats = categories(T.Label);
fprintf(' Label categories (%d): %s\n', numel(cats), strjoin(cats, ', '));
if numel(cats) < 2
    error('Label has only one category. Classification requires >= 2 classes. Check that you loaded data for multiple fault classes.');
end

% 8) Check table type (not timetable, dataset etc.)
if istimetable(T)
    fprintf(' >>> Table is a timetable. Converting to normal table.\n');
    T = timetable2table(T);
end

% 9) Final quick checks before opening the app
fprintf('Final table summary:\n');
summary(T);

% Save sanitized table as 'features_forApp' and put in base workspace
features_forApp = T; %#ok<NASGU>
assignin('base','features_forApp', features_forApp);
fprintf('\nCreated variable "features_forApp" in base workspace. Use this variable in Classification Learner (New > From Workspace).\n');

% Optional: automatically open the Classification Learner
% classificationLearner % uncomment to launch automatically
