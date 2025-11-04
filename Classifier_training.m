%% Training Classifier using Monte Carlo Analysis data

data = load("monte_carlo_results.mat");
whos('-file', 'monte_carlo_results.mat'); % Just to look at the data structs

% Declare separate variables so as to not tamper with the .mat
VoutTransient = data.Vout_transient;
VoutACreal = data.Vout_AC_real;
VoutACimag = data.Vout_AC_imag;
VoutACmag = data.Vout_AC_mag;
time = data.time_points;
freq = data.freq_points;

numRuns = size(VoutTransient, 2); % Inspecting data
any(isnan(VoutTransient(:))) || any(isnan(VoutACreal(:))); % Checking for missing values

% ----- Feature extraction -----
Feature1 = max(abs(VoutACreal), [], 1).';   % (200x1) Max peak of real output voltage
Feature2 = max(abs(VoutACimag), [], 1).';   % (200x1) Max peak of imag output voltage
Feature3 = min(VoutACimag, [], 1).';        % (200x1) Min peak (negative) of imag output voltage
Feature4 = max(abs(IsupplyACreal), [], 1).';% (200x1) Max peak of real supply current
Feature5 = max(abs(IsupplyACimag), [], 1).';% (200x1) Max peak of imag supply current
Feature6 = min(IsupplyACimag, [], 1).';     % (200x1) Min peak of imag supply current

% Combine into table
features = table(Feature1, Feature2, Feature3, Feature4, Feature5, Feature6);

% If you have labels (e.g., good/bad runs), add them here
% Example dummy labels:
labels = [repmat("F0",200,1);
          repmat("F1",200,1);
          repmat("F2",200,1);
          repmat("F3",200,1);
          repmat("F4",200,1);
          repmat("F5",200,1);
          repmat("F6",200,1);
          repmat("F7",200,1);
          repmat("F8",200,1);
          repmat("F9",200,1);
          repmat("F10",200,1)];
features.Label = categorical(labels);


% Save for Classification Learner
save('features_table.mat', 'features');