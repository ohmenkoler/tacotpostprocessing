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
Nfft = BigData.Conf.Acquisition.F_sampling;
p = BigData.H_DPS(2,2)
Z1_mag = p / (BigData.H_ACC(1,2) / (2*pi*47))
Z1_phase = (BigData.phi_DPS(2,2) - (BigData.phi_ACC(1,2)-(pi/2))) * 180/pi
Z2_mag = p / (BigData.H_ACC(2,2) / (2*pi*47))
Z2_phase = (BigData.phi_DPS(2,2) - (BigData.phi_ACC(2,2)+(pi/2))) * 180/pi

Tf_center = mean(BigData.TC{end-avg5lastmin:end,6}) + 273.15
Tf_avg = mean(mean(BigData.TC{end-avg5lastmin:end,5:7})') + 273.15
Ta_center = mean(BigData.TC{end-avg5lastmin:end,12}) + 273.15
Ta_avg = mean(mean(BigData.TC{end-avg5lastmin:end,11:13})') + 273.15

Qf = BigData.Q_c 
Qa = BigData.Q_a

COP_cold = BigData.Q_c / ...
    ((BigData.Conf.Parameters.URIX_Vrms^2 + BigData.Conf.Parameters.UHP_Vrms^2) ...
    / BigData.Conf.Parameters.RCHX_ohm)
COP_carnot = Tf_avg / (Ta_avg - Tf_avg)
COP_coldcarnot = COP_cold / COP_carnot
