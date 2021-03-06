% Paths
addpath('../../ModuleConnector_WIN/matlab');
addpath('../../ModuleConnector_WIN/lib');
addpath('../../ModuleConnector_WIN/include');
addpath('..');
addpath('../functions');
Lib = ModuleConnector.Library;
Lib.libfunctions

% Input parameters
COM = 'COM6'; %char(seriallist)
FPS = 5;
dataType = 'bb'; % bb seems to downsample 186 , rf is 1520

% Chip settings
PPS = 26;
DACmin = 0;%949
DACmax = 1400;%1100
Iterations = 16;%16Avergaging?
FrameStart = 0.0; % meters.
FrameStop = 9.9; % meters.

%% Using BasicRadarClassX4
radar = BasicRadarClassX4(COM,FPS,dataType);

% Open radar.
radar.open();

% Initialize radar.
radar.init();

% Configure X4 chip.
radar.radarInstance.x4driver_set_pulsesperstep(PPS);
radar.radarInstance.x4driver_set_dac_min(DACmin);
radar.radarInstance.x4driver_set_dac_max(DACmax);
radar.radarInstance.x4driver_set_iterations(Iterations);
radar.radarInstance.x4driver_set_tx_center_frequency(3);
radar.radarInstance.x4driver_set_pif_register(101, 48); %Frequency Register
% Frequency Registers
% 0 - 2.9 Ghz
% 16 - 4.314 Ghz
% 32 - 5.832 Ghz
% 48 - 7.29 Ghz
% 64 - 8.748 Ghz
% 80 - 10.206 Ghz
% 96 - 11.664 Ghz
% 112 - 13.122 Ghz

% Configure frame area
radar.radarInstance.x4driver_set_frame_area(FrameStart,FrameStop);
% Read back actual set frame area
[frameStart, frameStop] = radar.radarInstance.x4driver_get_frame_area();

% Start streaming and subscribe to message_data_float.
radar.start();

tstart = tic;

fh = figure(5);
clf(fh);
ph = plot(0);
ylabel('Normalized amplitude');
xlabel('Range [m]');

th = title('');
grid on;

i = 0;

while ishandle(fh)
    % Peek message data float
    numPackets = radar.bufferSize();
    if numPackets > 0
        i = i+1;
        % Get frame (uses read_message_data_float)
        [frame, ctr] = radar.GetFrameNormalized();
        
        if i == 1
            numBins = length(frame);
            if strcmp('bb', dataType)
                numBins = numBins/2;
            end
            binLength = (frameStop-frameStart)/(numBins-1);
            rangeVec = (0:numBins-1)*binLength + frameStart;
            ph.XData = rangeVec;
        end
        
        switch dataType
            
            case 'rf'
                frame=downconvert(frame',3);
                baseline=obtain_baseline_manual_downconversion(3);
                frame=frame-baseline;
                ph.YData = abs(frame)';
                ylim([0 1.2]);
            case 'bb'
                frame = frame(1:end/2) + 1i*frame(end/2 + 1:end);
                baseline=obtain_baseline('bb',3)';
                frame=frame-baseline;
                ph.YData = abs(frame);
                ylim([-0.1 2]);
        end
        
        th.String = ['FrameNo: ' num2str(i) ' - Length: ' num2str(length(frame)) ' - FrameCtr: ' num2str(ctr)];
        
        drawnow;
        if mod(i,100)==0
            disp(['Packets available: ' num2str(radar.bufferSize())]);
        end
        
    end
        
end

radar.stop();

tspent = toc(tstart);

framesRead = i;
totFramesFromChip = ctr;

FPS_est = framesRead/tspent;

framesDropped = ctr-i;

disp(['Read ' num2str(framesRead) ' frames. A total of ' num2str(totFramesFromChip) ' were sent from chip. Frames dropped: ' num2str(framesDropped)]);
disp(['Estimated FPS: ' num2str(FPS_est) ', should be: ' num2str(FPS)]);

radar.close();
clear radar frame