clear;
clc
%% load all
[filename,filepath] = uigetfile('*V2*.mat','Select a .mat files to process',...
    'C:\Users\mfontbon\Desktop\sDrive\Manips\ConvectionNaturelle\PerformancesStudy',...
    'MultiSelect','on');

filename_0 = uigetfile('*V2*.mat','Select a .mat initial files to process',...
    filepath);

if ~iscell(filename)
    filename = cellstr(filename);
    filename_0 = cellstr(filename_0);
end

for nfile = 1:length(filename)
    tmp = strcat(filepath,filename(nfile));
    BigData(nfile) = load(tmp{:});
    tmp_0 = strcat(filepath,filename_0(nfile));
    BigData_0(nfile) = load(tmp_0{:});
end
%%
avg5lastmin = 5 * 60 * BigData.Conf.Acquisition.F_resampling;

Orientation = BigData.Conf.Parameters.Orientation

xi1 = max(abs(BigData.Acc{:,1} / ((2*pi*47)^2))) * 1000
xi2 = max(abs(BigData.Acc{:,2} / ((2*pi*47)^2))) * 1000

DR = BigData.H_DPS(2,2) / BigData.Conf.Parameters.GasStaticPressure / 1e5 * 100
Nfft = BigData.Conf.Acquisition.F_sampling;
p = BigData.H_DPS(2,2)
Z1_mag = p / (BigData.H_ACC(1,2) / (2*pi*47))
Z2_mag = p / (BigData.H_ACC(2,2) / (2*pi*47))
Z1_phase = (BigData.phi_DPS(2,2) - (BigData.phi_ACC(1,2)-(pi/2))) * 180/pi
Z2_phase = (BigData.phi_DPS(2,2) - (BigData.phi_ACC(2,2)+(pi/2))) * 180/pi

disp('-- Raw temperature --')

% Ta_center = mean(BigData.TC{end-avg5lastmin:end,12}) + 273.15
% Ta_avg = mean(mean(BigData.TC{end-avg5lastmin:end,11:13})') + 273.15
% Tf_center = mean(BigData.TC{end-avg5lastmin:end,6}) + 273.15
% Tf_avg = mean(mean(BigData.TC{end-avg5lastmin:end,5:7})') + 273.15
% 
% T_rix = mean(BigData.TC{end-avg5lastmin:end,1}) + 273.15

disp('-- Temperature - initial value --')

Ta_avg_0beg = mean(mean(BigData.TC_0beg{end-avg5lastmin:end,11:13}),2)
Tf_avg_0beg = mean(mean(BigData.TC_0beg{end-avg5lastmin:end,5:7}),2)
% 
T_rix_0beg = mean(BigData.TC_0beg{end-avg5lastmin:end,1})

disp('-- Temperature - WaterOnly temperature --')

Ta_avg_0WO = mean(mean(BigData.TC{end-avg5lastmin:end,11:13} ...
    - BigData_0.TC{end,11:13}),2)
Tf_avg_0WO = mean(mean(BigData.TC{end-avg5lastmin:end,5:7} ...
    - BigData_0.TC{end,5:7}),2)

T_rix_0WO = mean(BigData.TC{end-avg5lastmin:end,1} ...
    - BigData_0.TC{end,1})

Qf = BigData.Q_c 
Qa = BigData.Q_a

% COP_cold = BigData.Q_c / ...
%     ((max(100*BigData.UIRix{:,1})*max(BigData.UIRix{:,2}))/2 + ...
%     BigData.Conf.Parameters.UHP_Vrms^2 / 4)
% COP_carnot = Tf_avg / (Ta_avg - Tf_avg)
% COP_coldcarnot = 100 * COP_cold / COP_carnot

%%