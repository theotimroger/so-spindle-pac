function [all_epochs, detected_SO] = detectSO_Massimini(signal, fig, fs)
    % Implémentation de l'algorithme décrit par Massimini et al. (2004)

    % Détection des oscillations lentes (0.1 - 4 Hz) sur un signal EEG unique
    % - signal : vecteur de signal EEG (1D)
    % - fig :  0 -> ne pas afficher les figures, 1 -> afficher
    % - fs : fréquence d'échantillonnage (ex. 100 Hz)
    % Sortie :
    % - all_epochs : contient les oscillations lentes à +-1,5s du pic
    % - detected_SO : liste des caractéristiques des oscillations lentes détectées: instant du pic négatif,
    % valeur du pic négatif, instant du pic positif, valeur du pic positif,
    % premier passage à zero (pos->neg), second passage à zéro (pos->neg)
    
    if nargin < 2
        fig = 0; % Par défaut, ne pas afficher les figures
    end

    if nargin < 3
        fs = 256; % Par défaut 256 Hz
    end

    filter_order = 2;
    fc_low = 0.1;  % fréquence de coupure basse en Hz
    fc_high = 4;   % fréquence de coupure haute en Hz
    
    % Conception d’un filtre passe-bande Butterworth
    [lp_b, lp_a] = butter(filter_order, [fc_low fc_high] / (fs/2), 'bandpass');
    
    % Application en passe-avant / passe-arrière
    signal_filt = filtfilt(lp_b, lp_a, double(signal));

    % **2️ Détection des passages à zéro**
    zero_crossings = find(diff(sign(signal_filt)) ~= 0); % on s'intéresse à tous les passages à zero, la contrainte sur le sens du passage est induite par le seuil sur le pic négatif

    % **3 Détection des oscillations lentes**
    detected_SO = [];
    all_epochs = [];
    for i = 1:length(zero_crossings) - 2
        idx1 = zero_crossings(i);
        idx2 = zero_crossings(i+1);
        idx3 = zero_crossings(i+2); %permet d'avoir le passage à zéro dans le même sens que idx1 (permet de faire correspondre les intervalle avec l'autre méthode de détection (detectSO_Molle) afin de les comparer

        % Vérifier l'intervalle temporel (0.3s - 1.0s)
        time_interval = (idx2 - idx1) / fs;
        if time_interval < 0.3 || time_interval > 1.0
            continue;
        end

        % **A) Détection du pic négatif et positif**
        segment = signal_filt(idx1:idx2); %première partie du signal, négative dans le cas d'une SO
        [y_min, loc_min] = min(segment);

        segment2 = signal_filt(idx2:idx3); %deuxième partie du signal, positive dans le cas d'une SO
        [y_max, loc_max] = max(segment2);

        % **B) Vérification des critères d'amplitude**
        peak_to_peak_amplitude = y_max - y_min;
        if y_min < -80 && peak_to_peak_amplitude > 140
            detected_SO = [detected_SO; idx1+loc_min-1, y_min, idx2+loc_max-1, y_max, idx1, idx3]; %detected_SO(:,1) contient les instants des pics négatifs
        end
    end

    if isempty(detected_SO)
        disp("Aucune oscillation lente détectée.");
        return;
    end

    %stockage de toutes les oscillations lentes sur un intervalle de 1.5s
    %autour du pic négatif
    window_size = round(1.5 * fs);

    for i = 1:size(detected_SO, 1)
        idx_neg = detected_SO(i,1); 

        idx_start = max(1, idx_neg - window_size); 
        idx_end = min(length(signal_filt), idx_neg + window_size); 

        epoch = signal_filt(idx_start:idx_end);

        if length(epoch) == 2 * window_size + 1
            all_epochs = [all_epochs; epoch(:)'];
        end
    end


    % % **6 Tracé de la moyenne avec écart-type**
    % if fig == 1 && ~isempty(all_epochs)
    %     figure;
    %     hold on;
    %     mean_epoch = mean(all_epochs, 1);
    %     std_epoch = std(all_epochs, 0, 1);
    % 
    %     t_epoch = linspace(-1.5, 1.5, size(all_epochs, 2));
    % 
    %     % Tracé de l'écart-type
    %     fill([t_epoch, fliplr(t_epoch)], ...
    %          [mean_epoch + std_epoch, fliplr(mean_epoch - std_epoch)], ...
    %          [1 0.8 0.8], 'FaceAlpha', 0.5, 'EdgeColor', 'none');
    % 
    %     % Tracé de la moyenne
    %     plot(t_epoch, mean_epoch, 'r', 'LineWidth', 3);
    % 
    %     title('Moyenne des Oscillations Lentes avec Écart-Type');
    %     xlabel('Temps (s)');
    %     ylabel('Amplitude (\muV)');
    %     legend('Écart-type', 'Moyenne des oscillations');
    %     hold off;
    % end
end
