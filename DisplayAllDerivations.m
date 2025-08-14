function StoredSpindles = DisplayAllDerivations(ElectrodeLabel,raw_data_Chan,StartTime,Parameters,SignleChanSpindleList,Global_Detected_spindles_list,Detected_spindles_array,fname,FeatureChan)
[~, edf_name, ~] = fileparts(fname);

Fs = Parameters.Fs;

if length(raw_data_Chan(:,1))>1
   Mean_raw_data = mean(raw_data_Chan);
else
    Mean_raw_data = raw_data_Chan;
end
Mean_raw_data = Filter(Parameters.Fc_ph_display,Parameters.Fc_pb_display,Mean_raw_data,Fs);
Offset = 100;

%fig = figure('name','Detection among derivatations','numbertitle','off');
fig = figure('name','Detection among derivatations','numbertitle','off', 'Position', [100, 100, 1200, 800]);

time = (1:length(Mean_raw_data))/Fs;
time = time + StartTime ;
plot(time, zeros(size(time)), 'w'); % hack pour forcer l'axe X sans modifier le reste du code
xlabel('Temps (s)');

hold on;
OffsetCount = 0;

StoredSpindles = struct('Label', {}, 'Spindles', {});

CountGlobal(length(ElectrodeLabel(:,1))) = 0;
CountPerM(length(ElectrodeLabel(:,1))) = 0;
TimePerc(length(ElectrodeLabel(:,1))) = 0;

for NumElectrode = 1:length(ElectrodeLabel(:,1))
    nrElectrodeLeft = ElectrodeLabel(NumElectrode,:);
    nrElectrodeLeft = deblank(nrElectrodeLeft);
    
    raw_data = raw_data_Chan(NumElectrode,:);
    raw_data = Filter(Parameters.Fc_ph_display, Parameters.Fc_pb_display, raw_data, Fs); % Filtrage
    ElData = -raw_data + OffsetCount;  % inversion + décalage
    plot(time, ElData);

    Detected_spindles_list = SignleChanSpindleList(NumElectrode).Detected_spindles_list;
    lockGreen = 0;
    UpdatedSpindleArray = zeros(1,length(ElData));
    if isempty(Detected_spindles_list)
    else 
        StoredSpindles(NumElectrode).Label = strtrim(nrElectrodeLeft);
        StoredSpindles(NumElectrode).Spindles = struct('start_idx', {}, 'end_idx', {}, 'start_time', {}, 'end_time', {}, 'duration', {});

        for DetectionIndex = 1:length(Detected_spindles_list(1,:))
            DetectedSpindleStart = Detected_spindles_list(1,DetectionIndex);
            DetectedSpindleStop = Detected_spindles_list(2,DetectionIndex);
            % Spindles with something aroud if needed.
            if (DetectedSpindleStop - DetectedSpindleStart>= Parameters.FusionMinTime)
                plot(time(DetectedSpindleStart:DetectedSpindleStop),ElData(DetectedSpindleStart:DetectedSpindleStop),'g');
                UpdatedSpindleArray(DetectedSpindleStart:DetectedSpindleStop) = ones(1,DetectedSpindleStop-DetectedSpindleStart+1);
                if ((DetectionIndex)>1) && ((DetectedSpindleStart-Detected_spindles_list(2,DetectionIndex-1))<Parameters.FusionMinTime) && (sum(Detected_spindles_array(Detected_spindles_list(1,DetectionIndex-1):DetectedSpindleStart))== DetectedSpindleStart-Detected_spindles_list(1,DetectionIndex-1)+1)
                    plot(time(Detected_spindles_list(1,DetectionIndex-1):DetectedSpindleStart),ElData(Detected_spindles_list(1,DetectionIndex-1):DetectedSpindleStart),'g');
                    UpdatedSpindleArray(Detected_spindles_list(1,DetectionIndex-1):DetectedSpindleStart) = ones(1,DetectedSpindleStart-Detected_spindles_list(1,DetectionIndex-1)+1);
                end
                if ((DetectionIndex)<length(Detected_spindles_list(1,:))) && ((Detected_spindles_list(1,DetectionIndex+1)-DetectedSpindleStop)<Parameters.FusionMinTime) && (sum(Detected_spindles_array(DetectedSpindleStop+1:Detected_spindles_list(2,DetectionIndex+1)))== Detected_spindles_list(2,DetectionIndex+1)-DetectedSpindleStop) 
                    plot(time(DetectedSpindleStop:Detected_spindles_list(2,DetectionIndex+1)),ElData(DetectedSpindleStop:Detected_spindles_list(2,DetectionIndex+1)),'g');
                    UpdatedSpindleArray(DetectedSpindleStop:Detected_spindles_list(2,DetectionIndex+1)) = ones(1,Detected_spindles_list(2,DetectionIndex+1)-DetectedSpindleStop+1);
                    lockGreen = Detected_spindles_list(2,DetectionIndex+1);
                end
            % Short event that can be put together to make a larger one
            % (only if spindle detected)
            elseif (sum(Detected_spindles_array(DetectedSpindleStart:DetectedSpindleStop))>0)
                %plot(time(DetectedSpindleStart:DetectedSpindleStop),ElData(DetectedSpindleStart:DetectedSpindleStop),'g');
                if ((DetectionIndex)>1) && ((DetectedSpindleStart-Detected_spindles_list(2,DetectionIndex-1))<Parameters.FusionMinTime) && (sum(Detected_spindles_array(Detected_spindles_list(1,DetectionIndex-1):DetectedSpindleStart))== DetectedSpindleStart-Detected_spindles_list(1,DetectionIndex-1)+1)
                    plot(time(Detected_spindles_list(1,DetectionIndex-1):DetectedSpindleStop),ElData(Detected_spindles_list(1,DetectionIndex-1):DetectedSpindleStop),'g');
                    UpdatedSpindleArray(Detected_spindles_list(1,DetectionIndex-1):DetectedSpindleStop) = ones(1,DetectedSpindleStop-Detected_spindles_list(1,DetectionIndex-1)+1);
                end
                if ((DetectionIndex)<length(Detected_spindles_list(1,:))) && ((Detected_spindles_list(1,DetectionIndex+1)-DetectedSpindleStop)<Parameters.FusionMinTime) && (sum(Detected_spindles_array(DetectedSpindleStop+1:Detected_spindles_list(2,DetectionIndex+1)))== Detected_spindles_list(2,DetectionIndex+1)-DetectedSpindleStop) 
                    plot(time(DetectedSpindleStart:Detected_spindles_list(2,DetectionIndex+1)),ElData(DetectedSpindleStart:Detected_spindles_list(2,DetectionIndex+1)),'g');
                    UpdatedSpindleArray(DetectedSpindleStart:Detected_spindles_list(2,DetectionIndex+1)) = ones(1,Detected_spindles_list(2,DetectionIndex+1)-DetectedSpindleStart+1);
                    lockGreen = Detected_spindles_list(2,DetectionIndex+1);
                end
            else
                if DetectedSpindleStart>lockGreen
                    plot(time(DetectedSpindleStart:DetectedSpindleStop),ElData(DetectedSpindleStart:DetectedSpindleStop),'k');
                else
                    lockGreen = 0;
                end
            end
        end
        % Après la boucle sur DetectionIndex
        spindle_mask = UpdatedSpindleArray;
        spindle_diff = diff([0 spindle_mask 0]);
        starts = find(spindle_diff == 1);
        stops  = find(spindle_diff == -1) - 1;
    end
    
    % Stats
    index = 1;
    while index < length(UpdatedSpindleArray)
        if ((UpdatedSpindleArray(index) == 0) && (UpdatedSpindleArray(index+1) == 1)) % We are on rising edge
            CountGlobal(NumElectrode) = CountGlobal(NumElectrode) + 1;
        end
        index = index + 1;
    end
    CountPerM(NumElectrode) = CountGlobal(NumElectrode)/length(ElData)*Fs*60;
    TimePerc(NumElectrode) = 100*sum(UpdatedSpindleArray)/length(ElData);
    
    % RMS and Frequency
    RMSTot = [];
    FreqTot = [];
    CountGlob = 0;
    for i=1:length(UpdatedSpindleArray)
        CurrentPos = find(FeatureChan(NumElectrode).Index == i);
        if (UpdatedSpindleArray(i) == 1) && sum(CurrentPos)>0
            CountGlob = CountGlob + 1;
            RMSTot(CountGlob) = FeatureChan(NumElectrode).RMS(CurrentPos);
            FreqTot(CountGlob) = FeatureChan(NumElectrode).MainFreq(CurrentPos);
        end
    end
    Charact_Spindles(NumElectrode).RMS = RMSTot;
    Charact_Spindles(NumElectrode).Freq = FreqTot;
    
    OffsetCount = OffsetCount + Offset;
    if exist('starts', 'var') && ~isempty(starts)
        for s = 1:length(starts)
            start_idx = starts(s);
            end_idx = stops(s);
            raw_filtered = Filter(Parameters.Fc_ph_display, Parameters.Fc_pb_display, raw_data, Parameters.Fs);  % signal EEG filtré
            d = designfilt('bandpassiir','FilterOrder',4, ...
                'HalfPowerFrequency1',Parameters.SpinFreqPH, ...
                'HalfPowerFrequency2',Parameters.SpinFreqPB, ...
                'SampleRate', Fs);
            analytic = hilbert(filtfilt(d, double(raw_filtered)));
            envelope = abs(analytic);
            env = envelope(start_idx:end_idx);
    
            StoredSpindles(NumElectrode).Spindles(end+1).start_idx  = start_idx;
            StoredSpindles(NumElectrode).Spindles(end).end_idx      = end_idx;
            StoredSpindles(NumElectrode).Spindles(end).start_time   = time(start_idx);
            StoredSpindles(NumElectrode).Spindles(end).end_time     = time(end_idx);
            StoredSpindles(NumElectrode).Spindles(end).duration     = time(end_idx) - time(start_idx);
            StoredSpindles(NumElectrode).Spindles(end).amplitude_envelope = env;
        end
    end
end

OffsetCount = OffsetCount + Offset;
% Xlabel_leg = [Xlabel_leg 'Autom Detected'];
ElData = OffsetCount*ones(1,length(raw_data_Chan(NumElectrode,:)));
Detected_spindles_list = Global_Detected_spindles_list;
if isempty(Detected_spindles_list)
else
    for DetectionIndex = 1:length(Detected_spindles_list(1,:))
        DetectedSpindleStart = Detected_spindles_list(1,DetectionIndex);
        DetectedSpindleStop = Detected_spindles_list(2,DetectionIndex);
        plot(time(DetectedSpindleStart:DetectedSpindleStop),ElData(DetectedSpindleStart:DetectedSpindleStop),'g');
    end
end

xlim([time(1) time(end)]);
ylim([-200 OffsetCount+200]);

set(gca, 'YLimMode', 'auto');    % Permet ensuite au zoom de l’axe X de rescaler Y


% Annotation
% ----------
OffsetCount = 0;

for NumElectrode = 1:length(ElectrodeLabel(:,1))
    nrElectrodeLeft = ElectrodeLabel(NumElectrode,:);
    nrElectrodeLeft = deblank(nrElectrodeLeft);
    
    % Label
    yPlot = OffsetCount;
    axPos = get(gca,'Position'); % gca gets the handle to the current axes
    yMinMax = ylim;
    xAnnotation = 0.07;
    yAnnotation = axPos(2) + ((yPlot - yMinMax(1))/(yMinMax(2)-yMinMax(1))) * axPos(4);
    an = annotation('textbox',[xAnnotation yAnnotation 0.01 0.01],'EdgeColor','none');
    label =[strtrim(nrElectrodeLeft)];
    set(an,'string',nrElectrodeLeft,'FontSize',10);
  
    OffsetCount = OffsetCount + Offset;
end

OffsetCount = OffsetCount + Offset;

% Label
yPlot = OffsetCount;
axPos = get(gca,'Position'); % gca gets the handle to the current axes
yMinMax = ylim;
xAnnotation = 0.07;
yAnnotation = axPos(2) + ((yPlot - yMinMax(1))/(yMinMax(2)-yMinMax(1))) * axPos(4);
an = annotation('textbox',[xAnnotation yAnnotation 0.01 0.01],'EdgeColor','none');
set(an,'string','Autom','FontSize',10);

hold off;

saveas(fig,['Display/Scoring_Overview_Patient_' edf_name '_' 'Detection among derivatations' '.fig']);



