function [RMSLevel,MainFreq] = DataFeatures(nrElectrodeLeft,raw_data,Parameters,fname)

if exist(['ProcessedFeatures\DataFeaturesPat_' fname '_Electrode_' nrElectrodeLeft '.mat'],'file') == 2
    load(['ProcessedFeatures\DataFeaturesPat_' fname '_Electrode_' nrElectrodeLeft],'RMSLevel','MainFreq');
else

    RMSLevel(length(raw_data)) = 0;
    MainFreq(length(raw_data)) = 0;
    
    Hamming_w = hamming(2*Parameters.RMSHalfWindow); % FFT ZP
    NumUniquePts = ceil((Parameters.FFT_nbr_points+1)/2); 
    
    for CurrentWindow = Parameters.RMSHalfWindow:Parameters.FeatureProcessingStep:length(raw_data)-Parameters.RMSHalfWindow
        WindowStart = CurrentWindow-Parameters.RMSHalfWindow+1;
        WindowStop = CurrentWindow+Parameters.RMSHalfWindow;
        CurrentData = raw_data(WindowStart:WindowStop);
        CurrentData = Filter(Parameters.Fc_ph_sleep,Parameters.Fc_pb_sleep,CurrentData,Parameters.Fs);
        
        % RMS level
        RMSLevel_CurrentWindow = std(CurrentData);
        
        % Power estimation around the frequency
        CurrentData_fft = CurrentData.*Hamming_w;
        WindowFFT=fft(CurrentData_fft,Parameters.FFT_nbr_points)/length(CurrentData_fft); % normalizes the data
        WindowFFT = WindowFFT(1:NumUniquePts); 
        WindowFFT = abs(WindowFFT);
        WindowFFT = WindowFFT.^2;  % Take the square of the magnitude of fft of x. 
        
        

        % Max freq
        MinFFTSearch =  round(Parameters.Fc_ph_sleep*Parameters.FFT_nbr_points/Parameters.Fs);
        MaxFFTSearch =  round(Parameters.Fc_pb_sleep*Parameters.FFT_nbr_points/Parameters.Fs); 
        [~,IndexFreq] = max(WindowFFT(MinFFTSearch:MaxFFTSearch));
        MainFreq_CurrentWindow_med = (IndexFreq+MinFFTSearch)*Parameters.Fs/Parameters.FFT_nbr_points;
        
        
        % On comptabilise le tout
        if CurrentWindow<length(raw_data)-Parameters.FeatureProcessingStep
            for fill = 1:Parameters.FeatureProcessingStep
                RMSLevel(CurrentWindow+fill-1) = RMSLevel_CurrentWindow;
                MainFreq(CurrentWindow+fill-1) = MainFreq_CurrentWindow_med;
            end
        end

    end
    
    %save(['ProcessedFeatures\DataFeaturesPat_' fname '_Electrode_' nrElectrodeLeft],'RMSLevel','MainFreq');
end