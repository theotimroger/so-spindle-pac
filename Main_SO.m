function [Detected_SO_list] = Main_SO(edf_filename, ElectrodeLabel, ElectrodeReference, time_start, time_end, method, fig, fs_new, save_SO)
    
    %Inputs
    %edf_filename : chemin du fichier
    %ElectrodeLabel: nom de l'électrode pour l'analyse
    %time_start : instant (en secondes) du début de l'analyse
    %time_end : instant (en secondes) de la fin de l'analyse
    %method: 1=detectSO, 2=detectSO2
    %fig: affichage des oscillations lentes détectées sur la période
    %choisie
    %fs_new: fréquence de rééchantillonnage
    %save_SO: 0: pas de sauvegarde des figures, 1: sauvegarde

    
    %Outputs
    %Detected_SO_list : tableaux content 1 ligne par oscillation lente détectée: 1 (instant pic négatif), 2 (amplitude pic négatif), 3 (instant pic positif),4 (amplitude pic positif), 5 (instant zéro 1), 6 (instant zéro 2)

    % **********
    % Parameters
    % **********

    % Extraire uniquement le nom du fichier EDF sans le chemin
    [~, edf_name, ~] = fileparts(edf_filename);
    inst1 = num2str(time_start);
    inst2 = num2str(time_end);
    met = num2str(method);

    %nom du fichier .mat pour la sauvegarde des données
    mat_filename = ['DetectedSO_' edf_name '_' inst1 '_' inst2 '_' ElectrodeLabel '_' met '.mat'];

    % Vérifie si un fichier .mat avec les SO détectées existe déjà
    if isfile(mat_filename)
        disp(['Les oscillations lentes détectées ont déjà été enregistrées dans ' mat_filename '. Chargement des données existantes.']);
        load(mat_filename, 'Detected_SO_list');
    end

    % **Toujours charger raw_data, même si les oscillations lentes ont déjà été enregistrées pour permettre l'affichage du résultats**
    if ~exist('raw_data', 'var')
        % Vérifie si le fichier existe avant de continuer
        if ~isfile(edf_filename)
            error('Le fichier spécifié n''existe pas : %s', edf_filename);
        end

        % Charger le signal brut EEG via ReadData (Electrode Cz)
        raw_data = ReadData(time_start, time_end, ElectrodeLabel, ElectrodeReference, edf_filename);

        % Charger la fréquence d'échantillonnage du fichier d'origine
        hdr = edfinfo(edf_filename);
        Fs_original = hdr.NumSamples(1) / seconds(hdr.DataRecordDuration); % Extraction de la fréquence d'échantillonnage
        
        if Fs_original < 256
            fs_new = Fs_original;
        end
        % Si les oscillations lentes ne sont pas chargées, les détecter
        if ~exist('Detected_SO_list', 'var')

            % Prétraitement du signal brut avec preprocess_eeg
            [signal_filtre] = preprocess_eeg(raw_data, Fs_original, fs_new);

            
            % Détection des oscillations lentes
            if method==1
                [~, detected_SO] = detectSO(signal_filtre, 0, fs_new); 
            elseif method==2
                [~, detected_SO] = detectSO2(signal_filtre, 0, fs_new); 
            end

            % detected_SO est une matrice Nx6 contenant les informations sur les oscillations lentes
            % On suppose qu’elle est exprimée dans une fréquence réduite fs_new, et que l’on souhaite convertir certaines colonnes en indices pour Fs_original
            
            Detected_SO_list = detected_SO; % Copie pour modification
            
            % Colonnes à convertir : 1 (instant pic négatif), 3 (instant pic positif), 5 (instant zéro 1), 6 (instant zéro 2)
            cols_to_convert = [1, 3, 5, 6];
            
            for c = cols_to_convert
                Detected_SO_list(:, c) = round(detected_SO(:, c) * (Fs_original / fs_new));
            end
            
            if save_SO
                % Sauvegarde des données liées aux oscillations lentes
                save(mat_filename, 'Detected_SO_list');
            end
        end
    end

    % ***********************
    % Affichage des résultats
    % ***********************
    if isempty(Detected_SO_list)
        disp('Aucune oscillation lente détectée.');
        return;
    end
    % if fig == 1
    %     % Génération de l'axe temporel du signal brut (non filtré)
    %     t = (0:length(raw_data)-1) / Fs_original;
    % 
    %     figure;
    %     hold on;
    % 
    %     %filtrage LP à 35 Hz pour un affichage du résultat plus lisible
    %     [b, a] = butter(4, 35/(Fs_original/2), 'low');
    %     raw_data_lp35 = filtfilt(b, a, double(raw_data));
    % 
    %     plot(t, raw_data_lp35, 'b'); % Signal EEG filtré en bleu
    % 
    %     % Colorier les oscillations lentes détectées en rouge
    %     for i = 1:size(Detected_SO_list, 1)
    %         start_idx = Detected_SO_list(i, 5);
    %         stop_idx = Detected_SO_list(i, 6);
    %         plot(t(start_idx:stop_idx), raw_data_lp35(start_idx:stop_idx), 'r', 'LineWidth', 1.5);
    %     end
    % 
    %     % Ajouter les légendes et labels
    %     title(['EEG' ElectrodeLabel '-' ElectrodeReference 'avec détection des oscillations lentes']);
    %     xlabel('Temps (s)');
    %     ylabel('Amplitude EEG (µV)');
    %     legend({'EEG LP 35 Hz', 'Oscillations lentes détectées'}, 'Location', 'Best');
    % 
    %     xlim([t(1), t(end)]); % Étendre l'axe x sur toute la durée de l'enregistrement
    %     grid on;
    % 
    %     hold off;
    end
end
