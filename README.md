# so-spindle-pac
Automatic detection of sleep spindles and slow oscillations in sleep EEG, automatic measurement of their Phase-Amplitude Coupling

EEG Slow Oscillations & Sleep Spindles — Detection and Phase–Amplitude Coupling (MI)
Code accompanying a research master’s thesis. It automates detection of slow oscillations (SO) and sleep spindles from EEG stored in EDF files, and quantifies their coupling via a Modulation Index (MI). The entry point is Main.m — set your parameters there and run.
 
Highlights
•	Two SO detectors (after Mölle 2009 and Massimini 2004 styles).
•	Spindle detector with multi channel event fusion and per channel features (after Nonclercq 2013 style).
•	Phase–Amplitude Coupling: spindle band amplitude binned by SO phase → MI and plots.
•	EDF I/O: reads data from EDF, supports referencing (e.g., Cz − A1).
•	Figures & exports: optional saving of detections and PAC figures.
 
Requirements
There is no external installation beyond MATLAB. Recommended environment:
•	MATLAB R2020b+ (tested features like edfinfo, designfilt, resample, hilbert).
•	Signal Processing Toolbox (for butter, filtfilt, iirnotch, designfilt, hilbert, resample).
Tip: If edfinfo isn’t available in your MATLAB, the repo includes classic EDF readers (Readedf.m, edfhdr.m) and helpers (GetFs2.m).
 
Quickstart
1.	Open Main.m and set:
o	edf_filename → path to your .edf file.
o	ElectrodeLabels → e.g., {'Cz','Fz'}.
o	ElectrodeReference → e.g., 'A1' or '' for no explicit reference.
o	Time window → time_start, time_end (seconds; use 0/Inf to process the whole file).
o	SO detection method → method = 1 (Mölle style) or method = 2 (Massimini style).
o	Display / saving flags → fig_SO, fig_spindles, fig_PAC, save_SO, save_spindles, save_fig_PAC.
o	fs_new → resampling rate for SO processing (e.g., 256).
2.	Run Main (no arguments). It will loop over the selected electrodes and call the full pipeline.
Minimal example snippet inside Main.m:
edf_filename      = 'path/to/your_recording.edf';
ElectrodeLabels   = {'Cz'};   % channels to analyze
ElectrodeReference = 'A1';    % or '' if already referenced

% Time window (s)
time_start = 0; time_end = Inf;

% Detection & display
method       = 1;   % 1 = Mölle (2009), 2 = Massimini (2004)
fig_SO       = 1;   % show SO figure
fig_spindles = 1;   % show/plot spindle detections
fig_PAC      = 1;   % show PAC figure
save_SO         = 1;   % save SO .mat / figures when implemented
save_spindles   = 1;   % save spindle .mat
save_fig_PAC    = 1;   % save PAC figure

fs_new = 256;     % resampling for SO path
 
What the pipeline does
1) Load & (optional) re reference
•	ReadData.m reads a channel from EDF (Readedf.m/edfinfo) and, if a reference label is provided, subtracts it (e.g., Cz − A1).
2) Pre processing
•	SO path (Main_SO.m): low pass / band pass filtering (≤ ~35 Hz), optional resample to fs_new via preprocess_eeg.m.
•	Spindle path (Main_Sp.m): band pass + notch (50 Hz) via Filter.m; feature extraction in DataFeatures.m (RMS, main frequency).
3) Slow oscillation (SO) detection
Two interchangeable detectors on the filtered signal:
•	detectSO.m (Mölle 2009 style): uses zero crossings (pos→neg), negative/positive peaks and duration constraints.
•	detectSO2.m (Massimini 2004 style): alternative band pass + zero crossing logic with constraints on inter zero intervals and peak amplitudes.
Output of Main_SO → Detected_SO_list (one row per SO; includes times and values for neg/pos peaks and the surrounding zero crossings).
4) Spindle detection & fusion
•	Main_Sp.m builds per channel detections, computes signal features (DataFeatures.m), and performs event fusion across time gaps.
•	SpindlesList.m and SpindlesListOneChan.m merge close/short events and, when relevant, apply a minimal duration and min channels criterion.
•	DisplayAllDerivations.m visualizes detections across derivations and returns a StoredSpindles structure with per channel event lists.
5) Phase–Amplitude Coupling (PAC) & Modulation Index (MI)
•	extract_ol_phase.m: estimates the dominant OL frequency via detect_ol_by_spectral_integration.m, band passes narrowly around it, and computes the instantaneous phase (Hilbert).
•	Compute_MI.m: for each spindle overlapping an SO epoch, extracts the amplitude envelope in the spindle band, bins it by OL phase, and computes an MI. It also produces an optional phase amplitude histogram and overlays SO/spindle events on the raw trace.
 
Repository structure & file by file guide
.
├─ Main.m                        % Entry point: set params (file, channels, method, flags) and run the analysis
├─ Main_SO.m                     % Driver for SO detection (select method, preprocess, call detector, save/plot)
├─ Main_Sp.m                     % Driver for spindle detection, features, multi channel fusion, visualization
├─ Compute_MI.m                  % End to end orchestration: load → detect SO & spindles → extract SO phase → MI + plots
├─ detectSO.m                    % SO detector (Mölle 2009 style): zero crossings, peaks, duration checks
├─ detectSO2.m                   % SO detector (Massimini 2004 style): alternative zero crossing/peak logic
├─ extract_ol_phase.m            % Finds dominant OL freq, band passes narrowly, returns phase and epochs
├─ detect_ol_by_spectral_integration.m % Integrates power around candidate freqs; picks center with max integrated power
├─ preprocess_eeg.m              % Low pass (≤35 Hz), resample to fs_new, mean remove (SO path)
├─ Filter.m                      % LP + HP + 50 Hz notch (Butterworth, iirnotch) for spindle path
├─ DataFeatures.m                % Sliding window RMS and main frequency features used during spindle processing
├─ SpindlesList.m                % Event fusion across/within channels with min duration and gap rules
├─ SpindlesListOneChan.m         % Event fusion for a single channel
├─ DisplayAllDerivations.m       % Plot detections across derivations, return `StoredSpindles` struct
├─ ReadData.m                    % Read EDF channel(s), apply optional re reference (left − right)
├─ Readedf.m                     % Classic EDF reader (segment by time, channel)
├─ edfhdr.m                      % Read EDF header info
├─ GetFs2.m                      % Helper to extract sampling rate for a named channel via `edfinfo`
├─ max_power_band.m              % Utility: frequency of max power within a band
├─ WhatElectrode.m               % List electrodes that are true EEG (excludes EOG/EMG/ECG helpers, or any other electrode one wants to exclude)
Key data structures
•	Detected_SO_list (from Main_SO): one row per SO; columns include: time/value of negative peak, time/value of positive peak, and the two bracketing zero crossings.
•	StoredSpindles (from Main_Sp / DisplayAllDerivations): struct array with one element per channel, each holding spindle events with start_time, end_time, and amplitude/envelope features.
 
Outputs
Depending on the flags set in Main.m:
•	Figures: SO detections on the trace, spindle overlays across derivations, and a PAC histogram with MI.
•	.mat files: when enabled, detections/features are saved (e.g., ProcessedFeatures/… or method specific files) for reuse without recomputation.
Exact paths/filenames are set inside the drivers; adjust there if you need a different layout.
 
Parameters (most relevant)
•	method (SO): 1 = detectSO.m (Mölle 2009), 2 = detectSO2.m (Massimini 2004).
•	fs_new (SO): target resampling rate for the SO branch.
•	fig_SO, fig_spindles, fig_PAC: toggle figures.
•	save_SO, save_spindles, save_fig_PAC: toggle saving of detections/figures.
•	Spindle fusion: minimal duration and gap settings live in SpindlesList*.m (tune to your dataset if needed).
 
Reproducibility
•	Keep a note of: MATLAB version, toolboxes, method, fs_new, channel montage, and time window.
 
Troubleshooting
•	edfinfo not found: use the provided Readedf.m/edfhdr.m paths or upgrade MATLAB/ensure Signal Processing Toolbox is installed.
•	No detections: relax thresholds inside the detector(s), check filtering band, and confirm your ElectrodeLabels exist in the EDF (use WhatElectrode.m).
<img width="451" height="677" alt="image" src="https://github.com/user-attachments/assets/aa0ecaa4-584a-4aa7-919e-d379b18874e7" />
