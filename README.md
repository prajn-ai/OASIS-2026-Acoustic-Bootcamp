# OASIS 2026 Acoustic Bootcamp

Scripts generated post-workshop to calculate and generate what's needed for calibrating a source and receiver (hydrophone) in a test tank: near/far-field placement, minimum usable frequency, frequency resolution, and calibration signal generation (stepped tones, sweeps, tone bursts).

This README and code files have been made with the help of Claude AI

## Files

- `calc_ideal_N_fmin.m` — function: computes the tank's waveguide cutoff frequency and, for each test frequency, the ideal number of cycles (N) needed for a target frequency resolution, plus the resulting pulse duration and far-field distance.
- `calc_f_min_tank.m` — script version of the above with plots and a results table (self-contained, standalone parameters).
- `step_pulse_train_calib_signal.m` — builds the actual stepped-frequency calibration pulse train, using `calc_ideal_N_fmin` for its frequency list and cycle counts, tapered with a Tukey window, gapped, and exported to WAV.
- `stepping_pulse_train.wav` — example output of the above.
- `OASIS_TX_signal_gen/sweep_signal.m` — repeated logarithmic (or linear) chirp sweep, on/off cycle repeated to fill a target total duration.
- `OASIS_TX_signal_gen/tone_burst_signal.m` — sequence of fixed-duration tone bursts at specified frequencies, with off-time between them.

## Equations

All formulas use: `c` = speed of sound in water (1480 m/s, fresh water), `f` = frequency, `D` = transducer diameter, `H` = tank depth.

### Wavelength

```
Ξ» = c / f
```

### Near-field / far-field boundary (Fraunhofer distance)

```
r_near = 2 * D^2 * f / c
```

Beyond `r_near`, the field behaves as a simple spreading spherical wave and the 1/r spreading law (used below) is valid. This is the general Fraunhofer/antenna-style far-field criterion (phase error across the aperture bounded to ~λ/16). A more conservative, geometry-specific alternative for a circular piston transducer is the "natural focus" distance `D^2*f/(4c)`, which is 8x smaller — this repo uses the more general `2D^2f/c` form.

### Waveguide cutoff frequency (tank depth constraint)

```
f_min ≈ c / (4H)
```

Comes from the tank acting as a duct with a pressure-release top (water surface) and rigid bottom — the fundamental mode only fits when `H = Ξ»/4`. Below `f_min`, sound doesn't propagate as a clean mode in the tank.

### Frequency resolution from cycle count

```
Ξ”f = f / N     <=>     T = N / f
```

`N` = number of cycles in a tone burst, `T` = resulting pulse duration. This is the reciprocal relationship between observation time and frequency resolution (Ξ”f = 1/T), rewritten in terms of cycle count. Used to pick the ideal `N` per frequency in `calc_ideal_N_fmin.m`.

### Spherical spreading

```
p(r) = p(1m) / r     <=>     level(r) = level(1m) - 20*log10(r)
```

Lets you convert a measurement at the actual test distance back to the standard 1 m reference used by TVR/RVR — valid only once `r > r_near` and still within the reflection-free ("quiet") window below.

### Quiet window / multipath timing

```
Ξ”t = (r_reflected - r_direct) / c
```

Using the image-source method: a boundary reflection is equivalent to a direct path from a mirrored source position. The path-length difference between that image path and the true direct path, divided by `c`, gives the time available before the first reflection arrives and contaminates the pulse. This caps how long a calibration pulse (`T` above) can be for a given tank geometry and source/receiver placement.

### TVR / RVR

```
TVR(f) = 20*log10( p(1m,f) / V(f) )        [dB re 1 µPa/V]
RVR(f) = 20*log10( V_out(f) / p_incident(f) )   [dB re 1V/µPa]
```

Transmit Voltage Response and Receive (Receiving) Voltage Response — the frequency-dependent efficiency of the source and hydrophone, respectively. Both peak near the transducer's mechanical resonance and roll off away from it, which is why calibration is done across a range of frequencies rather than a single tone.

### System gain from a calibrated source + receiver

```
p(1m,f)   = 10^(TVR(f)/20) * V_drive(f)
p(r,f)    = p(1m,f) / r
V_expected(f) = 10^(RVR(f)/20) * p(r,f)
G(f)      = V_measured(f) / V_expected(f)
```

If both the source (TVR) and receiver (RVR) are independently calibrated, this chain predicts what voltage should be measured at the hydrophone terminals. Any difference between that prediction and what's actually digitized is the gain of everything else in the signal path (cables, preamp, ADC). Extract `V_measured(f)` by windowing each known tone segment from the recording (using the transmit signal's lead-in/gap timing) and taking its FFT magnitude at that frequency.
