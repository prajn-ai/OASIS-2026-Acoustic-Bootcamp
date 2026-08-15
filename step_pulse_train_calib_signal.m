clear; close all; clc;
%% Parameters
fs = 192e3;                      % sampling frequency [Hz]
c = 1480;                        % speed of sound in water [m/s]
H = 1.3843;                      % tank depth [m]
D = 0.1826;                      % transducer (UW30) diameter [m]
df_target = 500;                 % desired frequency resolution [Hz]
f_speaker_max = 10000;           % upper usable frequency (speaker limit) [Hz]
freq_step = 1000;                % spacing between test frequencies [Hz]
gap_dur = 1;                     % silence between pulses [s]
lead_in_dur = 1;                 % silence before the first pulse [s]
lead_out_dur = 1;                % silence after the last pulse [s]
taper_ratio = 0.1;               % Tukey (cosine) taper ratio

%% Get test frequencies and ideal cycle count from calc_ideal_N_fmin
[freqs, N_ideal, ~, ~, ~, f_min] = ...
    calc_ideal_N_fmin(c, H, D, df_target, f_speaker_max, freq_step);

fprintf('Tank cutoff f_min = %.1f Hz, testing %d frequencies: %s Hz\n', ...
    f_min, length(freqs), mat2str(freqs));

%% Build the stepping pulse train
silence = zeros(1, round(gap_dur*fs));
lead_in = zeros(1, round(lead_in_dur*fs));
lead_out = zeros(1, round(lead_out_dur*fs));

x = lead_in;
for k = 1:length(freqs)
    f = freqs(k);
    N = N_ideal(k);
    pulse_dur = N / f;                       % duration for exactly N cycles
    t_pulse = 0:1/fs:pulse_dur-1/fs;
    w = tukeywin(length(t_pulse), taper_ratio)';
    pulse = sin(2*pi*f*t_pulse) .* w;

    x = [x, pulse]; %#ok<AGROW>
    if k < length(freqs)
        x = [x, silence]; %#ok<AGROW>
    end
end
x = [x, lead_out];
t = (0:length(x)-1)/fs;

fprintf('Total signal duration: %.2f s\n', t(end));

%% Plot full pulse train
figure;
plot(t, x);
xlabel('Time (s)');
ylabel('Amplitude');
title('Stepping Pulse Train (variable N per frequency)');
grid on;

%% Spectrogram (memory-safe: modest window, no overlap)
window = round(0.1*fs);
noverlap = 0;
nfft = 4096;
[s, f_axis, t_axis] = spectrogram(x, window, noverlap, nfft, fs);
S_db = 20*log10(abs(s) + eps);
S_db = S_db - max(S_db(:));

figure;
imagesc(t_axis, f_axis/1e3, S_db);
axis xy;
clim([-40 0]);
colorbar;
xlabel('Time (s)');
ylabel('Frequency (kHz)');
ylim([0 f_speaker_max/1e3 + 2]);
title('Spectrogram of Stepping Pulse Train');

%% Export as WAV
x_wav = x / max(abs(x));
audiowrite('stepping_pulse_train.wav', x_wav, fs);