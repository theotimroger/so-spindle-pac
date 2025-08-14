function Main(edf_filename)
    % ------------------------------
    % Ce programme a été conçu dans le cadre d'une thèse de master en
    % ingénierie biomédicale à L'Ecole Polytechnique de Bruxelles (ULB).
    %
    % Il a pour but d'automatiser l'analyse d'électroencéphalogrammes (EEG)
    % pour la détection des oscillations lentes, des fuseaux des sommeil et
    % d'analyser le couplage entre les 2 oscillations.
    % 
    % Détection des oscillations lentes:
    % Deux méthodes de détection sont proposées. Elles sont issues des
    % études de Massimi et al. (2004) et de Mölle et al. (2009). Le choix de
    % la méthode à utiliser pour l'analyse peut être fait dans la section
    % "Méthode de détection des oscillations lentes".
    %
    % Détection des fuseaux du sommeil:
    % La détection des fuseaux du sommeil se base sur la méthode mise au
    % point par Nonclercq et al. (2013) et dont les paramètres ont été
    % optimisés sur une population d'enfants.
    %
    % Mesure du couplage entre les 2 oscillations:
    % Ce programme permet de mesurer le couplage Phase-Amplitude entre les
    % 2 oscillations.
    % La mesure du couplage se fait en 2 étapes: détection des événements
    % cooccurents puis mesure de l'amplitude des fuseaux du sommeil
    % chevauchant, entièrement ou partiellement, des oscillations lentes
   
    %% fichier à étudier
    %edf_filename = '/Users/theotimroger/Desktop/MFE - epilespsy/Data_sleep_Theotim/eeg_meg_2636.edf'; %indiquer ici le chemin du fichier à traiter

    %% Choix des électrodes
    % Le signal final utilisé pour l'étude sera la différence entre celui
    % mesuré en ElectrodeLabel et celui mesuré en ElectrodeReference

    ElectrodeLabels = {'Cz'}; %nom des électrodes d'étude pour l'analyse
    ElectrodeReference = ''; %nom de l'électrode de référence, si les signaux des canaux dans Electrodelabels sont déjà référencés à une électrode, écrire: " ElectrodeReference = ''; "

    %% Paramètres
    fs_new = 256; %fréquence utilisée pour le rééchantillonnage

    %% Début et fin de l'analyse
    time_start = 0 ; %instant de début du traitement
    time_end = inf; %instant de fin du traitement
    
    %% Méthode de détection des oscillations lentes
    method = 2; % 1: detectSO, 2: detectSO2

    %% Outputs visuels
    fig_SO = 1; %0: pas d'affichage des oscillations lentes détectées sur le signal d'origine, 1: affichage
    fig_spindles = 1; %0: pas d'affichage des spindles détectées sur le signal d'origine, 1: affichage
    fig_PAC = 1; %0: pas d'affichage de l'histogramme de l'amplitude des spindles en fonction de la phase des oscillations lentes, 1: affichage
    
    %% Sauvegarde des résultats
    save_SO = 1; %0: pas de sauvegarde des données sur les oscillations lentes (instants et amplitudes) dans un fichier .mat, 1: sauvegarde
    save_spindles = 1; %0: pas de sauvegarde des données sur les spindles (instants et amplitudes) dans un fichier .mat , 1: sauvegarde
    save_fig_PAC = 0; %0: pas de sauvegarde de la figure du PAC, 1: sauvegarde
    
    %% Analyse
    for i=1:length(ElectrodeLabels)
        Compute_MI(edf_filename, ElectrodeLabels{i}, ElectrodeReference, time_start, time_end, method, fig_SO, fig_spindles, fig_PAC, fs_new, save_SO, save_spindles, save_fig_PAC)
    end








    