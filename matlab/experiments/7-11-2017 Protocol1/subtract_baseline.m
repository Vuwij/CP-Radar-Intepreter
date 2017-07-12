%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Script to visualize the collected radar data along with the corresponding
% baseline, as well as the baseline subtracted from the radar data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear variables;
close all;
clc;
%% Choosing a setting

%You need to be in the '7-11-2017 Protocol1' folder

%Folder can be "saline_only" or "chicken5x4x1cm" or "screw-2mm-0.8cm" or "screw-3mm-1.2cm" or "screw-3mm-1.5cm"
folder = 'saline_only';
height = '15.5cm';
%Frequency can be...
    %2 (5.832 GHz)
    %3 (7.29 GHz))
    %4 (8.748 GHz)
    %5 (10.206 GHz)
frequency = '2';
%Specify the dacmin and dacmax values (default: dacmin = 949, dacmax = 1100)
dacmin = '949';
dacmax = '1100';
%Specify whether to plot the baseband or rf data"
mode = 'bb';
%Specify which of the 5 fast time sequences
fts = 1;
%Specify whether the x axis is in bins or meters
x_units='bins';
%% Load the data
data = obtain_data(folder, height, frequency, dacmin, dacmax, mode, fts);
baseline=obtain_data('baseline','zero',frequency,dacmin,dacmax,mode,fts);
baseline = [baseline(1:18); zeros(length(baseline)-18,1)];
%% Uncalibrated range and time vectors
c = 299792458;
N=length(baseline);
fs = 2.916*10^9; % sampling rate of baseband data (number obtained from Xethru forum)

t_vec = 0:1/fs:(N-1)/fs;
r_vec = c/2 * t_vec;
r_vec_cm = r_vec * 100;
%% Find peak location in baseline data and calibrate range zero
[m ind] = max(abs(baseline));

r_min = r_vec(2) - r_vec(1);
r_vec = r_vec - (ind-1)*r_min;
r_vec_cm = r_vec * 100;

%% Plot the data before subtracting and baseline on the same subfigure
figure
subplot(2,1,1)
plot(r_vec_cm,abs(data));
hold on;
plot(r_vec_cm,abs(baseline));
%% Plot the data after subtracting on another subfigure 
subplot(2,1,2)
plot(r_vec_cm,abs(data-baseline));

