function [freqs, N_ideal, pulse_dur, df_actual, r_near, f_min] = calc_ideal_N_fmin(c, H, D, df_target, f_speaker_max, freq_step)
% CALC_IDEAL_N_FMIN  Compute tank cutoff frequency and ideal cycle count
% per test frequency for a target frequency resolution.
%
%   [freqs, N_ideal, pulse_dur, df_actual, r_near, f_min] = ...
%       calc_ideal_N_fmin(c, H, D, df_target, f_speaker_max, freq_step)
%
%   c            - speed of sound in water [m/s]
%   H            - tank depth [m]
%   D            - transducer diameter [m]
%   df_target    - desired frequency resolution [Hz]
%   f_speaker_max- upper usable frequency, e.g. speaker limit [Hz]
%   freq_step    - spacing between test frequencies [Hz]
%
%   freqs        - test frequency list [Hz]
%   N_ideal      - cycles needed per frequency for df_target resolution
%   pulse_dur    - resulting pulse duration per tone [s]
%   df_actual    - actual resolution achieved per tone [Hz]
%   r_near       - far-field distance per frequency [m]
%   f_min        - tank waveguide cutoff frequency [Hz]

%% Waveguide cutoff frequency (tank depth constraint)
f_min = c / (4*H);

%% Build test frequency list, starting just above f_min
f_start = ceil(f_min/freq_step)*freq_step;
if f_start <= f_min
    f_start = f_start + freq_step;
end
freqs = f_start:freq_step:f_speaker_max;

%% Ideal number of cycles (N) per frequency for the target resolution
% Resolution relationship: df = f/N  ->  N = f/df_target
N_ideal = ceil(freqs / df_target);
pulse_dur = N_ideal ./ freqs;              % resulting pulse duration [s]
df_actual = freqs ./ N_ideal;              % actual resolution achieved [Hz]
r_near = D^2 .* freqs / (4*c);             % far-field distance [m]

end