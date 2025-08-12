function Compute_MI(edf_filename, ElectrodeLabel,ElectrodeReference, time_start, time_end, method, fig_SO, fig_spindles, fig_PAC, fs_new, save_SO, save_spindles, save_fig_PAC)
    fname = edf_filename;
    [~, edf_name, ~] = fileparts(fname);

    % Charger signal EEG
    raw_data = ReadData(time_start, time_end, ElectrodeLabel, ElectrodeReference, edf_filename);

    % Récupérer fréquence d’échantillonnage
    hdr = edfinfo(edf_filename);
    fs = hdr.NumSamples(1) / seconds(hdr.DataRecordDuration);

    % ============================
    % Étape 1 : Détection des SO et Spindles
    % ============================
    Detected_SO_list = Main_SO(edf_filename, ElectrodeLabel, ElectrodeReference, time_start, time_end, method, fig_SO, fs_new, save_SO);
    %SpindleInfo = Main_Spindles(edf_filename, time_start, time_end, ElectrodeLabel, ElectrodeReference,fig_spindles, save_spindles);     % struct avec .start_time, .end_time, .amplitude_envelope
    % Nom du fichier .mat pour sauvegarder les spindles
    spindle_mat_file = ['StoredSpindles_' edf_name '.mat'];
    
    if exist(spindle_mat_file, 'file')
        % Charger si déjà existant
        load(spindle_mat_file, 'StoredSpindles');
        fprintf('StoredSpindles chargés depuis %s\n', spindle_mat_file);
    else
        % Sinon lancer la détection
        [~, StoredSpindles] = Main_Sp(fname, time_start, time_end, ElectrodeReference, fig_spindles);
        
        % Sauvegarder
        if save_spindles
            save(spindle_mat_file, 'StoredSpindles');
            fprintf('StoredSpindles sauvegardés dans %s\n', spindle_mat_file);
        end
    end
    
    % ============================
    % Étape 2 : Extraction de la phase des Oscillations Lentes
    % ============================
    [phase_ol, ~, so_filtered] = extract_ol_phase(raw_data, fs, Detected_SO_list); % même taille que le signal

    % ============================
    % Étape 3 : Chevauchement Spindles–OL
    % ============================
    SO_phase_all = [];
    spindle_amp_all = [];

    % Ne garder que les spindles de l'électrode cible
    target_label = lower(ElectrodeLabel);
    found = false;
    
    for ch = 1:length(StoredSpindles)
        if strcmpi(lower(StoredSpindles(ch).Label), target_label)
            spindle_list = StoredSpindles(ch).Spindles;
            found = true;
            break;
        end
    end
    
    if ~found
        warning("Aucun spindle trouvé pour l'électrode %s.", target_label);
        return;
    end

    for i = 1:length(spindle_list)
        idx_sp_start = round(spindle_list(i).start_time * fs);
        idx_sp_end   = round(spindle_list(i).end_time   * fs);
        amp_env      = spindle_list(i).amplitude_envelope(:);

        for j = 1:size(Detected_SO_list, 1)
            % Indices de l’OL (début et fin)
            idx_ol_start = Detected_SO_list(j, 5);
            idx_ol_end   = Detected_SO_list(j, 6);

            % Chevauchementn (si début ou fin du spindle compris dans l'OL)
            if (idx_sp_end >= idx_ol_start && idx_sp_end <= idx_ol_end) || (idx_sp_start >= idx_ol_start && idx_sp_start <= idx_ol_end)
                % Portion commune aux deux oscillations
                idx_common_start = max(idx_sp_start, idx_ol_start);
                idx_common_end   = min(idx_sp_end, idx_ol_end);

                if idx_common_start >= 1 && idx_common_end <= length(phase_ol)
                    % Correspondance locale dans l'enveloppe
                    local_start = idx_common_start - idx_sp_start + 1;
                    local_end   = idx_common_end - idx_sp_start + 1;

                    if local_start >= 1 && local_end <= length(amp_env)
                        phase_segment = phase_ol(idx_common_start:idx_common_end);
                        amp_segment   = amp_env(local_start:local_end);

                        if length(phase_segment) == length(amp_segment)
                            % Extraire le signal filtré dans la même fenêtre
                            so_segment = so_filtered(idx_common_start:idx_common_end);
                        
                            % Localiser le pic positif
                            [~, idx_peak_pos] = max(so_segment);
                        
                            % Décalage de phase pour que ce pic ait la phase 0
                            phase_shift = phase_segment(idx_peak_pos);
                        
                            % Recentre la phase et recalcule entre [-pi, pi]
                            phase_aligned = angle(exp(1i * (phase_segment - phase_shift)));
                        
                            % Stockage
                            SO_phase_all = [SO_phase_all; phase_aligned];
                            spindle_amp_all   = [spindle_amp_all;   amp_segment];
                        end

                    end

                end
            end
        end
    end


    if isempty(SO_phase_all)
        disp('Aucun chevauchement spindle–OL détecté.');
        return;
    end

    % ============================
    % Étape 4 : Binning et amplitude moyenne
    % ============================
    nbins = 18;
    edges = linspace(-pi, pi, nbins+1);
    bin_centers = edges(1:end-1) + diff(edges)/2;

    [~, bin_idx] = histc(SO_phase_all, edges);

    amp_mean = zeros(1, nbins);
    amp_std = zeros(1, nbins);
    counts = zeros(1, nbins);
    
    for k = 1:nbins
        in_bin = (bin_idx == k);
        counts(k) = sum(in_bin);
    
        if counts(k) > 0
            amp_values = spindle_amp_all(in_bin);
            amp_mean(k) = mean(amp_values, 'omitnan');
            amp_std(k) = std(amp_values, 'omitnan');
        else
            amp_mean(k) = NaN;
            amp_std(k) = NaN;
        end
    end
    
    % 🔽 Normalisation : moyenne des barres = 1
    amp_mean_norm = amp_mean / nanmean(amp_mean);
    amp_std_norm = amp_std / nanmean(amp_mean);  % même facteur de normalisation

    % ============================
    % Calcul du Modulation Index (Tort et al.)
    % ============================
    % Distribution de probabilité des amplitudes normalisées
    P = amp_mean_norm / nansum(amp_mean_norm);
    
    % Retirer les NaN éventuels
    P(isnan(P)) = 0;
    
    % Entropie de Shannon
    H = -nansum(P .* log(P + eps));  % eps pour éviter log(0)
    
    % Entropie maximale
    Hmax = log(length(P));
    
    % Modulation Index (MI)
    MI = (Hmax - H) / Hmax;
    
    fprintf('Modulation Index (MI) : %.4f\n', MI);

            
    % ============================
    % Étape 5 : Affichage du PAC
    % ============================
    if fig_PAC
        figure;
        bar(bin_centers, amp_mean_norm, 'FaceColor', [0.2 0.6 0.8], 'EdgeColor', 'k'); hold on;
        errorbar(bin_centers, amp_mean_norm, amp_std_norm, 'k.', 'LineWidth', 1.2);  % barres d’erreur noires
        xlabel('Phase des oscillations lentes (rad)');
        ylabel('Amplitude moyenne normalisée ± écart-type');
        title(sprintf('Amplitude des spindles vs phase des OL\nMI = %.4f', MI));
        grid on;
    end
        
    if save_fig_PAC
        fig = figure('Visible', 'off');
        bar(bin_centers, amp_mean_norm, 'FaceColor', [0.2 0.6 0.8], 'EdgeColor', 'k'); hold on;
        errorbar(bin_centers, amp_mean_norm, amp_std_norm, 'k.', 'LineWidth', 1.2);
        xlabel('Phase des oscillations lentes (rad)');
        ylabel('Amplitude moyenne normalisée ± écart-type');
        title(sprintf('Amplitude des spindles vs phase des OL\nMI = %.4f', MI));
        grid on;
        savefig(fig, ['PAC_' edf_name '.fig']);
        close(fig);
    end

    % ============================
    % Étape 6 : Affichage des événements sur le signal brut
    % ============================
    t = (0:length(raw_data)-1)/fs;  % vecteur temps en secondes
    [b, a] = butter(4, 35/(fs/2), 'low');
    raw_data_filtered = filtfilt(b, a, double(raw_data));
    figure; 
    hold on;
    hSignal = plot(t, raw_data_filtered, 'k');
    xlabel('Temps (s)');
    ylabel('Amplitude EEG (µV)');
    title('EEG avec oscillations lentes et spindles');
    
    % Définir les limites verticales constantes (pour patchs pleins)
    y_limits = ylim;
    
    % Affichage des SO détectées (bandes bleues)
    for i = 1:size(Detected_SO_list, 1)
        t_start = t(Detected_SO_list(i,5));
        t_end   = t(Detected_SO_list(i,6));
        hSO = fill([t_start t_end t_end t_start], ...
             [y_limits(1) y_limits(1) y_limits(2) y_limits(2)], ...
             [0.7 0.85 1], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
        if i == 1
            hSO_legend = hSO; % stocker handle pour la légende
        end
    end
    
    % Affichage des spindles (bandes rouges)
    for i = 1:length(StoredSpindles(ch).Spindles)
            t_start = StoredSpindles(ch).Spindles(i).start_time;
            t_end   = StoredSpindles(ch).Spindles(i).end_time;
            hSpin = fill([t_start t_end t_end t_start], ...
                 [y_limits(1) y_limits(1) y_limits(2) y_limits(2)], ...
                 [1 0.6 0.6], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
            if i == 1
                hSpin_legend = hSpin; % stocker handle pour la légende
            end
    end
    
    legend([hSignal, hSO_legend, hSpin_legend], ...
       {'Signal EEG', 'Oscillations lentes', 'Spindles'});
    xlim([t(1), t(end)]);
    grid on;
end