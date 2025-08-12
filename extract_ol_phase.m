function [phase_ol, all_phase_epochs, eeg_filt] = extract_ol_phase(eeg, fs, detected_SO)
% EXTRACT_OL_PHASE - Extrait la phase des oscillations lentes (<1 Hz)
% autour des pics négatifs détectés
%
% INPUTS :
%   eeg         : vecteur EEG brut
%   fs          : fréquence d’échantillonnage (Hz)
%   detected_SO : sorties de Main_SO (contenant les indices de pics négatifs)
%
% OUTPUTS :
%   phase_ol         : phase instantanée (Hilbert) sur tout le signal
%   all_phase_epochs : phases autour des pics négatifs, centrées sur chaque SO

    %% Extraction de la fréquence principale des OL
    fmin = 0.6; 
    fmax = 1.1;
    win_width = 0.2;
    [f_center, ~, ~] = detect_ol_by_spectral_integration(eeg, fs, fmin, fmax, win_width);

    %% Paramètres de filtrage
    % La transformée de Hilbert impose un filtre étroit
    f_low = f_center - 0.1;
    f_high = f_center + 0.1;


    d = designfilt('bandpassfir', ...
        'FilterOrder', 500, ...
        'CutoffFrequency1', f_low, ...
        'CutoffFrequency2', f_high, ...
        'SampleRate', fs);
    
    eeg_filt = filtfilt(d, double(eeg));

    % %% Filtrage + Hilbert
    % [b, a] = butter(4, [f_low f_high] / (fs/2), 'bandpass');
    % eeg_filt = filtfilt(b, a, double(eeg));
    
    analytic_signal = hilbert(eeg_filt);
    phase_ol = angle(analytic_signal);

    %% Extraire les segments autour des pics négatifs (fenêtre fixe)
    window_size = round(1.5 * fs);  % ±1.5s
    all_phase_epochs = [];

    for i = 1:size(detected_SO, 1)
        idx_neg = detected_SO(i, 1);  % index du pic négatif
        idx_start = idx_neg - window_size;
        idx_end = idx_neg + window_size;

        if idx_start >= 1 && idx_end <= length(phase_ol)
            segment = phase_ol(idx_start:idx_end);
            all_phase_epochs = [all_phase_epochs; segment(:)'];
        end
    end


    % %% Affichage si suffisamment d’événements
    % if size(all_phase_epochs, 1) >= 3
    %     t_epoch = linspace(-1.5, 1.5, size(all_phase_epochs, 2));
    % 
    %     figure;
    % 
    %     % 1. Tracé des phases individuelles
    %     subplot(2,1,1);
    %     hold on;
    %     for i = 1:size(all_phase_epochs, 1)
    %         plot(t_epoch, all_phase_epochs(i,:), 'Color', [0.6 0.6 0.6 0.3]);
    %     end
    %     title('Phases individuelles autour des pics négatifs (OL)');
    %     xlabel('Temps (s)');
    %     ylabel('Phase (rad)');
    %     ylim([-pi, pi]);
    %     grid on;
    % 
    %     % 2. Moyenne et écart-type circulaires
    %     subplot(2,1,2);
    %     hold on;
    % 
    %     phase_mean = circ_mean(all_phase_epochs, [], 1);
    %     phase_std = circ_std(all_phase_epochs, [], 1);
    % 
    %     phase_mean = phase_mean(:)';
    %     phase_std = phase_std(:)';
    % 
    %     % zone ± écart-type
    %     fill([t_epoch, fliplr(t_epoch)], ...
    %          [phase_mean + phase_std, fliplr(phase_mean - phase_std)], ...
    %          [1 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
    % 
    %     % moyenne
    %     plot(t_epoch, phase_mean, 'r', 'LineWidth', 2);
    %     title('Phase moyenne ± écart-type autour des SO');
    %     xlabel('Temps (s)');
    %     ylabel('Phase (rad)');
    %     ylim([-pi, pi]);
    %     legend('±1 std', 'Moyenne circulaire');
    %     grid on;
    % else
    %     disp('Pas assez d''oscillations lentes détectées pour afficher la moyenne de phase.');
    % end

end
