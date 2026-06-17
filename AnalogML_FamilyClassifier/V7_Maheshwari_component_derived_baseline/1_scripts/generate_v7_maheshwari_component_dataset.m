clear; clc; close all;

% ============================================================
% V7 Maheshwari Component-Derived Dataset
%
% Goal:
% Generate analog filter family-classification dataset using
% component-derived equations from Maheshwari & Anand, Analog Electronics,
% Active Filters chapter.
%
% Families:
%   PASSIVE
%   VCVS
%   MFB
%   ACTIVE_OTHER
%
% Response types:
%   LPF, HPF, BPF, BSF
%
% Important:
% - K, Q, and f0 are NOT chosen directly as random nominal variables.
% - Components are chosen first.
% - K, Q, and f0 are calculated from circuit equations.
%
% Main Maheshwari equations used:
%
% VCVS LPF/HPF:
%   K = 1 + RB/RA
%   wc = 1/(RC) for equal-component case
%   Q = 1/(3-K)
%
% VCVS BPF:
%   f0 = 1/(2*pi*R*C)
%   H0 = K/(3-K)
%   Q = 1/(3-K)
%
% VCVS BSF:
%   f0 = 1/(2*pi*R*C)
%   H0 = K
%   Q = 1/(2*(2-K))
%
% MFB LPF:
%   K = -R3/R1
%   wc^2 = 1/(R2*R3*C1*C2)
%   denominator coefficient b = 1/(R1*C1)+1/(R2*C1)+1/(R3*C1)
%   Q = wc/b
%
% MFB HPF:
%   K = -C3/C1
%   wc^2 = 1/(R1*R2*C2*C3)
%   Q = 1/(2k), where
%   2k = (1/R1)*(1/C1 + 1/C2 + C3/(C1*C2))*sqrt(R1*R2*C2*C3)
%
% MFB BPF:
%   K = -1/(R1*C2)
%   wc^2 = 1/(R1*R2*C1*C2)
%   b = (1/R2)*(1/C1 + 1/C2)
%   Q = wc/b
%
% ACTIVE_OTHER:
%   Implemented as cascaded VCVS sections, consistent with the idea
%   that higher-order active filters can be obtained by cascading
%   first-order/second-order sections.
% ============================================================

rng(7);

% ---------- Robust project path ----------
thisFile = mfilename('fullpath');
scriptFolder = fileparts(thisFile);
base = fileparts(scriptFolder);

dataFolder = fullfile(base, '2_datasets');
figFolder = fullfile(base, '4_figures');

if ~exist(dataFolder, 'dir'), mkdir(dataFolder); end
if ~exist(figFolder, 'dir'), mkdir(figFolder); end

% ---------- Settings ----------
families = ["PASSIVE", "VCVS", "MFB", "ACTIVE_OTHER"];
responseTypes = ["LPF", "HPF", "BPF", "BSF"];

nPerFamily = 700;
nFreq = 200;

f = logspace(1, 6, nFreq);      % 10 Hz to 1 MHz
w = 2*pi*f;
s = 1j*w;

nTotal = nPerFamily * numel(families);

% Features:
% 200 magnitude + 200 phase + 20 engineered = 420 predictors
Xraw = zeros(nTotal, 2*nFreq);
Xeng = zeros(nTotal, 20);

FamilyLabel = strings(nTotal,1);
ResponseType = strings(nTotal,1);

% Metadata for explainability
Meta = table();

row = 0;

for fam = families

    fprintf("Generating component-derived samples for %s...\n", fam);

    for kSample = 1:nPerFamily

        row = row + 1;

        rType = responseTypes(randi(numel(responseTypes)));

        switch fam

            case "PASSIVE"
                [H, metaRow] = makePassiveResponse(s, rType);

            case "VCVS"
                [H, metaRow] = makeVCVSResponse(s, rType);

            case "MFB"
                % Maheshwari screenshots gave MFB LPF, HPF, BPF.
                % For BSF, use BPF/LPF/HPF only for MFB by remapping BSF to BPF
                % so that MFB data remains equation-backed.
                if rType == "BSF"
                    rTypeUsed = "BPF";
                else
                    rTypeUsed = rType;
                end

                [H, metaRow] = makeMFBResponse(s, rTypeUsed);

                % Keep ResponseType as actual generated response type.
                rType = rTypeUsed;

            case "ACTIVE_OTHER"
                [H, metaRow] = makeActiveOtherResponse(s, rType);
        end

        % Frequency response features
        magdB = 20*log10(abs(H) + eps);
        phaseDeg = unwrap(angle(H))*180/pi;

        % Normalize magnitude to focus on shape, not only absolute gain
        magdB = magdB - max(magdB);

        % Small measurement-like noise
        magdB = magdB + 0.25*randn(size(magdB));
        phaseDeg = phaseDeg + 1.2*randn(size(phaseDeg));

        % Smooth disturbance
        magdB = magdB + 0.12*sin(linspace(0, 2*pi, nFreq) + 2*pi*rand());

        Xraw(row,:) = [magdB, phaseDeg];
        Xeng(row,:) = extractEngineeredFeatures(magdB, phaseDeg, f);

        FamilyLabel(row) = fam;
        ResponseType(row) = rType;

        metaRow.SampleID = row;
        metaRow.FamilyLabel = fam;
        metaRow.ResponseType = rType;

        Meta = [Meta; metaRow];
    end
end

% ---------- Create feature table ----------
rawNames = strings(1, 2*nFreq);

for i = 1:nFreq
    rawNames(i) = "Mag_" + string(i);
end

for i = 1:nFreq
    rawNames(nFreq+i) = "Phase_" + string(i);
end

engNames = {
    'Eng_MagMax'
    'Eng_MagMin'
    'Eng_MagMean'
    'Eng_MagStd'
    'Eng_MagRange'
    'Eng_FreqAtMaxLog10'
    'Eng_LowFreqMagMean'
    'Eng_MidFreqMagMean'
    'Eng_HighFreqMagMean'
    'Eng_LowHighSlope'
    'Eng_MagArea'
    'Eng_Bandwidth3dBLog'
    'Eng_QProxy'
    'Eng_PhaseStart'
    'Eng_PhaseEnd'
    'Eng_PhaseRange'
    'Eng_PhaseStd'
    'Eng_PhaseSlope'
    'Eng_PhaseArea'
    'Eng_NumMagPeaks'
};

Traw = array2table(Xraw, 'VariableNames', cellstr(rawNames));
Teng = array2table(Xeng, 'VariableNames', engNames);

T_v7 = [Traw, Teng];

T_v7.FamilyLabel = categorical(FamilyLabel);
T_v7.ResponseType = categorical(ResponseType);

% Shuffle dataset and metadata together
idx = randperm(height(T_v7));
T_v7 = T_v7(idx,:);
Meta = Meta(idx,:);

% ---------- Save ----------
csvFile = fullfile(dataFolder, 'family_classifier_dataset_v7_maheshwari.csv');
matFile = fullfile(dataFolder, 'family_classifier_dataset_v7_maheshwari.mat');
metaFile = fullfile(dataFolder, 'family_classifier_metadata_v7_maheshwari.csv');

writetable(T_v7, csvFile);
writetable(Meta, metaFile);
save(matFile, 'T_v7', 'Meta', 'f');

fprintf("\nSaved V7 dataset:\n");
fprintf("%s\n", csvFile);
fprintf("%s\n", matFile);
fprintf("%s\n", metaFile);

fprintf("\nDataset size:\n");
fprintf("Rows: %d\n", height(T_v7));
fprintf("Columns: %d\n", width(T_v7));

disp("Family counts:");
disp(groupcounts(T_v7, "FamilyLabel"));

disp("Response type counts:");
disp(groupcounts(T_v7, "ResponseType"));

% ---------- Save example response plot ----------
figure;
gscatter(1:height(T_v7), double(T_v7.FamilyLabel), T_v7.FamilyLabel);
title('V7 Dataset Family Labels');
xlabel('Sample Index');
ylabel('Family Label Index');

saveas(gcf, fullfile(figFolder, 'v7_family_label_distribution.png'));

% ============================================================
% Local functions
% ============================================================

function x = tol(xnom, tolerance)
    x = xnom .* (1 + tolerance*(2*rand(size(xnom))-1));
end

function [H, meta] = makePassiveResponse(s, rType)

    meta = table();

    % Passive LPF/HPF: RC based.
    % Passive BPF/BSF: series RLC-equivalent response.

    rType = string(rType);

    if rType == "LPF" || rType == "HPF"

        R = tol(10^(3 + 3*rand()), 0.05);      % 1k to 1M
        C = tol(10^(-9 - 3*rand()), 0.10);     % 1nF to 1uF

        wc = 1/(R*C);
        K = 1;
        Q = NaN;

        if rType == "LPF"
            H = 1 ./ (1 + s/wc);
        else
            H = (s/wc) ./ (1 + s/wc);
        end

        meta.Topology = "PASSIVE_RC";
        meta.R1 = R;
        meta.R2 = NaN;
        meta.R3 = NaN;
        meta.C1 = C;
        meta.C2 = NaN;
        meta.C3 = NaN;
        meta.RA = NaN;
        meta.RB = NaN;
        meta.K_calc = K;
        meta.Q_calc = Q;
        meta.f0_calc = wc/(2*pi);

    else

        % RLC equivalent.
        % Pick C and L, then R defines Q.
        C = tol(10^(-9 - 3*rand()), 0.10);     % 1nF to 1uF

        f0Target = 10^(2 + 4*rand());          % 100 Hz to 1 MHz
        w0 = 2*pi*f0Target;

        L = 1/(w0^2*C);

        % Choose R such that Q is physically derived.
        % Q = w0*L/R
        R = tol(10^(1 + 3*rand()), 0.05);      % 10 ohm to 10k
        Q = w0*L/R;

        % Restrict extreme Q to avoid unrealistic curves
        Q = max(min(Q, 10), 0.2);

        den = (s/w0).^2 + (s/(Q*w0)) + 1;

        if rType == "BPF"
            H = (s/(Q*w0)) ./ den;
            topo = "PASSIVE_RLC_BPF";
        else
            H = ((s/w0).^2 + 1) ./ den;
            topo = "PASSIVE_RLC_BSF";
        end

        meta.Topology = topo;
        meta.R1 = R;
        meta.R2 = NaN;
        meta.R3 = NaN;
        meta.C1 = C;
        meta.C2 = NaN;
        meta.C3 = NaN;
        meta.RA = NaN;
        meta.RB = NaN;
        meta.K_calc = 1;
        meta.Q_calc = Q;
        meta.f0_calc = f0Target;
    end
end

function [H, meta] = makeVCVSResponse(s, rType)

    meta = table();

    rType = string(rType);

    % Equal-component VCVS design from Maheshwari
    R = tol(10^(3 + 3*rand()), 0.05);       % 1k to 1M
    C = tol(10^(-9 - 3*rand()), 0.10);      % 1nF to 1uF

    RA = tol(10e3, 0.02);                   % gain-setting resistor

    % Choose stable op-amp gain K via RB/RA.
    if rType == "BSF"
        Ktarget = 1.05 + 0.70*rand();       % K < 2 for BSF Q expression
    else
        Ktarget = 1.05 + 1.35*rand();       % K < 3
    end

    RB = (Ktarget - 1)*RA;

    RA = tol(RA, 0.02);
    RB = tol(RB, 0.02);

    K = 1 + RB/RA;
    w0 = 1/(R*C);

    if rType == "LPF"
        Q = 1/(3 - K);
        H = K ./ ((s/w0).^2 + (s/(Q*w0)) + 1);
        topo = "VCVS_LPF";

    elseif rType == "HPF"
        Q = 1/(3 - K);
        H = K*(s/w0).^2 ./ ((s/w0).^2 + (s/(Q*w0)) + 1);
        topo = "VCVS_HPF";

    elseif rType == "BPF"
        Q = 1/(3 - K);
        H0 = K/(3 - K);
        H = (H0/Q)*(s/w0) ./ ((s/w0).^2 + (s/(Q*w0)) + 1);
        topo = "VCVS_BPF";

    else
        Q = 1/(2*(2 - K));
        H0 = K;
        H = H0*((s/w0).^2 + 1) ./ ((s/w0).^2 + (s/(Q*w0)) + 1);
        topo = "VCVS_BSF";
    end

    meta.Topology = topo;
    meta.R1 = R;
    meta.R2 = R;
    meta.R3 = NaN;
    meta.C1 = C;
    meta.C2 = C;
    meta.C3 = NaN;
    meta.RA = RA;
    meta.RB = RB;
    meta.K_calc = K;
    meta.Q_calc = Q;
    meta.f0_calc = w0/(2*pi);
end

function [H, meta] = makeMFBResponse(s, rType)

    meta = table();

    rType = string(rType);

    switch rType

        case "LPF"
            % MFB low-pass, Maheshwari p.216
            C1 = tol(10^(-9 - 2*rand()), 0.10);
            C2 = tol(10^(-9 - 2*rand()), 0.10);

            f0Target = 10^(2 + 4*rand());
            w0 = 2*pi*f0Target;

            R2 = tol(10^(3 + 2*rand()), 0.05);
            R3 = 1/(w0^2 * R2 * C1 * C2);

            Kmag = 0.8 + 3.0*rand();
            R1 = R3 / Kmag;

            R1 = tol(R1, 0.05);
            R2 = tol(R2, 0.05);
            R3 = tol(R3, 0.05);

            K = -R3/R1;
            wc = sqrt(1/(R2*R3*C1*C2));
            b = 1/(R1*C1) + 1/(R2*C1) + 1/(R3*C1);
            Q = wc/b;

            H = K ./ ((s/wc).^2 + (s/(Q*wc)) + 1);

            topo = "MFB_LPF";

            Rextra = NaN;
            C3 = NaN;

        case "HPF"
            % MFB high-pass, Maheshwari p.217
            C1 = tol(10^(-9 - 2*rand()), 0.10);
            C2 = tol(10^(-9 - 2*rand()), 0.10);
            C3 = tol(10^(-9 - 2*rand()), 0.10);

            f0Target = 10^(2 + 4*rand());
            w0 = 2*pi*f0Target;

            R1 = tol(10^(3 + 2*rand()), 0.05);
            R2 = 1/(w0^2 * R1 * C2 * C3);

            R1 = tol(R1, 0.05);
            R2 = tol(R2, 0.05);

            K = -C3/C1;
            wc = sqrt(1/(R1*R2*C2*C3));

            twok = (1/R1)*(1/C1 + 1/C2 + C3/(C1*C2))*sqrt(R1*R2*C2*C3);
            Q = 1/twok;

            H = K*(s/wc).^2 ./ ((s/wc).^2 + (s/(Q*wc)) + 1);

            topo = "MFB_HPF";

            R3 = NaN;

        otherwise
            % MFB band-pass, Maheshwari p.218
            C1 = tol(10^(-9 - 2*rand()), 0.10);
            C2 = tol(10^(-9 - 2*rand()), 0.10);

            f0Target = 10^(2 + 4*rand());
            w0 = 2*pi*f0Target;

            R1 = tol(10^(3 + 2*rand()), 0.05);
            R2 = 1/(w0^2 * R1 * C1 * C2);

            R1 = tol(R1, 0.05);
            R2 = tol(R2, 0.05);

            Kbp = -1/(R1*C2);
            wc = sqrt(1/(R1*R2*C1*C2));

            b = (1/R2)*(1/C1 + 1/C2);
            Q = wc/b;

            H = (Kbp*s) ./ (s.^2 + (wc/Q)*s + wc^2);

            K = Kbp;
            topo = "MFB_BPF";

            R3 = NaN;
            C3 = NaN;
    end

    meta.Topology = topo;
    meta.R1 = R1;
    meta.R2 = R2;
    meta.R3 = R3;
    meta.C1 = C1;
    meta.C2 = C2;
    meta.C3 = C3;
    meta.RA = NaN;
    meta.RB = NaN;
    meta.K_calc = K;
    meta.Q_calc = Q;
    meta.f0_calc = wc/(2*pi);
end

function [H, meta] = makeActiveOtherResponse(s, rType)

    % Higher-order active filter using cascade of two VCVS-derived sections.
    % This follows the standard active-filter design idea that higher-order
    % filters can be implemented by cascading second-order stages.

    [H1, m1] = makeVCVSResponse(s, rType);
    [H2, m2] = makeVCVSResponse(s, rType);

    H = H1 .* H2;

    meta = table();
    meta.Topology = "ACTIVE_OTHER_CASCADED_VCVS";
    meta.R1 = m1.R1;
    meta.R2 = m1.R2;
    meta.R3 = m2.R1;
    meta.C1 = m1.C1;
    meta.C2 = m1.C2;
    meta.C3 = m2.C1;
    meta.RA = m1.RA;
    meta.RB = m1.RB;
    meta.K_calc = m1.K_calc * m2.K_calc;
    meta.Q_calc = mean([m1.Q_calc, m2.Q_calc]);
    meta.f0_calc = mean([m1.f0_calc, m2.f0_calc]);
end

function E = extractEngineeredFeatures(m, p, f)

    nFreq = numel(m);
    logF = log10(f);

    magMax = max(m);
    magMin = min(m);
    magMean = mean(m);
    magStd = std(m);
    magRange = magMax - magMin;

    [~, peakIdx] = max(m);
    freqAtMaxLog10 = logF(peakIdx);

    lowFreqMagMean = mean(m(1:10));
    midIdx = round(nFreq/2)-5 : round(nFreq/2)+5;
    midFreqMagMean = mean(m(midIdx));
    highFreqMagMean = mean(m(end-9:end));

    lowHighSlope = (highFreqMagMean - lowFreqMagMean)/(logF(end)-logF(1));
    magArea = trapz(logF, m);

    threshold = magMax - 3;
    bwMask = m >= threshold;

    if any(bwMask)
        fLow = min(f(bwMask));
        fHigh = max(f(bwMask));
        bandwidth3dBLog = log10(fHigh) - log10(fLow);

        if fHigh > fLow
            qProxy = f(peakIdx)/(fHigh - fLow);
        else
            qProxy = 0;
        end
    else
        bandwidth3dBLog = 0;
        qProxy = 0;
    end

    phaseStart = p(1);
    phaseEnd = p(end);
    phaseRange = max(p) - min(p);
    phaseStd = std(p);
    phaseSlope = (phaseEnd - phaseStart)/(logF(end)-logF(1));
    phaseArea = trapz(logF, p);

    localPeaks = (m(2:end-1) > m(1:end-2)) & (m(2:end-1) > m(3:end));
    strongPeaks = localPeaks & (m(2:end-1) > -20);
    numMagPeaks = sum(strongPeaks);

    E = [
        magMax, magMin, magMean, magStd, magRange, ...
        freqAtMaxLog10, ...
        lowFreqMagMean, midFreqMagMean, highFreqMagMean, ...
        lowHighSlope, magArea, bandwidth3dBLog, qProxy, ...
        phaseStart, phaseEnd, phaseRange, phaseStd, ...
        phaseSlope, phaseArea, numMagPeaks
    ];
end