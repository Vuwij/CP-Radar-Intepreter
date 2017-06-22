clear

% Load the library
Lib = ModuleConnector.Library;
Lib.libfunctions

% Input parameters
COM = 'COM4';
FPS = 20;
dataType = 'bb';

% Chip settings
PPS = 26;
DACmin = 949;
DACmax = 1100;
Iterations = 16;
FrameStart = 0; % meters.
FrameStop = 9.75; % meters.

%% CardioRespitory Reading Parameters
% Respitory
RSampleDuration = 10; % seconds
RSample = zeros(1, RSampleDuration * FPS);
RespIndex = 1; % Index of the max of the Radar Signal

% Cardiac
CSampleDuration = 5; % seconds
CSample = zeros(1, CSampleDuration * FPS);

%% Using BasicRadarClassX4
%
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

% Configure frame area
radar.radarInstance.x4driver_set_frame_area(FrameStart,FrameStop);

% Start streaming and subscribe to message_data_float.
radar.start();

tstart = tic;

fh = figure(5);
clf(fh);
ph = plot(0);
th = title('Radar Signals');
ylim([0,1]);
ylim manual;
grid on;

fcr = figure(6);
clf(fcr);
pcr = plot(0);
tcr = title('CardioRespiaratory');

i = 0;
isFirstFrame = true;

while ishandle(fh)
    % Peek message data float
    numPackets = radar.bufferSize();
    if numPackets > 0
        i = i+1;
        % Get frame (uses read_message_data_float)
        [frame, ctr] = radar.GetFrameNormalized();
        
        % Zeros the signal at first
        if isFirstFrame
            average = frame;
            movingAverage = average;
            isFirstFrame = false;
        elseif mod(i,10) == 0 && i <= 50
            movingAverage = (movingAverage + average) / 2;
        end
        frame = frame - movingAverage;
        
        %% Respitory rhythm analysis
        % Record peak for respiratory
        if mod(i, RSampleDuration * FPS) == 0
            [MaxResp, RespIndex] = max(frame);
        end
        
        % Take samples at the Maximum Respiratory index
        RSample = [RSample(2:end) frame(RespIndex)];
        
        % Take the fast fourier transform after each duration
        if mod(i, RSampleDuration * FPS) == 0
            RespFFT = fft(RSample);
            pcr.YData = RSample;
        end
        
        % Cardiac rhythm analysis
        switch dataType
            case 'rf'
                ph.YData = frame;
                %ylim([-1.2 1.2]);
            case 'bb'
                frame = frame(1:end/2) + 1i*frame(end/2 + 1:end);
                ph.YData = abs(frame); 
                %ylim([-0.1 2]);
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