function [all_epochs, detected_SO] = detectSO(signal, fig, fs)
    % Implémentation de l'algorithme décrit par Mölle et al. (2009)
    
    % Détection des oscillations lentes dans un signal EEG filtré
    % - signal : vecteur du signal EEG brut
    % - fig :  0 -> ne pas afficher les figures, 1 -> afficher
    % - fs : fréquence d'échantillonnage (ex. 100 Hz)
    % Sortie :
    % - detected_SO : Matrice contenant les oscillations lentes détectées (instant du pic négatif,
    % valeur du pic négatif, instant du pic positif, valeur du pic positif, premier passage à zero (pos->neg), second passage à zéro (pos->neg))

    if nargin < 2
        fig = 0; % Par défaut, ne pas afficher les figures
    end

    if nargin < 3
        fs = 256; % Par défaut 256 Hz
    end

    filter_order = 2;
    fc_low = 0.1;  % fréquence de coupure basse en Hz
    fc_high = 2;   % fréquence de coupure haute en Hz
    
    % Conception d’un filtre passe-bande Butterworth
    [lp_b, lp_a] = butter(filter_order, [fc_low fc_high] / (fs/2), 'bandpass');
    
    % Application en passe-avant / passe-arrière
    signal_filt = filtfilt(lp_b, lp_a, double(signal));

    % **2️ Détection des passages à zéro (positif -> négatif)**
    zero_crossings = find(diff(sign(signal_filt)) < 0); % Passage positif -> négatif

    % **3️ Détection des pics positifs et négatifs**
    neg_peaks = [];
    pos_peaks = [];
    detected_SO = [];
    all_epochs = [];

    for i = 1:length(zero_crossings) - 1
        idx1 = zero_crossings(i);
        idx2 = zero_crossings(i+1);

        % Vérifier si l'intervalle est entre 0.9s et 2s
        time_interval = (idx2 - idx1) / fs;
        if time_interval < 0.9 || time_interval > 2
            continue;
        end

        % Extraire le segment entre idx1 et idx2
        segment = signal_filt(idx1:idx2);

        % Détection des pics négatif et positif
        [y_min, loc_min] = min(segment);
        [y_max, loc_max] = max(segment);

        neg_peaks = [neg_peaks; y_min];
        pos_peaks = [pos_peaks; y_max];

        detected_SO = [detected_SO; idx1+loc_min-1, y_min, idx1+loc_max-1, y_max, idx1, idx2];
    end

    % **4️ Calcul des seuils adaptatifs**
    if isempty(neg_peaks) || isempty(pos_peaks)
        disp("Aucune oscillation lente détectée.");
        return;
    end

    x = (2/3) * mean(neg_peaks);
    delta_moy = mean(pos_peaks - neg_peaks);
    delta_seuil = (2/3) * delta_moy;

    % **5 Sélection des oscillations valides**
    oscillations_valides = [];
    for i = 1:size(detected_SO, 1)
        y_min = detected_SO(i, 2);
        y_max = detected_SO(i, 4);
        amplitude = y_max - y_min;

        if y_min < x && amplitude > delta_seuil
            oscillations_valides = [oscillations_valides; detected_SO(i, :)];
        end
    end

    if isempty(oscillations_valides)
        disp("Aucune oscillation lente valide détectée.");
        return;
    end

    %stockage de toutes les oscillations lentes sur un intervalle de 1.5s
    %autour du pic négatif
    window_size = round(1.5 * fs);

    for i = 1:size(oscillations_valides, 1)
        idx_neg = oscillations_valides(i,1);
        idx_start = max(1, idx_neg - window_size);
        idx_end = min(length(signal_filt), idx_neg + window_size);

        epoch = signal_filt(idx_start:idx_end);
        if length(epoch) == 2 * window_size + 1
            all_epochs = [all_epochs; epoch(:)'];
            plot(linspace(-1.5, 1.5, length(epoch)), epoch, 'Color', [0.6 0.6 0.6]);
        end
    end
    % **6️ Affichage des oscillations lentes détectées**
    if fig == 1
        figure;
        t = (1:length(signal)) / fs;
        plot(t, signal_filt, 'k'); hold on;
        scatter(oscillations_valides(:,1)/fs, oscillations_valides(:,2), 'bo', 'filled');
        scatter(oscillations_valides(:,3)/fs, oscillations_valides(:,4), 'ro', 'filled');
        title('Détection des Oscillations Lentes');
        xlabel('Temps (s)');
        ylabel('Amplitude (\muV)');
        legend('Signal filtré', 'Pic négatif', 'Pic positif');
        hold off;
    end

    % **7️ Superposition des oscillations lentes détectées**
    if fig == 1

        % **8️ Tracé de la moyenne avec écart-type**
        if ~isempty(all_epochs)
            figure;
            hold on;
            mean_epoch = mean(all_epochs, 1);
            std_epoch = std(all_epochs, 0, 1);
            t = linspace(-1.5, 1.5, size(all_epochs, 2));
            fill([t, fliplr(t)], [mean_epoch + std_epoch, fliplr(mean_epoch - std_epoch)], [1 0.8 0.8], 'FaceAlpha', 0.5, 'EdgeColor', 'none');
            plot(t, mean_epoch, 'r', 'LineWidth', 4);
            title('Oscillation Lente Moyenne avec Écart-Type');
            xlabel('Temps (s)');
            ylabel('Amplitude (\muV)');
            hold off;
        end
    end

    detected_SO = oscillations_valides;
end
