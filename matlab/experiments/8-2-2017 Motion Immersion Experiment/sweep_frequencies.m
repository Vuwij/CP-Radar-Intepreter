%% Experiment - Differences in frequency of single layer (sweep)
% This experiemnt collects datas a certin liquid is increased in thickness
% with different settings with the radar. The objective is to have
% a function of the resulting movement of the radar with respect to
% frequency

% Create stuff %24 cm
clear

% Material data
Folder = '../8-2-2017 Protocol2';
Material = 'chicken_water_5';
Depth = 'baseline_nochicken_1';
mkdir(Folder, Material);
FileName = strcat(Folder, '/', Material, '/', Depth, '.mat');
delete(FileName);
save(FileName);

% Paths
addpath('../../ModuleConnector_WIN/matlab');
addpath('../../ModuleConnector_WIN/lib');
addpath('../../ModuleConnector_WIN/include');
addpath('..');
Lib = ModuleConnector.Library;
Lib.libfunctions

% Global radar settings
global FPS Duration PPS DACmin DACmax Iterations FrameStart FrameStop COM dataType radar;
FPS = 10;
Duration = 0.1;
PPS = 26;
DACmin = 949;
DACmax = 1400;
Iterations = 16;
FrameStart = 0.0; % meters.
FrameStop = 9.9; % meters.
COM = char(seriallist);
dataType = 'bb';

%% Using BasicRadarClassX4
radar = BasicRadarClassX4(COM,FPS,dataType);
radar.open();
radar.init();

% mtable(end+1,:) = mtable(end,:);
% mtable(end,1) = {Depth};
% mtablebb(end+1,:) = mtablebb(end,:);
% mtablebb(end,1) = {Depth};

% Sweep frequencies
for ftype=[0,1]
    radar.radarInstance.x4driver_set_downconversion(ftype);
    if ftype == 0
        dataType = 'rf';
    else
        dataType = 'bb';
    end
    
    DACmax = 1400;
    for DACmin = [0]
        for freq=[3,4]
            data = acquire_radar_data(FPS, Duration, freq);

            varname = strcat(dataType, num2str(DACmin), '_', num2str(DACmax), 'f', num2str(freq));
            str = [varname,'= data;'];
            eval(str);
            save(FileName,varname,'-append');
        end
    end
end


radar.close();
clear