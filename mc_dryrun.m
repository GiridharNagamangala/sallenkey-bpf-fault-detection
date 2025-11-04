%% Monte Carlo Analysis Script for Circuit

% Clear workspace and command window
clear; clc;

%% 1. User Inputs

% Ask user for lower and upper cutoff frequencies
f_low = input('Enter lower cutoff frequency (Hz): ');
f_high = input('Enter upper cutoff frequency (Hz): ');

% Number of Monte Carlo runs
N = input('Enter number of Monte Carlo runs: ');

%% 2. Define nominal values of resistors and capacitors

% Nominal resistor values in Ohms
R1_nom = 1e3;  % example value
R2_nom = 1e3;
R3_nom = 1e3;
R4_nom = 1e3;
R5_nom = 1e3;

% Nominal capacitor values in Farads
C1_nom = 1e-6;  % example value
C2_nom = 1e-6;

% Define percentage tolerance for Monte Carlo (e.g., 5%)
tol = 0.05;  % 5%

%% 3. Prepare storage for Monte Carlo results

% Preallocate matrices for transient and AC responses
% Assuming you simulate voltage at a node, e.g., Vout
time_points = 0:1e-5:0.01; % time vector for transient simulation
freq_points = logspace(log10(f_low), log10(f_high), 500); % frequency vector for AC
Vout_transient = zeros(length(time_points), N);
Vout_AC = zeros(length(freq_points), N);

%% 4. Define transfer function (leave blank to fill in)
% You can use the Symbolic Toolbox or Control System Toolbox
% Example: H(s) = (blank) 
% Use s = tf('s'); for Laplace variable

% SK-BPF transfer function
function H = sktf (R1, R2, R3, R4, R5, C1, C2)
    s = tf('s');
    K = 1 + (R5/R4);
    H = (s * K) / ((s^2)+(s*((1/(R1*C1))+(1/(R3*C1))+(1/R3*C2)+((1-K)/(R2*C1))))+((R1 + R2)/(R1*R2*R3*C1*C2)));
end

%% 5. Monte Carlo simulation

for k = 1:N
    % Generate random resistor and capacitor values within tolerance
    R1 = R1_nom*(1 + tol*randn());
    R2 = R2_nom*(1 + tol*randn());
    R3 = R3_nom*(1 + tol*randn());
    R4 = R4_nom*(1 + tol*randn());
    R5 = R5_nom*(1 + tol*randn());
    
    C1 = C1_nom*(1 + tol*randn());
    C2 = C2_nom*(1 + tol*randn());
    
    % Substitute the random values into the transfer function
    H_rand = sktf(R1, R2, R3, R4, R5, C1, C2);
    
    % 5a. Transient simulation (step response)
    [y_t, t] = step(H_rand, time_points);
    Vout_transient(:,k) = y_t;
    
    % 5b. AC simulation (frequency response)
    [mag, phase] = bode(H_rand, 2*pi*freq_points);
    % mag is 3D array: squeeze to get magnitude
    Vout_AC(:,k) = squeeze(mag);
end

%% 6. Save results
save('monte_carlo_results.mat', 'Vout_transient', 'Vout_AC', 'time_points', 'freq_points');

disp('Monte Carlo analysis complete. Results saved to monte_carlo_results.mat');
