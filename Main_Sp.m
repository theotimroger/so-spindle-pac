function [FeatureChan, StoredSpindles] = Main_Sp(fname,StartTime,StopTime,ElectrodeReference, fig_spindles)
tic
clear PE_RMSLevel PE_MainFreq Detected_spindles Detected_spindles_array FeatureChan
%profile on;

info = edfinfo(fname);
premiere_electrode = info.SignalLabels(1);
% **********
% Parameters
% **********

% Database - pointing at the folder where the database is placed
%DBPath = '/Users/theotimroger/Desktop/MFE - epilespsy/data AMD/wetransfer_algo-sleep-spindles_2025-06-23_0957/Référentiel/';	
%[DatabaseInfoNum, DatabaseInfoTxt] = xlsread([DBPath 'Global spindle database 2.xls']); 



% Plotting or annotating the data? 
if fig_spindles
    PlotData =  'Yes'; % 'Yes' or 'No'
else
    PlotData = 'No';
end

%AnnotateData=  'Yes'; % 'Yes' or 'No'



%INPUT PARAMETERS
%Parameters.Fs = GetFs(DBPath,DatabaseInfoTxt,"FP1");
Parameters.Fs = GetFs2(fname,premiere_electrode);
Parameters.Fc_ph_sleep = 5;
Parameters.Fc_pb_sleep = 35;
Parameters.Fc_ph_display = 0.3;
Parameters.Fc_pb_display = 70;
Parameters.Min_RMS_Threashold = 0; % Minimum amplitude of the sleep spindles (how many std above the mean)
Parameters.Min_mean_RMS_for_channel = 5;
Parameters.SpinFreqPH = 10; % Low cutoff frequency of sleep spindles
Parameters.SpinFreqPB = 15; % High cutoff frequency of sleep spindles
Parameters.MinElectForDet = 1; % Sleep spindle detected if at least on x derivations 
Parameters.FusionMinTime = Parameters.Fs/2;
Parameters.EvenMinTime = Parameters.Fs/2;
Parameters.RMSHalfWindow = round(Parameters.Fs/4);
Parameters.FFT_nbr_points = Parameters.Fs*10; % Number of point for the FFT
Parameters.FeatureProcessingStep = round(Parameters.Fs/16);




 

% *************
% Data Features
% *************
ArtElectrodes = {'lio','rso','emg-g','emg-d','ecg'};
[ElectrodeLabel] = WhatElectrode(fname,ArtElectrodes);

% Preallocation
nrElectrodeLeft = ElectrodeLabel(1,:);  %sélectionne la première electrode
nrElectrodeLeft = deblank(nrElectrodeLeft); %enlève les espaces vides
raw_data = ReadData(StartTime,StopTime,nrElectrodeLeft,ElectrodeReference,fname); 

nElectrodes = size(ElectrodeLabel, 1);
signalLength = length(raw_data);  % obtenu juste après avoir lu la première électrode
raw_data_Chan = zeros(nElectrodes, signalLength);
Detected_spindles = zeros(nElectrodes, signalLength);

FeatureChan = [];
% raw_data_Chan = [];
% Detected_spindles = zeros(1,length(raw_data)); %tableau de detection des fuseaux initialiser et de taille raw_data (signal montage monopolaire), une ligne par electorde et les colonnes correspondent a chaque sample

All_RMS_spindles = [];
All_Freq_spindles = [];
All_Dur_spindles = [];

for NumElectrode = 1:length(ElectrodeLabel(:,1)) % loop on all electrodes
    FeatureChan(NumElectrode).Label = nrElectrodeLeft;          % Stocke le nom de l'électrode
    FeatureChan(NumElectrode).Detected_spindles = zeros(1,length(raw_data)); 
    ProcPerformed = round(100*NumElectrode/length(ElectrodeLabel(:,1))); 
    fprintf('Detection in progress (perc.): %d .\n', ProcPerformed); % display the detection progress 

    nrElectrodeLeft = ElectrodeLabel(NumElectrode,:); % name of current electrode
    nrElectrodeLeft = deblank(nrElectrodeLeft);
    [raw_data] = ReadData(StartTime ,StopTime,nrElectrodeLeft,ElectrodeReference,fname); % Raw EEG data
    raw_data_Chan(NumElectrode,:) = raw_data; 

    [RMSLevel, MainFreq] = DataFeatures(nrElectrodeLeft,raw_data,Parameters,fname);% Extract form raw EEG data features of sliding window (such as frequency, amplitude, quality and power of the signal)


    Min_RMS_Level = mean(RMSLevel) + std(RMSLevel)*Parameters.Min_RMS_Threashold; % absolute threashold on the amplitude 
    

    % *****************
    % Spindle detection
    % *****************
    
    PositiveEventCount = 0;
    NegativeEventCount = 0;
    % Preallocation
    PE_RMSLevel= zeros(1,length(raw_data));
    PE_MainFreq= zeros(1,length(raw_data));
    PE_Index= zeros(1,length(raw_data));

        % Sliding window to decide on the presence of a spindle
        WindowStop = min([length(raw_data)-Parameters.RMSHalfWindow length(raw_data)-Parameters.FeatureProcessingStep]);
        for CurrentWindow = Parameters.RMSHalfWindow:Parameters.FeatureProcessingStep:WindowStop
            if ((MainFreq(CurrentWindow) > Parameters.SpinFreqPH) && (MainFreq(CurrentWindow) < Parameters.SpinFreqPB) && (RMSLevel(CurrentWindow) > Min_RMS_Level)) 
                % The window can include a spindle if:
                % - the main frequency of the signal is within SpinFreqPH and PB
                % - the amplitude of the signal is above Min_RMS_Level
                PositiveEvent = 1;
            else
                PositiveEvent = 0;
            end
            % Attribution
            if CurrentWindow<length(raw_data)-Parameters.FeatureProcessingStep
                if PositiveEvent == 1
                    PositiveEventCount = PositiveEventCount + 1;%nombre de fenêtre ou spindle
                    PE_RMSLevel(PositiveEventCount) = RMSLevel(CurrentWindow); %RMS centré en la fenêtre de détection
                    PE_MainFreq(PositiveEventCount) = MainFreq(CurrentWindow);%MainFreq centré en fenêtre de détection
                    PE_Index(PositiveEventCount) = CurrentWindow; %Contient les indices des fenêtres où les fuseaux ont été détectés.
                    for fill = 1:Parameters.FeatureProcessingStep %Note les FeaturesProcessingStep points échantillons suivants commme étant spindle
                        Detected_spindles(NumElectrode,CurrentWindow+fill-1) = 1;
                        FeatureChan(NumElectrode).Detected_spindles(CurrentWindow+fill-1) = 1;
                    end
                else
                    NegativeEventCount = NegativeEventCount + 1;
                end
            end
        end
        
        PE_RMSLevel = PE_RMSLevel(1:PositiveEventCount);
        PE_MainFreq = PE_MainFreq(1:PositiveEventCount);
        PE_Index = PE_Index(1:PositiveEventCount);

        FeatureChan(NumElectrode).RMS = PE_RMSLevel;
        FeatureChan(NumElectrode).MainFreq = PE_MainFreq;
        FeatureChan(NumElectrode).Index = PE_Index;

end
% Detection stat
[Detected_spindles_list,~,Detected_spindles_array] = SpindlesList(Detected_spindles,Parameters.MinElectForDet,Parameters.EvenMinTime);
fprintf('Nombre de spindles détectés : %d\n', size(Detected_spindles_list, 2));


% % Annotations
% if strcmp(AnnotateData,'Yes')
%     DataAnnotation(Parameters,Detected_spindles_list,fname); % Annotate EDF file with spindle events      
% end 

%stat
%[TP,FN,FP,ColorLine,FP_Huupponen,NonSpindleSec,TN] = DetectionStat(Detected_spindles_list, 0, Parameters.Fs, ExpertScoring, length(raw_data));


% Display
if strcmp(PlotData,'Yes')
    disp(ElectrodeLabel);
    SingleChanSpindleList = SpindlesListOneChan(FeatureChan,Parameters.EvenMinTime);
    StoredSpindles = DisplayAllDerivations(ElectrodeLabel,raw_data_Chan,StartTime,Parameters,SingleChanSpindleList,Detected_spindles_list,Detected_spindles_array,fname,FeatureChan); % Display all sleep spindles in green       
    close all; fclose all; 
end

% Création de SpindleInfo basé sur SpindlesListOneChan
SpindleInfo = struct('start_time', {}, 'end_time', {}, 'amplitude_envelope', {}, 'channel', {});

fs = Parameters.Fs;

for ch = 1:length(FeatureChan)
    label = FeatureChan(ch).Label;
    raw = raw_data_Chan(ch, :);
    
    % Spindles détectés pour ce canal
    if isfield(SingleChanSpindleList(ch), 'Detected_spindles_list')
        spindles = SingleChanSpindleList(ch).Detected_spindles_list;
    else
        continue
    end

    % Enveloppe hilbertienne
    d = designfilt('bandpassiir','FilterOrder',4, ...
        'HalfPowerFrequency1',Parameters.SpinFreqPH, ...
        'HalfPowerFrequency2',Parameters.SpinFreqPB, ...
        'SampleRate', fs);
    filtered = filtfilt(d, double(raw));
    analytic = hilbert(filtered);
    envelope = abs(analytic);

    for i = 1:size(spindles, 2)
        start_idx = spindles(1,i);
        end_idx   = spindles(2,i);

        if end_idx > length(envelope), end_idx = length(envelope); end
        if start_idx > end_idx, continue; end

        SpindleInfo(end+1).start_time = (start_idx - 1) / fs;
        SpindleInfo(end).end_time     = (end_idx - 1) / fs;
        SpindleInfo(end).amplitude_envelope = envelope(start_idx:end_idx);
        SpindleInfo(end).channel = label;
    end
end


temps = toc;
fprintf('Temps d''exécution : %.3f secondes\n', temps);

close all;
save('Global');
beep;

    

