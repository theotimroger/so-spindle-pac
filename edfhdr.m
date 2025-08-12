function [Nmb_chans,Fs,Label,Dim,Coef,S_date,S_time,Blck_size,pat_id,rec_id,transd,prefilt] = edfhdr(fname)

%	[Nmb_chans,Fs,Label,Dim,Coef,S_date,S_time,Blck_size,pat_id,rec_id,transd,prefilt] = edfhdr(fname)
%
%	Reads EDF file header
%
%   in:	fname		file name
%
%  out:	Nmb_chans	Number of channels
%	Fs		sampling frequency, vector
%	Label		Signal label, string matrix
%	Dim		Signal dimension, string matrix
%	Coef		Scaling coefficients, matrix [PhysMin PhysMax DigMin DigMax]
%	S_date		Date of the starting time of the recording [dd:mm:yy]
%	St_time		Time of the beginning of the recording [hh:mm:ss]
%	Blck_size	Data block size
%	ver		version of the data
%	pat_id		patient identification
%	rec_id		record identification
%	transd		transducer type
%	prefilt		prefiltering

%	(c) Ilkka Korhonen 14.04.1997 
%	    03.10.2000 IKo fname may be file handle

if nargin<1;fname=[];end
if isempty(fname)
	[fileout,pathout] = uigetfile('*.rec','Select EDF file');
	fname = [pathout,fileout];
end
if any(fname=='*')
	[fileout,pathout] = uigetfile(fname,'Select EDF file');
	fname = [pathout,fileout];
end
if length(fname)>1
        fid = fopen(fname,'r');        
else
        fid = fname;
end
if fid < 0
	error('Cannot open file ! Check the filename !');
end

% Scan header

fseek(fid,0,'bof');

ver = setstr(fread(fid,8,'char')');
pat_id = setstr(fread(fid,80,'char')');
rec_id = setstr(fread(fid,80,'char')');
S_date = setstr(fread(fid,8,'char')');
S_time = setstr(fread(fid,8,'char')');
Hdr_size   = sscanf(setstr(fread(fid,8,'char')'),'%d');
fseek(fid,52,'cof');
Blck_size  = sscanf(setstr(fread(fid,8,'char')'),'%d');
Nmb_chans  = sscanf(setstr(fread(fid,4,'char')'),'%d');

Fs = zeros(Nmb_chans,1);
Label = ones(Nmb_chans,16)*' ';
Dim = ones(Nmb_chans,8)*' ';
Coef = zeros(Nmb_chans,4);
transd = ones(Nmb_chans,80)*' ';
prefilt = ones(Nmb_chans,80)*' ';

for i=1:Nmb_chans
	Label(i,:) = setstr(fread(fid,16,'char')');
end
for i=1:Nmb_chans
	transd(i,:) = setstr(fread(fid,80,'char')');
end
for i=1:Nmb_chans
	Dim(i,:) = setstr(fread(fid,8,'char')');
end
for i=1:Nmb_chans
	Coef(i,1) = sscanf(setstr(fread(fid,8,'char')'),'%f');
end
for i=1:Nmb_chans
	Coef(i,2) = sscanf(setstr(fread(fid,8,'char')'),'%f');
end
for i=1:Nmb_chans
	Coef(i,3) = sscanf(setstr(fread(fid,8,'char')'),'%f');
end
for i=1:Nmb_chans
	Coef(i,4) = sscanf(setstr(fread(fid,8,'char')'),'%f');
end
for i=1:Nmb_chans
	prefilt(i,:) = setstr(fread(fid,80,'char')');
end
for i=1:Nmb_chans
	Fs(i)  = sscanf(setstr(fread(fid,8,'char')'),'%d')/Blck_size;
end

fclose(fid);