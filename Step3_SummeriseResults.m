clear;
close all;
%% load all
[filename,filepath] = uigetfile('*.mat','Select a pair of .mat files to process',...
    'C:\Users\mfontbon\Desktop\sDrive\Manips\ConvectionNaturelle\PerformancesStudy',...
    'MultiSelect','on');
if ~iscell(filename)
    filename = cellstr(filename);
end

for nfile = 1:length(filename)
    tmp = strcat(filepath,filename(nfile));
    BigData(nfile) = load(tmp{:});
end
%%

avg5lastmin = 5 * 60 * BigData.Conf.Acquisition.F_resampling;

Orientation = BigData.Conf.Parameters.Orientation

xi1 = max(abs(BigData.Acc{:,1} / ((2*pi*47)^2))) * 1000
xi2 = max(abs(BigData.Acc{:,2} / ((2*pi*47)^2))) * 1000

DR = BigData.H_DPS(2,2) / BigData.Conf.Parameters.GasStaticPressure * 100

p = BigData.H_DPS(2,2)
v1 = max(abs(BigData.Acc{:,1} / (2*pi*47)))
Z1 = fft(BigData.DPS{:,2},BigData.Conf.Acquisition.F_sampling) ...
    ./ fft(BigData.Acc{:,1},BigData.Conf.Acquisition.F_sampling);
Z1 = Z1()
Z1_mag = abs(Z1())
v2 = max(abs(BigData.Acc{:,2} / (2*pi*47)))
Z2(nfile)

Tf_center = mean(BigData.TC{end-avg5lastmin:end,6})
Tf_avg = mean(mean(BigData.TC{end-avg5lastmin:end,5:7})')
Ta_center = mean(BigData.TC{end-avg5lastmin:end,12})
Ta_avg = mean(mean(BigData.TC{end-avg5lastmin:end,11:13})')

Qf = BigData.Q_c 
Qa = BigData.Q_a

