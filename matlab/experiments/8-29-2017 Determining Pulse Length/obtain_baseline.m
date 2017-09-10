function [baseline] = obtain_baseline(mode,frequency)

    table_name = strcat(mode,'0_1400f',int2str(frequency));
    file_name = strcat('baseline/zero6.mat');
    S = load(file_name);
    baseline = S.(table_name);

end
