clear; clc; close all;

% ============================================================
% V8 Final Component-Derived Dataset
%
% Families:
% PASSIVE / VCVS / MFB / ACTIVE_OTHER
%
% Response types:
% LPF / HPF / BPF / BSF
%
% Improvements over V7:
% 1. Balanced 4 x 4 family-response dataset.
% 2. MFB BSF included using valid 1-BP notch construction.
% 3. VCVS and MFB equations are component-derived.
% 4. Metadata saves component values and K/Q/f0 calculations separately.
% 5. Metadata is NOT used as ML predictor.
% ============================================================

rng(8);

thisFile = mfilename('fullpath');
scriptFolder = fileparts(thisFile);
base = fileparts(scriptFolder);

dataFolder = fullfile(base, '2_datasets');
figFolder = fullfile(base, '4_figures');
if ~exist(dataFolder, 'dir'), mkdir(dataFolder); end
if ~exist(figFolder, 'dir'), mkdir(figFolder); end

families = ["PASSIVE", "VCVS", "MFB", "ACTIVE_OTHER"];
responseTypes = ["LPF", "HPF", "BPF", "BSF"];

nPerCombo = 200;      % balanced: 4 families x 4 responses x 200 = 3200
nFreq = 200;

f = logspace(1, 6, nFreq);
w = 2*pi*f;
s = 1j*w;

nTotal = numel(families) * numel(responseTypes) * nPerCombo;

Xraw = zeros(nTotal, 2*nFreq);
Xeng = zeros(nTotal, 20);

FamilyLabel = strings(nTotal,1);
ResponseType = strings(nTotal,1);

MetaSampleID = zeros(nTotal,1);
MetaFamily = strings(nTotal,1);
MetaResponse = strings(nTotal,1);
MetaTopology = strings(nTotal,1);
MetaSource = strings(nTotal,1);
MetaR1 = nan(nTotal,1);
MetaR2 = nan(nTotal,1);
MetaR3 = nan(nTotal,1);
MetaC1 = nan(nTotal,1);
MetaC2 = nan(nTotal,1);
MetaC3 = nan(nTotal,1);
MetaL1 = nan(nTotal,1);
MetaRA = nan(nTotal,1);
MetaRB = nan(nTotal,1);
MetaK = nan(nTotal,1);
MetaQ = nan(nTotal,1);
MetaF0 = nan(nTotal,1);

row = 0;

for fam = families
    for rType = responseTypes

        fprintf("Generating %s - %s...\n", fam, rType);

        for kSample = 1:nPerCombo
            row = row + 1;

            switch fam
                case "PASSIVE"
                    [H, meta] = makePassiveResponse(s, rType);

                case "VCVS"
                    [H, meta] = makeVCVSResponse(s, rType);

                case "MFB"
                    [H, meta] = makeMFBResponse(s, rType);

                case "ACTIVE_OTHER"
                    [H, meta] = makeActiveOtherResponse(s, rType);
            end

            magdB = 20*log10(abs(H) + eps);
            phaseDeg = unwrap(angle(H))*180/pi;

            magdB = magdB - max(magdB);
            magdB = magdB + 0.20*randn(size(magdB));
            phaseDeg = phaseDeg + 1.0*randn(size(phaseDeg));
            magdB = magdB + 0.10*sin(linspace(0, 2*pi, nFreq) + 2*pi*rand());

            Xraw(row,:) = [magdB, phaseDeg];
            Xeng(row,:) = extractEngineeredFeatures(magdB, phaseDeg, f);

            FamilyLabel(row) = fam;
            ResponseType(row) = rType;

            MetaSampleID(row) = row;
            MetaFamily(row) = fam;
            MetaResponse(row) = rType;
            MetaTopology(row) = meta.Topology;
            MetaSource(row) = meta.Source;
            MetaR1(row) = meta.R1;
            MetaR2(row) = meta.R2;
            MetaR3(row) = meta.R3;
            MetaC1(row) = meta.C1;
            MetaC2(row) = meta.C2;
            MetaC3(row) = meta.C3;
            MetaL1(row) = meta.L1;
            MetaRA(row) = meta.RA;
            MetaRB(row) = meta.RB;
            MetaK(row) = meta.K_calc;
            MetaQ(row) = meta.Q_calc;
            MetaF0(row) = meta.f0_calc;
        end
    end
end

rawNames = strings(1, 2*nFreq);
for i = 1:nFreq
    rawNames(i) = "Mag_" + string(i);
end
for i = 1:nFreq
    rawNames(nFreq+i) = "Phase_" + string(i);
end

engNames = {
    'Eng_MagMax','Eng_MagMin','Eng_MagMean','Eng_MagStd','Eng_MagRange', ...
    'Eng_FreqAtMaxLog10','Eng_LowFreqMagMean','Eng_MidFreqMagMean', ...
    'Eng_HighFreqMagMean','Eng_LowHighSlope','Eng_MagArea', ...
    'Eng_Bandwidth3dBLog','Eng_QProxy','Eng_PhaseStart','Eng_PhaseEnd', ...
    'Eng_PhaseRange','Eng_PhaseStd','Eng_PhaseSlope','Eng_PhaseArea', ...
    'Eng_NumMagPeaks'
};

Traw = array2table(Xraw, 'VariableNames', cellstr(rawNames));
Teng = array2table(Xeng, 'VariableNames', engNames);

T_v8 = [Traw, Teng];
T_v8.FamilyLabel = categorical(FamilyLabel);
T_v8.ResponseType = categorical(ResponseType);

Meta = table( ...
    MetaSampleID, MetaFamily, MetaResponse, MetaTopology, MetaSource, ...
    MetaR1, MetaR2, MetaR3, MetaC1, MetaC2, MetaC3, MetaL1, ...
    MetaRA, MetaRB, MetaK, MetaQ, MetaF0, ...
    'VariableNames', { ...
        'SampleID','FamilyLabel','ResponseType','Topology','EquationSource', ...
        'R1','R2','R3','C1','C2','C3','L1','RA','RB','K_calc','Q_calc','f0_calc' ...
    });

idx = randperm(height(T_v8));
T_v8 = T_v8(idx,:);
Meta = Meta(idx,:);

csvFile = fullfile(dataFolder, 'family_classifier_dataset_v8_final.csv');
matFile = fullfile(dataFolder, 'family_classifier_dataset_v8_final.mat');
metaFile = fullfile(dataFolder, 'family_classifier_metadata_v8_final.csv');

writetable(T_v8, csvFile);
writetable(Meta, metaFile);
save(matFile, 'T_v8', 'Meta', 'f');

fprintf("\nSaved V8 dataset:\n");
fprintf("%s\n", csvFile);
fprintf("%s\n", matFile);
fprintf("%s\n", metaFile);

fprintf("\nRows: %d\n", height(T_v8));
fprintf("Columns: %d\n", width(T_v8));

disp("Family counts:");
disp(groupcounts(T_v8, "FamilyLabel"));

disp("Response type counts:");
disp(groupcounts(T_v8, "ResponseType"));

% ============================================================
% Local functions
% ============================================================

function x = tol(xnom, tolerance)
    x = xnom .* (1 + tolerance*(2*rand(size(xnom))-1));
end

function y = clamp(x, lo, hi)
    y = min(max(x, lo), hi);
end

function meta = blankMeta()
    meta.Topology = "";
    meta.Source = "";
    meta.R1 = NaN;
    meta.R2 = NaN;
    meta.R3 = NaN;
    meta.C1 = NaN;
    meta.C2 = NaN;
    meta.C3 = NaN;
    meta.L1 = NaN;
    meta.RA = NaN;
    meta.RB = NaN;
    meta.K_calc = NaN;
    meta.Q_calc = NaN;
    meta.f0_calc = NaN;
end

function [H, meta] = makePassiveResponse(s, rType)

    meta = blankMeta();
    rType = string(rType);

    if rType == "LPF" || rType == "HPF"
        R = tol(10^(3 + 3*rand()), 0.05);
        C = tol(10^(-9 - 3*rand()), 0.10);

        wc = 1/(R*C);

        if rType == "LPF"
            H = 1 ./ (1 + s/wc);
            topo = "PASSIVE_RC_LPF";
        else
            H = (s/wc) ./ (1 + s/wc);
            topo = "PASSIVE_RC_HPF";
        end

        meta.Topology = topo;
        meta.Source = "Passive RC first-order equation";
        meta.R1 = R;
        meta.C1 = C;
        meta.K_calc = 1;
        meta.Q_calc = NaN;
        meta.f0_calc = wc/(2*pi);

    else
        C = tol(10^(-9 - 3*rand()), 0.10);
        f0Target = 10^(2 + 4*rand());
        w0 = 2*pi*f0Target;

        L = 1/(w0^2*C);
        Qdes = 0.5 + 5*rand();
        R = w0*L/Qdes;

        R = tol(R, 0.05);
        C = tol(C, 0.10);
        L = tol(L, 0.10);

        w0 = 1/sqrt(L*C);
        Q = clamp(w0*L/R, 0.2, 20);

        den = (s/w0).^2 + (s/(Q*w0)) + 1;

        if rType == "BPF"
            H = (s/(Q*w0)) ./ den;
            topo = "PASSIVE_RLC_BPF";
        else
            H = ((s/w0).^2 + 1) ./ den;
            topo = "PASSIVE_RLC_BSF";
        end

        meta.Topology = topo;
        meta.Source = "Passive RLC second-order equation";
        meta.R1 = R;
        meta.C1 = C;
        meta.L1 = L;
        meta.K_calc = 1;
        meta.Q_calc = Q;
        meta.f0_calc = w0/(2*pi);
    end
end

function [H, meta] = makeVCVSResponse(s, rType)

    meta = blankMeta();
    rType = string(rType);

    R = tol(10^(3 + 3*rand()), 0.05);
    C = tol(10^(-9 - 3*rand()), 0.10);

    RA = tol(10e3, 0.02);

    if rType == "BSF"
        Ktarget = 1.05 + 0.70*rand();     % K < 2
    else
        Ktarget = 1.05 + 1.35*rand();     % K < 3
    end

    RB = tol((Ktarget - 1)*RA, 0.02);
    K = 1 + RB/RA;

    w0 = 1/(R*C);

    if rType == "LPF"
        Q = 1/(3 - K);
        H = K ./ ((s/w0).^2 + (s/(Q*w0)) + 1);
        topo = "VCVS_LPF_Maheshwari";

    elseif rType == "HPF"
        Q = 1/(3 - K);
        H = K*(s/w0).^2 ./ ((s/w0).^2 + (s/(Q*w0)) + 1);
        topo = "VCVS_HPF_Maheshwari";

    elseif rType == "BPF"
        Q = 1/(3 - K);
        H0 = K/(3 - K);
        H = (H0/Q)*(s/w0) ./ ((s/w0).^2 + (s/(Q*w0)) + 1);
        topo = "VCVS_BPF_Maheshwari";

    else
        Q = 1/(2*(2 - K));
        H = K*((s/w0).^2 + 1) ./ ((s/w0).^2 + (s/(Q*w0)) + 1);
        topo = "VCVS_BSF_Maheshwari";
    end

    meta.Topology = topo;
    meta.Source = "Maheshwari VCVS equal-component active-filter equations";
    meta.R1 = R;
    meta.R2 = R;
    meta.C1 = C;
    meta.C2 = C;
    meta.RA = RA;
    meta.RB = RB;
    meta.K_calc = K;
    meta.Q_calc = Q;
    meta.f0_calc = w0/(2*pi);
end

function [H, meta] = makeMFBResponse(s, rType)

    meta = blankMeta();
    rType = string(rType);

    switch rType

        case "LPF"
            for attempt = 1:100
                C1 = tol(10^(-9 - 2*rand()), 0.10);
                C2 = tol(10^(-9 - 2*rand()), 0.10);
                f0Target = 10^(2 + 4*rand());
                w0 = 2*pi*f0Target;

                R3 = 10^(3 + 3*rand());
                R2 = 1/(w0^2 * R3 * C1 * C2);
                Kmag = 0.8 + 3.0*rand();
                R1 = R3/Kmag;

                R1 = tol(R1,0.05); R2 = tol(R2,0.05); R3 = tol(R3,0.05);

                wc = sqrt(1/(R2*R3*C1*C2));
                b = 1/(R1*C1) + 1/(R2*C1) + 1/(R3*C1);
                Q = wc/b;

                if isfinite(Q) && Q > 0.15 && Q < 20 && R1 > 10 && R2 > 10 && R3 > 10
                    break;
                end
            end

            K = -R3/R1;
            H = K ./ ((s/wc).^2 + (s/(Q*wc)) + 1);

            topo = "MFB_LPF_Maheshwari";
            C3 = NaN;

        case "HPF"
            for attempt = 1:100
                C1 = tol(10^(-9 - 2*rand()), 0.10);
                C2 = tol(10^(-9 - 2*rand()), 0.10);
                C3 = tol(10^(-9 - 2*rand()), 0.10);
                f0Target = 10^(2 + 4*rand());
                w0 = 2*pi*f0Target;

                R1 = 10^(3 + 3*rand());
                R2 = 1/(w0^2 * R1 * C2 * C3);

                R1 = tol(R1,0.05); R2 = tol(R2,0.05);

                wc = sqrt(1/(R1*R2*C2*C3));
                twok = (1/R1)*(1/C1 + 1/C2 + C3/(C1*C2))*sqrt(R1*R2*C2*C3);
                Q = 1/twok;

                if isfinite(Q) && Q > 0.15 && Q < 20 && R1 > 10 && R2 > 10
                    break;
                end
            end

            K = -C3/C1;
            H = K*(s/wc).^2 ./ ((s/wc).^2 + (s/(Q*wc)) + 1);

            topo = "MFB_HPF_Maheshwari";
            R3 = NaN;

        case {"BPF","BSF"}
            for attempt = 1:100
                C1 = tol(10^(-9 - 2*rand()), 0.10);
                C2 = tol(10^(-9 - 2*rand()), 0.10);
                f0Target = 10^(2 + 4*rand());
                w0 = 2*pi*f0Target;

                Qdes = 0.5 + 6*rand();
                R2 = Qdes*(1/C1 + 1/C2)/w0;
                R1 = 1/(w0^2 * R2 * C1 * C2);

                R1 = tol(R1,0.05); R2 = tol(R2,0.05);

                wc = sqrt(1/(R1*R2*C1*C2));
                b = (1/R2)*(1/C1 + 1/C2);
                Q = wc/b;

                if isfinite(Q) && Q > 0.15 && Q < 20 && R1 > 10 && R2 > 10
                    break;
                end
            end

            if rType == "BPF"
                K = -1/(R1*C2);
                H = (K*s) ./ (s.^2 + (wc/Q)*s + wc^2);
                topo = "MFB_BPF_Maheshwari";
            else
                K = 1;
                H = (s.^2 + wc^2) ./ (s.^2 + (wc/Q)*s + wc^2);
                topo = "MFB_BSF_1_MINUS_BP";
            end

            R3 = NaN;
            C3 = NaN;

        otherwise
            error("Unknown MFB response type");
    end

    meta.Topology = topo;
    if rType == "BSF"
        meta.Source = "Maheshwari MFB BPF denominator + ADI 1-minus-BP notch construction";
    else
        meta.Source = "Maheshwari MFB active-filter equations";
    end
    meta.R1 = R1;
    meta.R2 = R2;
    meta.R3 = R3;
    meta.C1 = C1;
    meta.C2 = C2;
    meta.C3 = C3;
    meta.K_calc = K;
    meta.Q_calc = Q;
    meta.f0_calc = wc/(2*pi);
end

function [H, meta] = makeActiveOtherResponse(s, rType)

    meta = blankMeta();
    rType = string(rType);

    % State-variable / biquad-like active-other model.
    % Parameters are component-derived from tunable RC and resistor ratios.

    R4 = tol(10^(3 + 3*rand()), 0.05);
    R5 = tol(10^(3 + 3*rand()), 0.05);
    C1 = tol(10^(-9 - 3*rand()), 0.10);
    C2 = tol(10^(-9 - 3*rand()), 0.10);

    w0 = 1/sqrt(R4*R5*C1*C2);

    Rq = tol(10e3*(0.5 + 5*rand()), 0.05);
    Rd = tol(10e3, 0.05);
    Q = clamp(Rq/Rd, 0.25, 10);

    Rg = tol(10e3, 0.05);
    Rf = tol(10e3*(0.5 + 3*rand()), 0.05);
    K = 1 + Rf/Rg;

    den = (s/w0).^2 + (s/(Q*w0)) + 1;

    if rType == "LPF"
        H = K ./ den;
        topo = "ACTIVE_OTHER_STATE_VARIABLE_LPF";
    elseif rType == "HPF"
        H = K*(s/w0).^2 ./ den;
        topo = "ACTIVE_OTHER_STATE_VARIABLE_HPF";
    elseif rType == "BPF"
        H = K*(s/(Q*w0)) ./ den;
        topo = "ACTIVE_OTHER_STATE_VARIABLE_BPF";
    else
        H = K*((s/w0).^2 + 1) ./ den;
        topo = "ACTIVE_OTHER_STATE_VARIABLE_BSF";
    end

    meta.Topology = topo;
    meta.Source = "External state-variable/biquad active-filter canonical equation";
    meta.R1 = R4;
    meta.R2 = R5;
    meta.R3 = Rq;
    meta.C1 = C1;
    meta.C2 = C2;
    meta.RA = Rg;
    meta.RB = Rf;
    meta.K_calc = K;
    meta.Q_calc = Q;
    meta.f0_calc = w0/(2*pi);
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
        freqAtMaxLog10, lowFreqMagMean, midFreqMagMean, highFreqMagMean, ...
        lowHighSlope, magArea, bandwidth3dBLog, qProxy, ...
        phaseStart, phaseEnd, phaseRange, phaseStd, ...
        phaseSlope, phaseArea, numMagPeaks
    ];
end