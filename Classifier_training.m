%% Build combined feature table from multiple Monte Carlo result files (preallocated)
clc; clear;

files = dir('mc_F*.mat');
numFiles = numel(files);

if numFiles == 0
    error('No mc_F*.mat files found in current folder.');
end

fprintf('Found %d files.\n', numFiles);

% --- Step 1: Get number of Monte Carlo runs from the first file ---
tmp = load(files(1).name);
numRunsPerFile = size(tmp.Vout_AC_real, 2);
fprintf('Each file has %d Monte Carlo runs.\n', numRunsPerFile);

% --- Step 2: Preallocate numeric arrays ---
totalRuns = numFiles * numRunsPerFile;

Feature1 = zeros(totalRuns, 1);
Feature2 = zeros(totalRuns, 1);
Feature3 = zeros(totalRuns, 1);
Feature4 = zeros(totalRuns, 1);
Feature5 = zeros(totalRuns, 1);
Feature6 = zeros(totalRuns, 1);
Labels   = strings(totalRuns, 1);

rowIdx = 1;

% --- Step 3: Loop through files ---
for k = 1:numFiles
    fname = files(k).name;
    fprintf('\nProcessing %s...\n', fname);
    data = load(fname);

    VoutACreal    = data.Vout_AC_real;
    VoutACimag    = data.Vout_AC_imag;
    IsupplyACreal = data.Isupply_AC_real;
    IsupplyACimag = data.Isupply_AC_imag;
    n = size(VoutACreal, 2);

    % Compute features for all runs in this file
    f1 = max(abs(VoutACreal), [], 1).';
    f2 = max(abs(VoutACimag), [], 1).';
    f3 = min(VoutACimag, [], 1).';
    f4 = max(abs(IsupplyACreal), [], 1).';
    f5 = max(abs(IsupplyACimag), [], 1).';
    f6 = min(IsupplyACimag, [], 1).';

    % Extract label from filename (e.g. monte_carlo_results_F3.mat → F3)
    tokens = regexp(fname, 'mc_(F\d+)', 'tokens');
    faultLabel = tokens{1}{1}; % e.g. 'F3'

    % Assign into preallocated arrays
    idxRange = rowIdx:(rowIdx + n - 1);

    Feature1(idxRange) = f1;
    Feature2(idxRange) = f2;
    Feature3(idxRange) = f3;
    Feature4(idxRange) = f4;
    Feature5(idxRange) = f5;
    Feature6(idxRange) = f6;
    Labels(idxRange)   = faultLabel;

    rowIdx = rowIdx + n;

    fprintf('   Added %d runs for %s.\n', n, faultLabel);
end

% --- Step 4: Create final table ---
features_all = table(Feature1, Feature2, Feature3, Feature4, Feature5, Feature6);
features_all.Label = categorical(Labels);

fprintf('\n Final feature table has %d rows and %d columns.\n', ...
        height(features_all), width(features_all));

save('features_all.mat', 'features_all');
disp('Saved features_all.mat ready for Classification Learner.');
