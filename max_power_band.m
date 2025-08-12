function f_max = max_power_band(signal, fs, fmin, fmax)
% PLOT_MAX_POWER_BAND - Calcule et affiche la puissance maximale dans une bande
%
% INPUTS :
%   signal : vecteur signal temporel
%   fs     : fréquence d’échantillonnage (Hz)
%   fmin   : borne inférieure de la bande (Hz)
%   fmax   : borne supérieure de la bande (Hz)
%
% OUTPUT :
%   maxPower : puissance correspondante au pic dans la bande [fmin, fmax]

    % Longueur du signal
    N = length(signal);

    % Appliquer une fenêtre pour éviter les effets de bord (optionnel mais recommandé)
    w = hamming(N)';
    signal_win = signal(:)' .* w;

    % Transformée de Fourier
    X = fft(signal_win);
    X = X(1:floor(N/2)+1);
    P = abs(X).^2 / N;  % Spectre de puissance normalisé
    f = linspace(0, fs/2, length(P));  % Axe des fréquences

    % Recherche du pic dans la bande
    idx_band = (f >= fmin) & (f <= fmax);
    [maxPower, idx_max] = max(P(idx_band));
    f_peak = f(idx_band);
    f_max = f_peak(idx_max);

    % Affichage du spectre
    figure;
    plot(f, P, 'b'); hold on;
    plot(f_max, maxPower, 'ro', 'MarkerSize', 8, 'LineWidth', 2);
    title(sprintf('Spectre de puissance (pic à %.2f Hz)', f_max));
    xlabel('Fréquence (Hz)');
    ylabel('Puissance');
    xlim([0, fs/2]);
    grid on;

end
