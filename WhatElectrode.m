function [EEGElectrode] = WhatElectrode(fname,ArtElectrodes)

% What electrodes have EEG as a beginning?
[Nmb_chans,~,Label] = edfhdr(fname);

count = 0;
for i=1:Nmb_chans
    Electrodes(i,:)=lower(setstr(Label(i,:)));
    %if (Electrodes(i,1) == 'e') && (Electrodes(i,2) == 'e') && (Electrodes(i,3) == 'g')
        CurrentEl = Electrodes(i,:);
        CurrentEl = deblank(CurrentEl);
        ok = 1;
        if ~isempty(ArtElectrodes)
            for j = 1:length(ArtElectrodes)
                if strcmp(CurrentEl, ArtElectrodes{j})
                    ok = 0;
                end
            end
        end
        if ok == 1
            count=count+1;
            EEGElectrode(count,:) = Electrodes(i,:);
        end
    %end
end
