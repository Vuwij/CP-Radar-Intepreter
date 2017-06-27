%% Calculates the frequency/angularvelocity dependence graph
% Equation 7, 8 of http://images.remss.com/papers/rsspubs/Meissner_TGRS_2004_dielectric.pdf
% Graph should look like figure 3
% To test, enter the variables in the command window for the function and
% press play

%Angular velocity is in rad/s
function[y] = calculate_dielectric_values(material_index, temperature, ang_vel_min, ang_vel_max, precision)
    
    % Vector of angular velocities 
    x = ang_vel_min:precision:ang_vel_max; 
    % Convert angular velocities to frequencies
    f = x*(1/(2*pi));
    
    p1=calculate_episilon_s(T); % ?_s
    p2=calculate_epsilon_1(T); % ?_1
    p3=calculate_v_1(T); % ?_1
    p4=calculate_epsilon_2(T); % ?_inf
    p5=calculate_v_2(T); % ?_2
    
    y=(p1-p2)/(1+1i*f/p3)+(p2-p4)/(1+1i*f/p5)+p4;
    
     
    plot(f,y);
    
    % Finds values in the Material Dieletric Properties Table found in materials/MaterialData and return a graph
    load('../materials/MaterialData');
    
    
end

function e = calculate_epsilon_s(T)
    e = (3.70886*(10^4)-8.2168*10*T)/(4.21854*100+T);
end

function e = calculate_epsilon_1(T)
    load('../materials/MaterialData');
    a_0=MaterialData.MaterialDielectricProperties{1,1};
    a_1=MaterialData.MaterialDielectricProperties{1,2};
    a_2=MaterialData.MaterialDielectricProperties{1,3};
    
    e = a_0+a_1*T+a_2*T*T;
    
end

function v = calculate_v_1(T)
    load('../materials/MaterialData');
    a_3=MaterialData.MaterialDielectricProperties{1,4};
    a_4=MaterialData.MaterialDielectricProperties{1,5};
    a_5=MaterialData.MaterialDielectricProperties{1,6};
    
    v = (45+T)/(a_3+a_4*T+a_5*T*T);
    
end

function e = calculate_epsilon_2(T)
    load('../materials/MaterialData');
    a_6=MaterialData.MaterialDielectricProperties{1,7};
    a_7=MaterialData.MaterialDielectricProperties{1,8};
    
    e = a_6+a_7*T;
end

function v = calculate_v_2(T)
load('../materials/MaterialData');
    a_8=MaterialData.MaterialDielectricProperties{1,9};
    a_9=MaterialData.MaterialDielectricProperties{1,10};
    a_10=MaterialData.MaterialDielectricProperties{1,11};
    
    v = (45+T)/(a_8+a_9*T+a_10*T*T);

end