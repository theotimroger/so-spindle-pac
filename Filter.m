function [ datafilt_lp_hp_notch ] = Filter(Fc_ph,Fc_pb,data,Fs)

% Butter 5th ordre LP Hz
Wn = Fc_pb/(Fs/2); 
[Blp,Alp] = butter(5,Wn); 
datafilt_lp = filtfilt(Blp,Alp,data); 

% Butter 3rd ordre HP Hz
Wn = Fc_ph/(Fs/2); 
[Bhp,Ahp] = butter(3,Wn,'high'); 
datafilt_lp_hp = filtfilt(Bhp,Ahp,datafilt_lp); 

% Ajouter un filtre Notch à 50 Hz
f0 = 50;  % Fréquence du notch (50 Hz)
Q = 30;   % Facteur de qualité (plus élevé, plus étroit est le filtre)

% Calculer la fréquence normalisée pour le notch
Wn_notch = f0 / (Fs / 2);

% Créer le filtre Notch 
[Bnotch, Anotch] = iirnotch(Wn_notch, Wn_notch / Q);

datafilt_lp_hp_notch = filtfilt(Bnotch, Anotch, datafilt_lp_hp);

end