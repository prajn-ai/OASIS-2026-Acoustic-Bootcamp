clear; close all; clc;
%% Parameters
input_file = 'gain_measurements.xlsx';
output_file = 'gain_results.xlsx';

% Expected columns in input_file (one row per test frequency):
%   Frequency_Hz  - test frequency [Hz]
%   TVR_dB        - source Transmit Voltage Response, dB re 1 uPa/V @ 1m
%   RVR_dB        - receiver Receive Voltage Response, dB re 1V/uPa
%   V_drive_V     - drive voltage sent to the source [V]
%   r_m           - source-to-receiver distance [m]
%   V_measured_V  - voltage actually measured/digitized at the end of
%                   your recording chain (after amp/ADC/etc.) [V]

%% Read measurements
T = readtable(input_file);
f      = T.Frequency_Hz;
TVR    = T.TVR_dB;
RVR    = T.RVR_dB;
V_drive= T.V_drive_V;
r      = T.r_m;
V_meas = T.V_measured_V;

%% Gain chain
% p(1m,f) = 10^(TVR/20) * V_drive        -> radiated pressure at 1 m
% p(r,f)  = p(1m,f) / r                  -> pressure at test distance r
% V_expected = 10^(RVR/20) * p(r,f)      -> voltage the calibrated
%                                           hydrophone alone should produce
% G(f) = V_measured / V_expected         -> gain of everything else in
%                                           the chain (cables/preamp/ADC)
p_1m = 10.^(TVR/20) .* V_drive;
p_r  = p_1m ./ r;
V_expected = 10.^(RVR/20) .* p_r;

G_linear = V_meas ./ V_expected;
G_dB = 20*log10(G_linear);

%% Display results table
fprintf('\n%10s %12s %14s %10s\n', 'f (Hz)', 'V_expected', 'V_measured', 'G (dB)');
for k = 1:height(T)
    fprintf('%10d %12.4g %14.4g %10.2f\n', f(k), V_expected(k), V_meas(k), G_dB(k));
end

%% Plot gain vs frequency
figure;
plot(f/1e3, G_dB, 'o-', 'LineWidth', 1.5);
xlabel('Frequency (kHz)');
ylabel('System Gain (dB)');
title('System Gain vs Frequency');
grid on;

%% Write results back out
T.p_1m_uPa = p_1m;
T.p_r_uPa = p_r;
T.V_expected_V = V_expected;
T.Gain_linear = G_linear;
T.Gain_dB = G_dB;
writetable(T, output_file);
fprintf('\nResults written to %s\n', output_file);