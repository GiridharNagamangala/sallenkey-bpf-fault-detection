%% Plotting dry run output to test and debug
clear; clc;

load('monte_carlo_results.mat'); % Contains output data of dryrun

figure;
hold on;
for k = 1:N
    plot(time_points, Vout_transient(:,k), 'b');
end
hold off;
xlabel('Time (s)');
ylabel('V_{out} (V)');
title('Monte Carlo Transient Responses (200 runs)');
grid on;

figure;
hold on;
for k = 1:N
    semilogx(freq_points, 20*log10(Vout_ACR(:,k)), 'b');
end
hold off;
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
title('Monte Carlo Real Response (N = ' + N + ')');
grid on;