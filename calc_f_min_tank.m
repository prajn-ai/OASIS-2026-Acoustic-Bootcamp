clear; close all; clc;
%% Parameters
c = 1480;                        % speed of sound in water [m/s]
H = 1.3843;                      % tank depth [m]
D = 0.1826;                      % transducer (UW30) diameter [m]
df_target = 500;                 % desired frequency resolution [Hz]
f_speaker_max = 10000;           % upper usable frequency (speaker limit) [Hz]
freq_step = 1000;                % spacing between test frequencies [Hz]

%% Waveguide cutoff frequency (tank depth constraint)
f_min = c / (4*H); 
fprintf('Tank waveguide cutoff f_min = %.1f Hz\n', f_min);

%% Build test frequency list, starting just above f_min
f_start = ceil(f_min/freq_step)*freq_step;   % round up to nearest step
if f_start <= f_min
    f_start = f_start + freq_step;
end
freqs = f_start:freq_step:f_speaker_max;

%% Ideal number of cycles (N) per frequency for the target resolution
% Resolution relationship: df = f/N  ->  N = f/df_target
N_ideal = ceil(freqs / df_target);
pulse_dur = N_ideal ./ freqs;              % resulting pulse duration [s]
df_actual = freqs ./ N_ideal;              % actual resolution achieved [Hz]
r_near = 2*D^2 .* freqs / c;   % Being more general but could use D^2 .* freqs / (4*c) for piston approx          % far-field distance [m]

%% Display results table
fprintf('\n%8s %6s %10s %12s %14s\n', 'f (Hz)', 'N', 'T (ms)', 'df actual (Hz)', 'r_near (cm)');
for k = 1:length(freqs)
    fprintf('%8d %6d %10.3f %14.2f %12.2f\n', freqs(k), N_ideal(k), ...
        pulse_dur(k)*1e3, df_actual(k), r_near(k)*100);
end

%% Plots
figure;
subplot(2,1,1);
stem(freqs/1e3, N_ideal, 'filled');
xlabel('Frequency (kHz)');
ylabel('Ideal N (cycles)');
title(sprintf('Cycles Needed for %d Hz Resolution', df_target));
grid on;

subplot(2,1,2);
stem(freqs/1e3, pulse_dur*1e3, 'filled');
xlabel('Frequency (kHz)');
ylabel('Pulse duration (ms)');
title('Resulting Pulse Duration per Tone');
grid on;

figure;
plot(freqs/1e3, r_near*100, 'o-');
xlabel('Frequency (kHz)');
ylabel('Far-field distance (cm)');
title('Near-Field / Far-Field Boundary vs Frequency');
grid on;