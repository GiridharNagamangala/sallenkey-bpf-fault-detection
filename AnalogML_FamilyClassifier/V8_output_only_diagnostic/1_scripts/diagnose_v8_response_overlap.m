clear; clc; close all;

% ============================================================
% Diagnose V8 response overlap
%
% Goal:
% Plot representative magnitude responses for each family and
% response type to see whether classes are physically separable.
%
% This checks whether low accuracy is due to:
% 1. weak ML model, or
% 2. true response overlap between families.
% ============================================================

thisFile = mfilename('fullpath');
scriptFolder = fileparts(thisFile);
base = fileparts(scriptFolder);

dataFile = fullfile(base, '2_datasets', 'family_classifier_dataset_v8_final.mat');

if ~isfile(dataFile)
    error("Dataset not found: %s", dataFile);
end

load(dataFile, 'T_v8', 'f');

T_v8.FamilyLabel = categorical(T_v8.FamilyLabel);
T_v8.ResponseType = categorical(T_v8.ResponseType);

figFolder = fullfile(base, '4_figures');
if ~exist(figFolder, 'dir')
    mkdir(figFolder);
end

families = categories(T_v8.FamilyLabel);
responseTypes = categories(T_v8.ResponseType);

magNames = "Mag_" + string(1:200);

for r = 1:numel(responseTypes)

    rt = responseTypes{r};

    figure;
    hold on;
    grid on;

    title("V8 Magnitude Response Overlap: " + string(rt));
    xlabel("Frequency (Hz)");
    ylabel("Normalized Magnitude (dB)");
    set(gca, 'XScale', 'log');

    legendEntries = {};

    for fidx = 1:numel(families)

        fam = families{fidx};

        idx = T_v8.ResponseType == rt & T_v8.FamilyLabel == fam;
        rows = find(idx);

        if isempty(rows)
            continue;
        end

        % Plot only 15 random examples per family to avoid clutter
        nPlot = min(15, numel(rows));
        rows = rows(randperm(numel(rows), nPlot));

        Mag = table2array(T_v8(rows, magNames));

        for k = 1:nPlot
            plot(f, Mag(k, :), 'LineWidth', 0.6);
        end

        legendEntries{end+1} = fam; %#ok<SAGROW>
    end

    % Since many lines are plotted, legend by family colors may not be perfect.
    % The visual overlap itself is the main thing to inspect.
    outFile = fullfile(figFolder, "v8_overlap_" + string(rt) + ".png");
    saveas(gcf, outFile);

    fprintf("Saved plot: %s\n", outFile);
end

% ============================================================
% Also create average response plot per family/response type
% ============================================================

for r = 1:numel(responseTypes)

    rt = responseTypes{r};

    figure;
    hold on;
    grid on;

    title("V8 Average Magnitude Response by Family: " + string(rt));
    xlabel("Frequency (Hz)");
    ylabel("Mean Normalized Magnitude (dB)");
    set(gca, 'XScale', 'log');

    for fidx = 1:numel(families)

        fam = families{fidx};

        idx = T_v8.ResponseType == rt & T_v8.FamilyLabel == fam;

        if sum(idx) == 0
            continue;
        end

        Mag = table2array(T_v8(idx, magNames));
        meanMag = mean(Mag, 1);

        plot(f, meanMag, 'LineWidth', 2);
    end

    legend(families, 'Location', 'best');

    outFile = fullfile(figFolder, "v8_average_response_" + string(rt) + ".png");
    saveas(gcf, outFile);

    fprintf("Saved average plot: %s\n", outFile);
end

fprintf("\nDone. Check figures folder for V8 overlap plots.\n");