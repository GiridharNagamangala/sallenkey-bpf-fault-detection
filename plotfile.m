load('monte_carlo_results_faultfree.mat');
figure('Position', [100 100 1000 800]); % Create a large figure window (1000x800 pixels)

% Define a light gray color for the individual Monte Carlo runs
MC_Color = [0.7 0.7 0.7];

% --------------------------------------------------------
% Subplot 1: Real Part of Vout
% --------------------------------------------------------
subplot(2, 2, 1); 
semilogx(freq_points, Vout_AC_real, 'Color', MC_Color);
hold on;
plot(freq_points, mean(Vout_AC_real, 2), 'r', 'LineWidth', 2); % Mean response in RED
grid on;
xlabel('Frequency (Hz)');
ylabel('Real(V_{out})');
title('Real Part of Output Voltage');
legend('MC Runs', 'Mean', 'Location', 'SouthWest');
hold off;

% --------------------------------------------------------
% Subplot 2: Imaginary Part of Vout
% --------------------------------------------------------
subplot(2, 2, 2); 
semilogx(freq_points, Vout_AC_imag, 'Color', MC_Color);
hold on;
plot(freq_points, mean(Vout_AC_imag, 2), 'b', 'LineWidth', 2); % Mean response in BLUE
grid on;
xlabel('Frequency (Hz)');
ylabel('Imag(V_{out})');
title('Imaginary Part of Output Voltage');
legend('MC Runs', 'Mean', 'Location', 'SouthWest');
hold off;

% --------------------------------------------------------
% Subplot 3: Real Part of Isupply (Placeholder)
% --------------------------------------------------------
subplot(2, 2, 3); 
semilogx(freq_points, Isupply_AC_real, 'Color', MC_Color);
hold on;
plot(freq_points, mean(Isupply_AC_real, 2), 'g', 'LineWidth', 2); % Mean response in GREEN
grid on;
xlabel('Frequency (Hz)');
ylabel('Real(I_{supply})');
title('Real Part of Supply Current (Placeholder)');
legend('MC Runs', 'Mean', 'Location', 'SouthWest');
hold off;

% --------------------------------------------------------
% Subplot 4: Imaginary Part of Isupply (Placeholder)
% --------------------------------------------------------
subplot(2, 2, 4); 
semilogx(freq_points, Isupply_AC_imag, 'Color', MC_Color);
hold on;
plot(freq_points, mean(Isupply_AC_imag, 2), 'm', 'LineWidth', 2); % Mean response in MAGENTA
grid on;
xlabel('Frequency (Hz)');
ylabel('Imag(I_{supply})');
title('Imaginary Part of Supply Current (Placeholder)');
legend('MC Runs', 'Mean', 'Location', 'SouthWest');
hold off;