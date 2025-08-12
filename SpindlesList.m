function [Detected_spindles_list,WhatElectrode,Detected_spindles_Tot] = SpindlesList(Detected_spindles,MinElectForDet,EvenMinTime)

Detected_spindles_fusion_Array(length(Detected_spindles(:,1)),length(Detected_spindles(1,:))) = 0;
WhatElectrode = [];

for NumElectrode = 1:length(Detected_spindles(:,1))
    % Spindle fusion (even with short events)
    Detected_spindles_fusion = Detected_spindles(NumElectrode,:);
    Detected_spindles_fusion_ok = Detected_spindles(NumElectrode,:);
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
    
    % Short Event removal
    Detected_spindles_removal = Detected_spindles_fusion_ok;
    index = 1;
    while index < length(Detected_spindles_removal)
        if ((Detected_spindles_removal(index) == 0) && (Detected_spindles_removal(index+1) == 1)) % We are on a rising edge
            FusionCount = 0;
            FusionStartTime = index;
            while ((index < length(Detected_spindles_removal)) && (Detected_spindles_removal(index+1) == 1))
                index = index + 1;
                FusionCount = FusionCount + 1;
            end
            if FusionCount < EvenMinTime
                Detected_spindles_removal(FusionStartTime:index) = zeros(1,FusionCount+1);
            end
        end
        index = index + 1;
    end
    
    Detected_spindles_fusion_Array(NumElectrode,:) = Detected_spindles_removal;
    
end

% We are now working analyzing spindles accross all channels
% Fist looking at how many channels show a spindle at each time point
if length(Detected_spindles_fusion_Array(:,1))>1
    Detected_spindles_Tot = sum(Detected_spindles_fusion_Array);
else
    Detected_spindles_Tot = Detected_spindles_fusion_Array;
end

for index = 1:length(Detected_spindles_Tot)
    if Detected_spindles_Tot(index)>=MinElectForDet
        Detected_spindles_Tot(index)=1;
    else
        Detected_spindles_Tot(index)=0;
    end
end

% The overlap also has to be larger than 0.5s
Detected_spindles_removal = Detected_spindles_Tot;
index = 1;
while index < length(Detected_spindles_removal)
    if ((Detected_spindles_removal(index) == 0) && (Detected_spindles_removal(index+1) == 1)) % We are on a rising edge
        FusionCount = 0;
        FusionStartTime = index;
        while ((index < length(Detected_spindles_removal)) && (Detected_spindles_removal(index+1) == 1))
            index = index + 1;
            FusionCount = FusionCount + 1;
        end
        if FusionCount < EvenMinTime
            Detected_spindles_removal(FusionStartTime:index) = zeros(1,FusionCount+1);
        end
    end
    index = index + 1;
end
Detected_spindles_Tot = Detected_spindles_removal;

Detected_spindles_list = [];
DetectedSpindles = 0;
index = 1;

while index < length(Detected_spindles_Tot)
    if ((Detected_spindles_Tot(index) == 0) && (Detected_spindles_Tot(index+1) == 1)) % We are on rising edge
        DetectedSpindles = DetectedSpindles + 1;
        Detected_spindles_list(1,DetectedSpindles) = index+1;
        for NumElectrode = 1:length(Detected_spindles(:,1))
            if Detected_spindles_fusion_Array(NumElectrode,index+1) == 1
                WhatElectrode(DetectedSpindles,NumElectrode) = 1;
            end
        end
    end
    if ((Detected_spindles_Tot(index) == 1) && (Detected_spindles_Tot(index+1) == 0)) % We are on falling edge
        Detected_spindles_list(2,DetectedSpindles) = index;
    end
    index = index + 1;
end

% if ending with a spindle
if length(Detected_spindles_list) == 1
    Detected_spindles_list(2,1) = index;
elseif (length(Detected_spindles_list)>1) && (Detected_spindles_list(2,end) == 0)
    Detected_spindles_list(2,end) = index;
end
