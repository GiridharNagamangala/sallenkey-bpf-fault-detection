%% Monte Carlo Analysis Script for Circuit (Final Integrated Version with I_supply Placeholder)
% Clear workspace and command window
clear; clc;

%% 1. User Inputs
f_low = input('Enter lower cutoff frequency (Hz): ');
f_high = input('Enter upper cutoff frequency (Hz): ');
N = input('Enter number of Monte Carlo runs: ');

%% 2. Define nominal values of resistors and capacitors
R1_nom = input('Enter LPF stage resistance value (R1): ');   % 1 kOhm
R2_nom = input('Enter HPF stage resistance value (R2): ');   % 3 kOhm
R3_nom = input('Enter noninverting feedback resistance value (R3): ');   % 1 kOhm
R4_nom = input('Enter inverting feedback resistance divider value (R4): ');   % 4 kOhm
R5_nom = input('Enter inverting feedback resistance value (R5): ');   % 4 kOhm
C1_nom = input('Enter LPF stage capacitance value (C1): ');  % 5 nF
C2_nom = input('Enter HPF stage capacitance value (C2): ');  % 5 nF
tolR = 0.10; % Resistance tolerance of 10%
tolC = 0.15; % Capacitance tolerance of 15%

%% 3. Prepare storage for Monte Carlo results
time_points = 0:1e-5:0.01; 
freq_points = logspace(log10(f_low), log10(f_high), 500); 

Vout_transient = zeros(length(time_points), N);
Vout_AC_real = zeros(length(freq_points), N);
Vout_AC_imag = zeros(length(freq_points), N);
Isupply_AC_real = zeros(length(freq_points), N);
Isupply_AC_imag = zeros(length(freq_points), N);

%% 5. Monte Carlo simulation
for k = 1:N
    % Generate random component values within tolerance
    % To be changed to 1 + tol + (0.5 - tol) * randn() for faulty class
    R1 = R1_nom*(1 + tolR*(2*rand() - 1));
    R2 = R2_nom*(1 + tolR*(2*rand() - 1));
    R3 = R3_nom*(1 + tolR*(2*rand() - 1));
    R4 = R4_nom*(1 + tolR*(2*rand() - 1));
    R5 = R5_nom*(1 + tolR*(2*rand() - 1));
    C1 = C1_nom*(1 + tolC*(2*rand() - 1));
    C2 = C2_nom*(1 + tolC*(2*rand() - 1));
    
    % --- Vout AC simulation ---
    H_Vout_rand = sktf(R1, R2, R3, R4, R5, C1, C2);
    H_jw_Vout = freqresp(H_Vout_rand, 2*pi*freq_points);
    Vout_AC_complex = squeeze(H_jw_Vout); 
    
    Vout_AC_real(:,k) = real(Vout_AC_complex);
    Vout_AC_imag(:,k) = imag(Vout_AC_complex);
    
    % --- Isupply AC Simulation (Using Placeholder Function) ---
    H_Isupply_rand = skIsupply_placeholder(R1, R2, R3, R4, R5, C1, C2);
    H_jw_Isupply = freqresp(H_Isupply_rand, 2*pi*freq_points);
    Isupply_AC_complex = squeeze(H_jw_Isupply); 
    
    Isupply_AC_real(:,k) = real(Isupply_AC_complex);
    Isupply_AC_imag(:,k) = imag(Isupply_AC_complex);

    % --- Transient simulation ---
    [y_t, ~] = step(H_Vout_rand, time_points);
    Vout_transient(:,k) = y_t;
end

%% 6. Save results
save('monte_carlo_results_faultfree.mat', ...
    'Vout_transient', ... 
    'Vout_AC_real', 'Vout_AC_imag', ... 
    'Isupply_AC_real', 'Isupply_AC_imag', ...
    'time_points', 'freq_points');
disp('Monte Carlo analysis complete. Results saved to monte_carlo_results_final.mat');

% --------------------------------------------------------------------------
% Local Functions MUST be defined at the end of the script file
% --------------------------------------------------------------------------

%% 4a. Define Vout Transfer Function (SK-BPF H(s))
function H = sktf (R1, R2, R3, R4, R5, C1, C2)
    s = tf('s');
    K = 1 + (R5/R4);
    H = (s * K) / ((s^2)+(s*((1/(R1*C1))+(1/(R3*C1))+(1/(R3*C2))+((1-K)/(R2*C1))))+((R1 + R2)/(R1*R2*R3*C1*C2)));
end

%% 4b. Define Placeholder Isupply Transfer Function
function H_I = skIsupply_placeholder (R1, R2, R3, R4, R5, C1, C2)
    s = tf('s');
    K = 1 + (R5/R4);
    
    % Denominator D(s) is the same as for Vout (shared poles)
    D_s = (s^2)+(s*((1/(R1*C1))+(1/(R3*C1))+(1/(R3*C2))+((1-K)/(R2*C1))))+((R1 + R2)/(R1*R2*R3*C1*C2));
    
    % Placeholder Numerator N_I(s): s*C1 gives a stable, current-like behavior.
    N_I_s = s * C1; 
    
    H_I = N_I_s / D_s;
end