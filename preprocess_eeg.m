function [signal_filtre] = preprocess_eeg(signal, fs, fs_new)
    % Fonction de prétraitement EEG
    % utilisée uniquement pour Main_SO, le prétraitement est inclus dans
    % Main_Spindles
    % - signal : signal brut issu de l'électrode choisi dans Main_SO()
    % - fs : fréquence d'échantillonnage lu dans le header dans Main_SO()
    % - fs_new :  nouvelle fréquence d'échantillonnage


    fc = 35; % fréquence de coupure 35 Hz    
    
    % Conception du filtre passe-bas Butterworth d'ordre 4
    Wn = fc / (fs / 2);
    [b, a] = butter(4, Wn, 'low');
    
    % Appliquer le filtre
    signal_filtre = filtfilt(b, a, double(signal));
    
    %Rééchantillonner le signal pour accélerer les calculs (tout en
    %respectant le critère de Nyquist-Shannon)
    if fs > fs_new
        signal_filtre = resample(signal_filtre, fs_new, fs);
    end

    %calcul de le moyenne du signal pour mettre un offset
    mean_signal = mean(signal_filtre);

    %ajout de l'offset pour que mean = 0
    signal_filtre = signal_filtre - mean_signal;

end