function [f_center, P_integrated, f_vec] = detect_ol_by_spectral_integration(signal, fs, fmin, fmax, win_width)
% DETECT_OL_BY_SPECTRAL_INTEGRATION
% Calcule la fréquence OL dominante en intégrant la puissance autour de chaque f
%
% INPUTS :
%   signal     : vecteur EEG temporel
%   fs         : fréquence d'échantillonnage (Hz)
%   fmin, fmax : limites de la bande à explorer (e.g. 0.3 – 1.2 Hz)
%   win_width  : largeur de la fenêtre d’intégration (Hz), ex: 0.2 → ±0.1 Hz
%
% OUTPUTS :
%   f_center       : fréquence centrale qui maximise la puissance intégrée
%   P_integrated   : vecteur des puissances intégrées pour chaque f
%   f_vec          : vecteur des fréquences testées

    % Paramètres FFT
    N = length(signal);
    win = hamming(N)';
    signal_win = signal(:)' .* win;

    X = fft(signal_win);
    X = X(1:floor(N/2)+1);
    P = abs(X).^2 / N;
    f = linspace(0, fs/2, length(P));

    % Fréquences à tester pour l’intégration
    f_vec = fmin : 0.01 : fmax;  % Résolution fine
    P_integrated = zeros(size(f_vec));

    % Intégration autour de chaque fréquence testée
    for i = 1:length(f_vec)
        f0 = f_vec(i);
        idx = (f >= f0 - win_width/2) & (f <= f0 + win_width/2);
        P_integrated(i) = sum(P(idx));
    end

    % Fréquence maximale de puissance intégrée
    [~, idx_max] = max(P_integrated);
    f_center = f_vec(idx_max)

    % Affichage
    % figure;
    % plot(f_vec, P_integrated, 'k', 'LineWidth', 2); hold on;
    % xline(f_center, 'r--', 'LineWidth', 1.5);
    % title(sprintf('Puissance intégrée autour de chaque fréquence (%.2f Hz)', f_center));
    % xlabel('Fréquence centrale (Hz)');
    % ylabel('Puissance intégrée (uV^2)');
    % grid on;

end
