clear

[BigData,Conf.Acquisition.F_sampling] = importFILES;

if width(BigData) == 18
    SelectTC = 1:16;
    SelectPT = [17 18];
else
    SelectTC = 9:24;
    SelectPT = [25 26];
    SelectAcc = [8 30];
    SelectDPS = 1:4;
    SelectSPS = [5 6];
    SelectUIRix = [28 27];
    SelectCHXtrig = 7;
end

T_end = 3500;                                              % Total duration of measurement in s.
BigData = BigData(1:Conf.Acquisition.F_sampling*T_end,:);    % Resizing to have same length for all

%% Configuration of measurement
Conf.Parameters.WaterAHX_lperminute = 7;
Conf.Parameters.GasMix = '65%He-35%Ar';
Conf.Parameters.GasStaticPressure = 40;
Conf.Parameters.F_operation = 47;
Conf.Parameters.RegPoros = 68;
Conf.Parameters.rh = 2.81e-5;
Conf.Parameters.GantoisRef = '102045';
Conf.Parameters.RCHX_ohm = 22.4;
Conf.Parameters.CanisterType = 'Inox';
Conf.Parameters.Cpwater = 4185;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Conf.Acquisition.Iteration = 3;
Conf.Parameters.Orientation = 'V1';
Conf.Acquisition.ManipType = 'Acou';
Conf.Acquisition.Acq = 'Transient';
Conf.Acquisition.Amplitude = 'Mid';
Conf.Parameters.UCHX_Vrms = 0;
switch Conf.Acquisition.Amplitude
    case {'Low','Lo','low','lo'}
        Conf.Parameters.URIX_Vrms = 13;
        Conf.Parameters.UHP_Vrms = .7;
    case {'Mid','Medium','mid','medium'}
        Conf.Parameters.URIX_Vrms = 66;
        Conf.Parameters.UHP_Vrms = 4;
    case {'Hi','High','hi','high'}
        Conf.Parameters.URIX_Vrms = 116;
        Conf.Parameters.UHP_Vrms = 7;
    case 'Off'
        Conf.Parameters.URIX_Vrms = 0;
        Conf.Parameters.UHP_Vrms = 0;
end
Conf.Parameters.PhiRix = 0;
Conf.Parameters.PhiHP = -60;

%% Re sampling
Conf.Acquisition.F_resampling = .1;%fix(Conf.Acquisition.F_sampling/1000);
N_resample = fix(Conf.Acquisition.F_sampling/Conf.Acquisition.F_resampling);

T_operation = 1/Conf.Parameters.F_operation;
N_end = fix(Conf.Acquisition.F_sampling * 20 * T_operation);
N_beg = 10 * Conf.Acquisition.F_sampling;

Acc = BigData(end-N_end:end,SelectAcc);
DPS = BigData(end-N_end:end,SelectDPS);
UIRix = BigData(end-N_end:end,SelectUIRix);

CHXTrig = BigData(:,SelectCHXtrig);

TC = BigData(:,SelectTC);
TA_core = TC(:,2:end);
TC_0beg = TC - mean(TC{1:N_beg,:});
TA_core0beg = TC_0beg(:,2:end);
PT = BigData(:,SelectPT);
SPS = BigData(:,SelectSPS);

TC = TC(1:N_resample:end,:);
TA_core = TA_core(1:N_resample:end,:);
TC_0beg = TC_0beg(1:N_resample:end,:);
TA_core0beg = TA_core0beg(1:N_resample:end,:);
PT = PT(1:N_resample:end,:);
SPS = SPS(1:N_resample:end,:);

%% Calculations of heat flows
mdot = Conf.Parameters.WaterAHX_lperminute / 60 / 1000 * 1000;   % kg/s
Q_a_t = Conf.Parameters.Cpwater * mdot * (PT{:,2} - PT{:,1});
Q_a = mean(Q_a_t(end-50:end));
Q_c = Conf.Parameters.UCHX_Vrms^2/Conf.Parameters.RCHX_ohm;

fig = uifigure('HandleVisibility','on');
selection = uiconfirm(fig,'What to do with this measurement?',...
    'Measurement type',"Options",...
    ["Save as WaterOnly exp","Load WaterOnly","Cancel"], ...
    "DefaultOption",2,"CancelOption",3);
switch selection
    case 'Save as WaterOnly exp'
        Q_c = 'WaterOnly';
    case 'Load WaterOnly'
        [file2load,path2load] = uigetfile("*QcWaterOnly*.mat",...
            'Select a WaterOnly reference file to process',...
            'Z:\Martin\Measurements\TACOT\V2_AddedSensors');
        WaterOnly = load([path2load file2load]);
        Q_a = Q_a - WaterOnly.Q_a;
    case 'Cancel'
        % return
end

%% Calculation of pressure and accelerations amplitudes
phi=0;
for ii = 1:4
    [f_sp_DPS,sp_DPS(ii,:),H_DPS(ii,:),phi_DPS(ii,:)]=Detection_synchrone(...
        DPS{:,ii}.',seconds(DPS.Time),1,1024,Conf.Acquisition.F_sampling,Conf.Parameters.F_operation,phi,5);
end

for jj = [1 2]
    [f_sp_ACC,sp_ACC(jj,:),H_ACC(jj,:),phi_ACC(jj,:)]=Detection_synchrone(...
        Acc{:,jj}.',seconds(Acc.Time),1,1024,Conf.Acquisition.F_sampling,Conf.Parameters.F_operation,phi,5);
end

Conf.Parameters.DriveRatio = 100 * H_DPS(2,2) / (Conf.Parameters.GasStaticPressure * 1e5);

%% Global saving location
SAVE_PATH = uigetdir('Z:\Martin\Measurements\TACOT\V2_AddedSensors',"Where to store things?");



%% Saving postprocessed .mat files
matfilename = ['Rix' Conf.Acquisition.Amplitude '_PhaseRIXHP' num2str(Conf.Parameters.PhiHP-Conf.Parameters.PhiRix)...
    '°_Orientation' Conf.Parameters.Orientation '_Qc' num2str(Q_c,'%.0f') 'W_Serie' num2str(Conf.Acquisition.Iteration)];

fig2 = uifigure('HandleVisibility','on');
selection2 = uiconfirm(fig2,['Confirm the .mat file name: ' newline matfilename '.mat'],...
    '.mat File name confirmation');
switch selection2
    case 'OK'
        save([SAVE_PATH  '\' matfilename '.mat'],'TC','TC_0beg','PT','Acc','UIRix','DPS','SPS','Q_a','Q_c','Conf','H*','phi*') 
    case 'Cancel'
        % return
end




%% Exporting as textfiles
save_txt = uifigure();
selection3 = uiconfirm(save_txt,'Save .txt data ?', 'Save ?',"Options",["Yes","No"]);
switch selection3
    case 'Yes'
        mkdir(SAVE_PATH,'TextData\')
        savepathtxt = [SAVE_PATH '\TextData\'];
        % addpath(savepathtxt)

        for n = 1:16
            filenameTCtxt = [savepathtxt 'data_TC' num2str(n-1) '_Rix' Conf.Acquisition.Amplitude '_PhaseRIXHP' ...
                num2str(Conf.Parameters.PhiHP-Conf.Parameters.PhiRix)...
                    '°_Orientation' Conf.Parameters.Orientation '_Qc' num2str(Q_c,'%.0f') 'W_Serie' num2str(Conf.Acquisition.Iteration) '.txt'];
            % writetimetable(TC(:,n),filenametxt,'WriteVariableNames',false,'Delimiter','tab');
            tmp = [seconds(TC.Time) table2array(TC(:,n))];
            save(filenameTCtxt,"tmp",'-ascii')

            filenameTC0begtxt = [savepathtxt 'data_TC' num2str(n-1) '_0beg_Rix' Conf.Acquisition.Amplitude '_PhaseRIXHP' ...
                num2str(Conf.Parameters.PhiHP-Conf.Parameters.PhiRix)...
                    '°_Orientation' Conf.Parameters.Orientation '_Qc' num2str(Q_c,'%.0f') 'W_Serie' num2str(Conf.Acquisition.Iteration) '.txt'];
            % writetimetable(TC_0beg(:,n),filenametxt,'WriteVariableNames',false,'Delimiter','tab');
            tmp_0beg = [seconds(TC_0beg.Time) table2array(TC_0beg(:,n))];
            save(filenameTC0begtxt,"tmp_0beg",'-ascii')
        end

        % for nn = 1:2
        % 
        % end
    case 'No'
        % return
end


