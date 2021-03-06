function [sample_spline] = cubic_spline_3d(sample)
    [slowTime, fastTime] = size(sample);
    sample_spline = zeros(slowTime*4-3, fastTime*4-3);
    
    % Spline on the x axis first
    x = 0:1:fastTime-1;
    xx = 0:.25:fastTime-1;
    for i=1:slowTime
        sample_spline(i,:) = spline(x,sample(i,:),xx);
    end
    
    % Spline on the y axis
    y = 0:1:slowTime-1;
    yy = 0:.25:slowTime-1;
    for i=1:fastTime*4-3
        sample_spline(:,i) = spline(y,sample_spline(1:slowTime,i),yy);
    end
end
