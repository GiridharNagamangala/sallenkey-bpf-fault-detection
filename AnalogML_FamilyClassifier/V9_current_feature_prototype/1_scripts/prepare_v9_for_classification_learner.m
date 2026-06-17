clear; clc;

thisFile = mfilename('fullpath');
scriptFolder = fileparts(thisFile);
base = fileparts(scriptFolder);

dataFile = fullfile(base, '2_datasets', ...
    'family_classifier_dataset_v9_current_features.mat');

load(dataFile, 'T_v9');

T_v9.FamilyLabel = categorical(T_v9.FamilyLabel);
T_v9.ResponseType = categorical(T_v9.ResponseType);

T_v9_flat = T_v9;
T_v9_BPF = T_v9(T_v9.ResponseType == "BPF", :);
T_v9_BSF = T_v9(T_v9.ResponseType == "BSF", :);
T_v9_HPF = T_v9(T_v9.ResponseType == "HPF", :);
T_v9_LPF = T_v9(T_v9.ResponseType == "LPF", :);

assignin('base', 'T_v9_flat', T_v9_flat);
assignin('base', 'T_v9_BPF', T_v9_BPF);
assignin('base', 'T_v9_BSF', T_v9_BSF);
assignin('base', 'T_v9_HPF', T_v9_HPF);
assignin('base', 'T_v9_LPF', T_v9_LPF);

disp("Created:");
disp("T_v9_flat");
disp("T_v9_BPF");
disp("T_v9_BSF");
disp("T_v9_HPF");
disp("T_v9_LPF");

disp("Sizes:");
disp(size(T_v9_flat));
disp(size(T_v9_BPF));
disp(size(T_v9_BSF));
disp(size(T_v9_HPF));
disp(size(T_v9_LPF));