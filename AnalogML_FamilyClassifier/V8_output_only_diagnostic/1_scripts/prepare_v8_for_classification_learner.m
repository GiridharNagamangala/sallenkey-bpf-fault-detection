clear; clc;

% ============================================================
% Prepare V8 datasets for Classification Learner
%
% Creates:
% T_v8_flat
% T_v8_BPF
% T_v8_BSF
% T_v8_HPF
% T_v8_LPF
%
% Use these in Classification Learner.
% ============================================================

thisFile = mfilename('fullpath');
scriptFolder = fileparts(thisFile);
base = fileparts(scriptFolder);

dataFile = fullfile(base, '2_datasets', 'family_classifier_dataset_v8_final.mat');

load(dataFile, 'T_v8');

T_v8.FamilyLabel = categorical(T_v8.FamilyLabel);
T_v8.ResponseType = categorical(T_v8.ResponseType);

T_v8_flat = T_v8;

T_v8_BPF = T_v8(T_v8.ResponseType == "BPF", :);
T_v8_BSF = T_v8(T_v8.ResponseType == "BSF", :);
T_v8_HPF = T_v8(T_v8.ResponseType == "HPF", :);
T_v8_LPF = T_v8(T_v8.ResponseType == "LPF", :);

assignin('base', 'T_v8_flat', T_v8_flat);
assignin('base', 'T_v8_BPF', T_v8_BPF);
assignin('base', 'T_v8_BSF', T_v8_BSF);
assignin('base', 'T_v8_HPF', T_v8_HPF);
assignin('base', 'T_v8_LPF', T_v8_LPF);

disp("Created Classification Learner variables:");
disp("T_v8_flat");
disp("T_v8_BPF");
disp("T_v8_BSF");
disp("T_v8_HPF");
disp("T_v8_LPF");

disp("Sizes:");
disp(size(T_v8_flat));
disp(size(T_v8_BPF));
disp(size(T_v8_BSF));
disp(size(T_v8_HPF));
disp(size(T_v8_LPF));