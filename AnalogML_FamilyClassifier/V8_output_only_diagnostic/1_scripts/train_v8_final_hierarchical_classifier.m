clear; clc; close all;

% ============================================================
% V8 Final Hierarchical Family Classifier
%
% Dataset:
% family_classifier_dataset_v8_final.mat
%
% Target:
% FamilyLabel
%
% Strategy:
% Split by ResponseType, then classify family inside each group.
% ============================================================

thisFile = mfilename('fullpath');
scriptFolder = fileparts(thisFile);
base = fileparts(scriptFolder);

dataFile = fullfile(base, '2_datasets', 'family_classifier_dataset_v8_final.mat');

if ~isfile(dataFile)
    error("Dataset not found. Run generate_v8_final_component_dataset.m first.");
end

load(dataFile, 'T_v8');

T_v8.FamilyLabel = categorical(T_v8.FamilyLabel);
T_v8.ResponseType = categorical(T_v8.ResponseType);

allNames = string(T_v8.Properties.VariableNames);
predictorMask = allNames ~= "FamilyLabel" & allNames ~= "ResponseType";
predictorNames = allNames(predictorMask);

Xall = table2array(T_v8(:, predictorNames));
Yall = T_v8.FamilyLabel;
Rall = T_v8.ResponseType;

responseTypes = categories(Rall);

allTrueStr = strings(0,1);
allPredStr = strings(0,1);

results = table();

fprintf("\n=====================================================\n");
fprintf("V8 Final Hierarchical Family Classifier\n");
fprintf("=====================================================\n\n");

for i = 1:numel(responseTypes)

    rt = responseTypes{i};
    idx = Rall == rt;

    X = Xall(idx,:);
    Y = Yall(idx);

    fprintf("\n-----------------------------------------------------\n");
    fprintf("ResponseType = %s\n", rt);
    fprintf("Samples      = %d\n", numel(Y));

    cvp = cvpartition(Y, 'KFold', 5);

    bestAcc = -inf;
    bestName = "";
    bestPred = categorical([]);
    bestDetails = "";

    % Fine Tree
    treeModel = fitctree(X, Y, ...
        'MaxNumSplits', 500, ...
        'MinLeafSize', 1, ...
        'SplitCriterion', 'gdi');

    cvTree = crossval(treeModel, 'CVPartition', cvp);
    predTree = kfoldPredict(cvTree);
    accTree = mean(predTree == Y);

    fprintf("Fine Tree accuracy: %.2f %%\n", 100*accTree);

    if accTree > bestAcc
        bestAcc = accTree;
        bestName = "FineTree";
        bestPred = predTree;
        bestDetails = "MaxNumSplits=500, MinLeafSize=1";
    end

    % KNN grid
    knnBestAcc = -inf;
    knnBestPred = categorical([]);
    knnBestDetails = "";

    neighborList = [1 3 5 7 10 15 20];
    distanceList = ["euclidean", "cityblock", "cosine"];
    weightList = ["equal", "inverse", "squaredinverse"];

    for nn = neighborList
        for d = distanceList
            for wt = weightList
                try
                    knnModel = fitcknn(X, Y, ...
                        'NumNeighbors', nn, ...
                        'Distance', char(d), ...
                        'DistanceWeight', char(wt), ...
                        'Standardize', true);

                    cvKNN = crossval(knnModel, 'CVPartition', cvp);
                    predKNN = kfoldPredict(cvKNN);
                    accKNN = mean(predKNN == Y);

                    if accKNN > knnBestAcc
                        knnBestAcc = accKNN;
                        knnBestPred = predKNN;
                        knnBestDetails = sprintf("k=%d, distance=%s, weight=%s", ...
                            nn, d, wt);
                    end
                catch
                end
            end
        end
    end

    fprintf("Best KNN accuracy: %.2f %% (%s)\n", ...
        100*knnBestAcc, knnBestDetails);

    if knnBestAcc > bestAcc
        bestAcc = knnBestAcc;
        bestName = "OptimizedKNN";
        bestPred = knnBestPred;
        bestDetails = knnBestDetails;
    end

    % Bagged Trees grid
    bagBestAcc = -inf;
    bagBestPred = categorical([]);
    bagBestDetails = "";

    cycleList = [100 200 300];
    minLeafList = [1 2 5];
    splitList = [100 250 500];

    for nCycles = cycleList
        for minLeaf = minLeafList
            for maxSplits = splitList
                try
                    treeTemplate = templateTree( ...
                        'MaxNumSplits', maxSplits, ...
                        'MinLeafSize', minLeaf);

                    bagModel = fitcensemble(X, Y, ...
                        'Method', 'Bag', ...
                        'NumLearningCycles', nCycles, ...
                        'Learners', treeTemplate);

                    cvBag = crossval(bagModel, 'CVPartition', cvp);
                    predBag = kfoldPredict(cvBag);
                    accBag = mean(predBag == Y);

                    if accBag > bagBestAcc
                        bagBestAcc = accBag;
                        bagBestPred = predBag;
                        bagBestDetails = sprintf("Cycles=%d, MinLeaf=%d, MaxSplits=%d", ...
                            nCycles, minLeaf, maxSplits);
                    end
                catch
                end
            end
        end
    end

    fprintf("Best Bagged Trees accuracy: %.2f %% (%s)\n", ...
        100*bagBestAcc, bagBestDetails);

    if bagBestAcc > bestAcc
        bestAcc = bagBestAcc;
        bestName = "OptimizedBaggedTrees";
        bestPred = bagBestPred;
        bestDetails = bagBestDetails;
    end

    fprintf("\nBest for %s:\n", rt);
    fprintf("  Model    : %s\n", bestName);
    fprintf("  Accuracy : %.2f %%\n", 100*bestAcc);
    fprintf("  Details  : %s\n", bestDetails);

    temp = table( ...
        string(rt), ...
        numel(Y), ...
        100*accTree, ...
        100*knnBestAcc, ...
        string(knnBestDetails), ...
        100*bagBestAcc, ...
        string(bagBestDetails), ...
        string(bestName), ...
        string(bestDetails), ...
        100*bestAcc, ...
        'VariableNames', { ...
            'ResponseType', ...
            'NumSamples', ...
            'FineTreeAccuracy', ...
            'BestKNNAccuracy', ...
            'BestKNNDetails', ...
            'BestBaggedTreesAccuracy', ...
            'BestBaggedTreesDetails', ...
            'BestModel', ...
            'BestModelDetails', ...
            'BestAccuracy' ...
        });

    results = [results; temp];

    allTrueStr = [allTrueStr; string(Y)];
    allPredStr = [allPredStr; string(bestPred)];
end

allTrue = categorical(allTrueStr);
allPred = categorical(allPredStr);

overallAcc = mean(allPred == allTrue);

fprintf("\n=====================================================\n");
fprintf("V8 Overall final hierarchical accuracy: %.2f %%\n", 100*overallAcc);
fprintf("=====================================================\n\n");

disp(results);

resultsFolder = fullfile(base, '3_results');
figFolder = fullfile(base, '4_figures');

if ~exist(resultsFolder, 'dir'), mkdir(resultsFolder); end
if ~exist(figFolder, 'dir'), mkdir(figFolder); end

resultFile = fullfile(resultsFolder, 'v8_final_hierarchical_results.csv');
writetable(results, resultFile);

fig = figure;
cm = confusionchart(allTrue, allPred);
cm.Title = sprintf('V8 Final Component-Derived Classifier, Accuracy = %.2f%%', ...
    100*overallAcc);
cm.RowSummary = 'row-normalized';
cm.ColumnSummary = 'column-normalized';

figFile = fullfile(figFolder, 'v8_final_hierarchical_confusion_matrix.png');
saveas(fig, figFile);

fprintf("Saved results:\n%s\n", resultFile);
fprintf("Saved confusion matrix:\n%s\n", figFile);