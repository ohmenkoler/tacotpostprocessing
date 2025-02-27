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

% T_end = 3500;                                              % Total duration of measurement in s.
% BigData = BigData(1:Conf.Acquisition.F_sampling*T_end,:);    % Resizing to have same length for all

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
Conf.Acquisition.Iteration = 1;
Conf.Parameters.Orientation = 'H2';
Conf.Acquisition.ManipType = 'Water';
Conf.Acquisition.Acq = 'Transient';
Conf.Acquisition.Amplitude = 'Hi';
Conf.Parameters.UCHX_Vrms = sqrt(0*22.4);
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
CHXDutyCycle = mean(CHXTrig);

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
mdot = Conf.Parameters.WaterAHX_lperminute / 60;   % l/min -> kg/s
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
        mkdir(SAVE_PATH,'TextData\TemporalData\')
        savepathtxt_temporal = [SAVE_PATH '\TextData\TemporalData\'];
        for n = 1:16
            filenameTCtxt_temporal = [savepathtxt_temporal 'data_TC' num2str(n-1) '_Rix' Conf.Acquisition.Amplitude '_PhaseRIXHP' ...
                num2str(Conf.Parameters.PhiHP-Conf.Parameters.PhiRix)...
                    '°_Orientation' Conf.Parameters.Orientation '_Qc' num2str(Q_c,'%.0f') 'W_Serie' num2str(Conf.Acquisition.Iteration) '.txt'];
            % writetimetable(TC(:,n),filenametxt,'WriteVariableNames',false,'Delimiter','tab');
            tmp = [seconds(TC.Time) table2array(TC(:,n))];
            save(filenameTCtxt_temporal,"tmp",'-ascii')

            filenameTC0begtxt_temporal = [savepathtxt_temporal 'data_TC' num2str(n-1) '_0beg_Rix' Conf.Acquisition.Amplitude '_PhaseRIXHP' ...
                num2str(Conf.Parameters.PhiHP-Conf.Parameters.PhiRix)...
                    '°_Orientation' Conf.Parameters.Orientation '_Qc' num2str(Q_c,'%.0f') 'W_Serie' num2str(Conf.Acquisition.Iteration) '.txt'];
            % writetimetable(TC_0beg(:,n),filenametxt,'WriteVariableNames',false,'Delimiter','tab');
            tmp_0beg = [seconds(TC_0beg.Time) table2array(TC_0beg(:,n))];
            save(filenameTC0begtxt_temporal,"tmp_0beg",'-ascii')
        end

    
        mkdir(SAVE_PATH,'TextData\AxialProfileData\')
        savepathtxt_profile = [SAVE_PATH '\TextData\AxialProfileData\'];

        rowNames = ["1_4_7_10_13" "2_5_8_11_14" "3_6_9_12_15"];

        x = [0 39/2 39];                % Regen axial dimension
        x_core = [x(1)-7 x x(end)+23];  % Core axial dimension
        r = [-148/2 0 148/2];           % Regen transverse dimensions
        r_AHX = [-110 0 110]/2;           % AHX transverse dimensions
        r_CHX = [-140 0 140]/2;           % CHX transverse dimensions
        
        [X,R] = meshgrid(x,r);
        R = R(end:-1:1,:);
        X_core = [x_core;x_core;x_core];
        R_core = [r_CHX' r' r' r' r_AHX'];
        R_core = R_core(end:-1:1,:);

        avg5lastmin = 5 * 60 * Conf.Acquisition.F_resampling;    % nb of points for averaging
        TC_avg = mean(TC{end-avg5lastmin:end,2:end},1);
        TC_0beg_avg = mean(TC_0beg{end-avg5lastmin:end,2:end},1);

        TC_avg_mat = reshape(TC_avg,3,5);
        TC_0beg_avg_mat = reshape(TC_0beg_avg,3,5);

        for n = 1:3
            filenameTCtxt_profile = [savepathtxt_profile 'data_TC' convertStringsToChars(rowNames(n)) '_Rix' Conf.Acquisition.Amplitude '_PhaseRIXHP' ...
                num2str(Conf.Parameters.PhiHP-Conf.Parameters.PhiRix)...
                    '°_Orientation' Conf.Parameters.Orientation '_Qc' num2str(Q_c,'%.0f') 'W_Serie' num2str(Conf.Acquisition.Iteration) '.txt'];
            % writetimetable(TC(:,n),filenametxt,'WriteVariableNames',false,'Delimiter','tab');
            tmp = [x_core ; TC_avg_mat(n,:)]';
            save(filenameTCtxt_profile,"tmp",'-ascii')

            filenameTC0begtxt_profile = [savepathtxt_profile 'data_TC' convertStringsToChars(rowNames(n)) '_0beg_Rix' Conf.Acquisition.Amplitude '_PhaseRIXHP' ...
                num2str(Conf.Parameters.PhiHP-Conf.Parameters.PhiRix)...
                    '°_Orientation' Conf.Parameters.Orientation '_Qc' num2str(Q_c,'%.0f') 'W_Serie' num2str(Conf.Acquisition.Iteration) '.txt'];
            % writetimetable(TC_0beg(:,n),filenametxt,'WriteVariableNames',false,'Delimiter','tab');
            tmp_0beg = [x_core ; TC_0beg_avg_mat(n,:)]';
            save(filenameTC0begtxt_profile,"tmp_0beg",'-ascii')
        end
    
    
    case 'No'
        % return
end


