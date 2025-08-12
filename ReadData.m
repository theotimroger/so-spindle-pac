function [data] = ReadData(timeIn,timeOut,nrElectrodeLeft,nrElectrodeRight,fname)

% Charger les infos EDF
hdr = edfinfo(fname);

% Liste des électrodes présentes dans le fichier
labels = hdr.SignalLabels;  % Cell array de noms

% if(strcmp(nrElectrodeRight,'A1')|| strcmp(nrElectrodeRight,'A2')) 
%     [xL,~,~,~,~,~,~,~,~] = Readedf(timeIn,timeOut,nrElectrodeLeft,fname);    
%     data = -xL;
% else
[xL,~,~,~,~,~,~,~,~] = Readedf(timeIn,timeOut,nrElectrodeLeft,fname); 
if ~any(strcmpi(nrElectrodeRight, labels)) && ~isempty(nrElectrodeRight)
    [xR,~,~,~,~,~,~,~,~] = Readedf(timeIn,timeOut,nrElectrodeRight,fname);    
    data = xL-xR;
else
    data = xL;
end
% end
