function [] = DataAnnotation(Parameters,Global_Detected_spindles_list,fname)

Fs = Parameters.Fs;
[~,FileName] = fileparts(fname);
copyfile(fname, [FileName '.edf'], 'f');


manual_onset = seconds(15);
manual_duration = seconds(5);
manual_annotation = "test";

if isempty(Global_Detected_spindles_list)

else
    Onset(length(Global_Detected_spindles_list)) = seconds(0);
    Annotations(length(Global_Detected_spindles_list)) = "Spindle";
    Duration(length(Global_Detected_spindles_list)) = seconds(0);
        for DetectionIndex = 1:length(Global_Detected_spindles_list(1,:))
            DetectedSpindleStart = Global_Detected_spindles_list(1,DetectionIndex);
            DetectedSpindleStop = Global_Detected_spindles_list(2,DetectionIndex);
            Onset(DetectionIndex) = seconds(DetectedSpindleStart/Fs);
            Annotations(DetectionIndex) = "Spindle";
            Duration(DetectionIndex) = seconds((DetectedSpindleStop-DetectedSpindleStart)/Fs);
        end
end
%Onset(5) = manual_onset;
%Annotations(5) = manual_annotation;
%Duration(5) = manual_duration;

Onset = Onset';
Annotations = Annotations';
Duration = Duration';
tsal = timetable(Onset,Annotations,Duration);
edfw = edfwrite(fname);
addAnnotations(edfw,tsal);
%disp(size(Onset));
%disp(size(Annotations));
%disp(size(Duration));
end 
