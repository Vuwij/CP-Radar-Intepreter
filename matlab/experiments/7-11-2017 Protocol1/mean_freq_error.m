%This script plots the errors in distance for each frequency band as a
%function of the DAC setting
%It also provides the mean error for each frequency band as well as the
%standard deviation
figure
for k = linspace(2,5,4)
    errors=zeros(1,12); %vector to store the errors
    for i = linspace(0,1000,11)
        greatest_peak = obtain_greatest_peak('saline_only','29.6cm',int2str(k),int2str(i),'1400');
        errors(i/100 + 1) = abs(29.6-greatest_peak(1));
    end
    greatest_peak = obtain_greatest_peak('saline_only','29.6cm',int2str(k),'949','1100');
    errors(12) = abs(29.6-greatest_peak(1));
    mean(errors)
    std(errors)
    subplot(3,4,k-1);
    plot(errors);
    title(strcat('29.6cm-',num2str(1.458*k+2.916),'GHz'));
end
    
for k = linspace(2,5,4)
    errors=zeros(1,12); %vector to store the errors
    for i = linspace(0,1000,11)
        greatest_peak = obtain_greatest_peak('saline_only','21.6cm',int2str(k),int2str(i),'1400');
        errors(i/100 + 1) = abs(21.6-greatest_peak(1));
    end
    greatest_peak = obtain_greatest_peak('saline_only','21.6cm',int2str(k),'949','1100');
    errors(12) = abs(21.6-greatest_peak(1));
    mean(errors)
    std(errors)
    subplot(3,4,4+k-1);
    plot(errors);
    title(strcat('21.6cm-',num2str(1.458*k+2.916),'GHz'));
end

for k = linspace(2,5,4)
    errors=zeros(1,12); %vector to store the errors
    for i = linspace(0,1000,11)
        greatest_peak = obtain_greatest_peak('saline_only','15.5cm',int2str(k),int2str(i),'1400');
        errors(i/100 + 1) = abs(15.5-greatest_peak(1));
    end
    greatest_peak = obtain_greatest_peak('saline_only','15.5cm',int2str(k),'949','1100');
    errors(12) = abs(15.5-greatest_peak(1));
    mean(errors)
    std(errors)
    subplot(3,4,8+k-1);
    plot(errors);
    title(strcat('15.5cm-',num2str(1.458*k+2.916),'GHz'));
end
