function Fs = GetFs2(filename, channel_name)
    % EXTRACT_FS_EDFINFO - Extrait la fréquence d'échantillonnage d'un canal spécifique d'un fichier EDF
    %
    % Usage :
    %   Fs = extract_Fs_edfinfo('mon_fichier.edf', 'Cz')
    %
    % Entrées :
    %   - filename : Chemin du fichier EDF
    %   - channel_name : Nom du canal dont on veut extraire la fréquence d'échantillonnage
    %
    % Sortie :
    %   - Fs : Fréquence d'échantillonnage du canal spécifié, ou NaN si le canal n'existe pas

    % Lire les métadonnées du fichier EDF
    edf = edfinfo(filename);
    
    % Convertir la durée en secondes
    record_duration = seconds(edf.DataRecordDuration);

    % Extraire les noms des signaux
    signal_labels = edf.SignalLabels;

    % Trouver l'index du canal demandé
    idx = find(strcmpi(signal_labels, channel_name), 1);

    if isempty(idx)
        warning('Le canal "%s" n''existe pas dans le fichier.', channel_name);
        Fs = NaN;
    else
        % Calculer Fs = (nombre d'échantillons) / (durée en secondes)
        Fs = edf.NumSamples(idx) / record_duration;
    end
end
