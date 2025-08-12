function [SignleChanSpindleList] = SpindlesListOneChan(FeatureChan,EvenMinTime)

for NumElectrode = 1:length(FeatureChan)
    
    % Spindle fusion (even with short events)
    Detected_spindles_fusion = FeatureChan(NumElectrode).Detected_spindles;
    Detected_spindles_fusion_ok = FeatureChan(NumElectrode).Detected_spindles;
    index = 1;
    PE_Start = 1;
    while index < length(Detected_spindles_fusion)
        if ((Detected_spindles_fusion(index) == 0) && (Detected_spindles_fusion(index+1) == 1)) % We are on a rising edge
            PE_Start = index+1;
        end
        if ((Detected_spindles_fusion(index) == 1) && (Detected_spindles_fusion(index+1) == 0)) % We are on a falling edge
            PE_Stop = index;
            EventTime = PE_Stop-PE_Start;
            if EventTime>EvenMinTime
                EventTime=EvenMinTime;
            end
            % Fuse to the right
            FusionCount = 0;
            Rightindex = PE_Stop+1;
            while ((Rightindex < length(Detected_spindles_fusion)) && (Detected_spindles_fusion(Rightindex+1) == 0))
                Rightindex = Rightindex + 1;
                FusionCount = FusionCount + 1;
            end
            if (FusionCount < EventTime) && (Rightindex < length(Detected_spindles_fusion))
                Detected_spindles_fusion_ok(PE_Stop:Rightindex) = ones(1,FusionCount+2);
            end
            % Fuse to the left
            FusionCount = 0;
            Leftindex = PE_Start-1;
            while ((Leftindex > 0) && (Detected_spindles_fusion(Leftindex) == 0))
                Leftindex = Leftindex - 1;
                FusionCount = FusionCount + 1;
            end
            if (FusionCount < EventTime) && (Leftindex > 0)
                Detected_spindles_fusion_ok(Leftindex:PE_Start) = ones(1,FusionCount+2);
            end
        end
        index = index + 1;
    end
    
    FeatureChan(NumElectrode).Detected_spindles = Detected_spindles_fusion_ok;
    
    SignleChanSpindleList(NumElectrode).Detected_spindles_list = [];
    DetectedSpindles = 0;
    index = 1;
    while index < length(FeatureChan(NumElectrode).Detected_spindles)
        if ((FeatureChan(NumElectrode).Detected_spindles(index) == 0) && (FeatureChan(NumElectrode).Detected_spindles(index+1) == 1)) % We are on rising edge
            DetectedSpindles = DetectedSpindles + 1;
            SignleChanSpindleList(NumElectrode).Detected_spindles_list(1,DetectedSpindles) = index;
        end
        if ((FeatureChan(NumElectrode).Detected_spindles(index) == 1) && (FeatureChan(NumElectrode).Detected_spindles(index+1) == 0)) % We are on falling edge
            SignleChanSpindleList(NumElectrode).Detected_spindles_list(2,DetectedSpindles) = index;
        end
        index = index + 1;
    end
end