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
Conf.Parameters.GasMix = '70%He-30%Ar';
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
Conf.Parameters.Orientation = 'V1';
CompLabels = 'V1V2';    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
Conf.Acquisition.ManipType = 'HeatOnly';
Conf.Acquisition.Acq = 'Transient';
Conf.Acquisition.Amplitude = 'Off';
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
        DPS{:,ii}.',DPS.Time,1,1024,Conf.Acquisition.F_sampling,Conf.Parameters.F_operation,phi,5);
end

for jj = [1 2]
    [f_sp_ACC,sp_ACC(jj,:),H_ACC(jj,:),phi_ACC(jj,:)]=Detection_synchrone(...
        Acc{:,jj}.',Acc.Time,1,1024,Conf.Acquisition.F_sampling,Conf.Parameters.F_operation,phi,5);
end

Conf.Parameters.DriveRatio = 100 * H_DPS(2,2) / (Conf.Parameters.GasStaticPressure * 1e5);

%% Global saving location
SAVE_PATH = uigetdir('Z:\Martin\Measurements\TACOT\V2_AddedSensors',"Where to store things?");
% addpath(SAVE_PATH)
% %% Cmap
% % ------------------------------------ Blue Orange Yellow + lighter version
% % CmapType = "3colors";
% % BaseColor = orderedcolors("gem");
% % BaseColorSelect = BaseColor(1:3,:);
% % BaseRIXcolor = [0 0 0];%orderedcolors("meadow");
% % BaseRIXcolorSelect = BaseRIXcolor(1,:);
% % N_color = 100;
% % GradientColor = zeros(3,3,N_color);
% % GradientRIXcolor = zeros(3,N_color);
% % for n = 1:3
% %     GradientRIXcolor(n,:) = linspace(BaseRIXcolorSelect(n),1,N_color);
% %     for m = 1:3
% %         GradientColor(m,n,:) = linspace(BaseColorSelect(m,n),1,N_color);
% %     end
% % end
% % ------------------------------------ END Blue Orange Yellow + lighter version
% % ------------------------------------ Blue CHX to Red AHX - 6 shades
% % CmapType = "shades";
% % Blue = [0 0 1]; Red = [1 0 0];
% % Blue2Red = zeros(5,3);
% % BaseRIXcolor = [0 0 0];%orderedcolors("meadow");
% % BaseRIXcolorSelect = BaseRIXcolor(1,:);
% % N_color = 256;
% % GradientColor = zeros(5,3,N_color);
% % GradientRIXcolor = zeros(3,N_color);
% % for ii = 1:3
% %     Blue2Red(:,ii) = linspace(Blue(ii),Red(ii),5);
% % end
% % for n = 1:3
% %     GradientRIXcolor(n,:) = linspace(BaseRIXcolorSelect(n),1,N_color);
% %     for m = 1:5
% %         GradientColor(m,n,:) = linspace(Blue2Red(m,n),1,N_color);
% %     end
% % end
% % ------------------------------------ END Blue CHX to Red AHX - 6 shades
% % ------------------------------------ Rainbow Blue CHX to Red AHX - 6 shades
% % CmapType = "rainbow";
% % CmapTot = colormap("hsv");
% % RainbowColorSelector = fix(linspace(1,171,5));      % 1 is red, 171 is blue
% % BaseColor = CmapTot(RainbowColorSelector,:);
% % BaseRIXcolor = [0 0 0];%orderedcolors("meadow");
% % BaseRIXcolorSelect = BaseRIXcolor(1,:);
% % N_color = 256;
% % GradientColor = zeros(5,3,N_color);
% % GradientRIXcolor = zeros(3,N_color);
% % for n = 1:3
% %     GradientRIXcolor(n,:) = linspace(BaseRIXcolorSelect(n),1,N_color);
% %     for m = 1:5
% %         GradientColor(m,n,:) = linspace(BaseColor(m,n),1,N_color);
% %     end
% % end
% % ------------------------------------ END Rainbow Blue CHX to Red AHX - 6 shades
% CmapType = "monochromeS";
% BaseColorHex = "#" + [ "030164" "050296" "0603c8" "0804fa" "3936fb" "6b68fc";...   % blue      CHX
%                     % "560164" "810296" "ac03c8" "d703fb" "df36fb" "e768fc";...   % purple   CHX
%                     "004a66" "006f99" "0094cc" "00b9ff" "33c7ff" "66d5ff";...   % cyan      Reg CHX
%                     "060" "090" "0c0" "0f0" "3f3" "6f6";...                     % green     Reg middle
%                     "656600" "990" "cbcc00" "feff00" "feff33" "feff66";...      % yellow    Reg AHX
%                     % "664200" "996300" "cc8400" "ffa500" "ffb733" "ffc966";...   % orange   Reg AHX
%                     "600" "900" "c00" "f00" "f33" "f66"];                       % red       AHX
% 
% %% Plots
% switch Conf.Parameters.Orientation
%     case 'V1'
%         newLS = '-';
%         LW = 1.5;
%         newcolor = GradientColor(:,:,1);
%         RIXcolor = GradientRIXcolor(:,1);
%     case 'V2'
%         newLS = '-';
%         LW = 1.5;
%         newcolor = GradientColor(:,:,50);
%         RIXcolor = GradientRIXcolor(:,50);
%     case 'H1'
%         newLS = '-';
%         LW = 1.5;
%         newcolor = GradientColor(:,:,25);
%         RIXcolor = GradientRIXcolor(:,25);
%     case 'H2'
%         newLS = '-';
%         LW = 1.5;
%         newcolor = GradientColor(:,:,75);
%         RIXcolor = GradientRIXcolor(:,75);
% end
% 
% switch CmapType
%     case "shades"
%         newcolor = GradientColor(:,:,fix(linspace(1,.75*256,6))); 
%         newcolor = [squeeze(newcolor(1,:,1:3))';squeeze(newcolor(2,:,1:3))';...
%             squeeze(newcolor(3,:,1:3))';squeeze(newcolor(4,:,1:3))';squeeze(newcolor(5,:,1:3))';...
%             squeeze(newcolor(1,:,4:6))';squeeze(newcolor(2,:,4:6))';...
%             squeeze(newcolor(3,:,4:6))';squeeze(newcolor(4,:,4:6))';squeeze(newcolor(5,:,4:6))'];
%     case "3color"
%         newcolor = newcolor;
%     case "monochromeS"
%         newcolor = BaseColorHex;
%     otherwise
% 
% end
% 
% 
% newmarker = ["_","_","_",...
%     "v","v","v",...
%     "x","x","x",...
%     "^","^","^",...
%     "+","+","+"];
% % newcolor = newcolor(1:3,:);
% MarkerSpacer = fix(height(TC)/4);
% 
% plotStuff = uifigure();
% selectionPlots = uiconfirm(plotStuff,"Plot stuff ?","Plot choice","Options",["1 plot per fig","6 plots per fig","No"],...
%     "DefaultOption",1,"CancelOption",3);
% switch selectionPlots
%     case '1 plot per fig'
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Plot absolute temperature
%         Figtype = ["AllTC";"TC123RIX";"TC456";"TC789";"TC101112";"TC131415";"TC5811";...
%             "AllTC_norm";"TC123RIX_norm";"TC456_norm";"TC789_norm";"TC101112_norm";"TC131415_norm";"TC5811_norm";"gradients"];
%         figure(1)
%         set(gcf,'Position',[2 42 798 774])
%         plot(TC.Time,TC{:,1},DisplayName='Src ac. 1',Color=RIXcolor,Marker='square',MarkerIndices=T_end*Conf.Acquisition.F_resampling,... %1:MarkerSpacer:length(TC{:,1}),...
%             LineWidth=LW,LineStyle=newLS)
%         set(gca,'ColorOrder',newcolor,'ColorOrderIndex',1)
%         for ii = 1:15
%             hold on
%             if ii == 1
%                 p = plot(TC.Time,TA_core{:,ii},DisplayName=['TC ' num2str(ii) ' (' Conf.Parameters.Orientation ')'],LineWidth=LW,LineStyle=newLS,Marker=newmarker(ii));
%                 p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%             else
%                 p = plot(TC.Time,TA_core{:,ii},DisplayName=['TC ' num2str(ii)],LineWidth=LW,LineStyle=newLS,Marker=newmarker(ii));
%                 p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%             end
%             lgd = legend();
%             lgd.NumColumns=6;
%             lgd.Location='northoutside';
%         end
%         xlabel("t [s]")
%         ylabel("T [^oC]")        
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
% 
%         figure(2)
%         set(gcf,'Position',[2 472 532 344])
%         plot(TC.Time,TC{:,1},DisplayName='Src ac. 1',Color=RIXcolor,Marker='square',...
%             MarkerIndices=T_end*Conf.Acquisition.F_resampling,LineWidth=LW,LineStyle=newLS)
%         set(gca,'ColorOrder',newcolor([1:3 16:18],:),'ColorOrderIndex',1)
%         for ii = 1:3
%         hold on
%         if ii==1
%             p = plot(TC.Time,TA_core{:,ii},DisplayName=['TC ' num2str(ii) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(ii));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core{:,ii},DisplayName=['TC ' num2str(ii)],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(ii));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         end
%         lgd = legend();
%         lgd.NumColumns=2;
%         lgd.Location='northoutside';
%         end
%         xlabel("t [s]")
%         ylabel("T [^oC]")
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
% 
%         figure(3)
%         set(gcf,'Position',[536 472 532 344])
%         TCcoldin = 4:6;
%         set(gca,'ColorOrder',newcolor([TCcoldin TCcoldin+15],:),'ColorOrderIndex',1)
%         for ii = 1:numel(TCcoldin)
%         hold on
%         if ii == 1
%             p = plot(TC.Time,TA_core{:,TCcoldin(ii)},DisplayName=['TC ' num2str(TCcoldin(ii)) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCcoldin(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core{:,TCcoldin(ii)},DisplayName=['TC ' num2str(TCcoldin(ii))],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCcoldin(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});    
%         end
%         lgd = legend();
%         lgd.NumColumns=2;
%         lgd.Location='northoutside';
%         end
%         xlabel("t [s]")
%         ylabel("T [^oC]")
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
% 
%         figure(4)
%         set(gcf,'Position',[1070 472 532 344])
%         TCmilieu = 7:9;
%         set(gca,'ColorOrder',newcolor([TCmilieu TCmilieu+15],:),'ColorOrderIndex',1)
%         for ii = 1:numel(TCmilieu)
%         hold on
%         if ii == 1
%             p = plot(TC.Time,TA_core{:,TCmilieu(ii)},DisplayName=['TC ' num2str(TCmilieu(ii)) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCmilieu(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core{:,TCmilieu(ii)},DisplayName=['TC ' num2str(TCmilieu(ii))],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCmilieu(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});    
%         end
%         lgd = legend();
%         lgd.NumColumns=2;
%         lgd.Location='northoutside';
%         end
%         xlabel("t [s]")
%         ylabel("T [^oC]")
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
% 
%         figure(5)
%         set(gcf,'Position',[2 42 532 344])
%         TCambin = 10:12;
%         set(gca,'ColorOrder',newcolor([TCambin TCambin+15],:),'ColorOrderIndex',1)
%         for ii = 1:numel(TCambin)
%         hold on
%         if ii == 1
%             p = plot(TC.Time,TA_core{:,TCambin(ii)},DisplayName=['TC ' num2str(TCambin(ii)) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCambin(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core{:,TCambin(ii)},DisplayName=['TC ' num2str(TCambin(ii))],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCambin(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});    
%         end
%         lgd = legend();
%         lgd.NumColumns=2;
%         lgd.Location='northoutside';
%         end
%         xlabel("t [s]")
%         ylabel("T [^oC]")
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
% 
%         figure(6)
%         set(gcf,'Position',[536 42 532 344])
%         TCambout = 13:15;
%         set(gca,'ColorOrder',newcolor([TCambout TCambout+15],:),'ColorOrderIndex',1)
%         for ii = 1:numel(TCambout)
%         hold on
%         if ii == 1
%             p = plot(TC.Time,TA_core{:,TCambout(ii)},DisplayName=['TC ' num2str(TCambout(ii)) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCambout(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core{:,TCambout(ii)},DisplayName=['TC ' num2str(TCambout(ii))],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCambout(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});    
%         end
%         lgd = legend();
%         lgd.NumColumns=2;
%         lgd.Location='northoutside';
%         end
%         xlabel("t [s]")
%         ylabel("T [^oC]")
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
% 
%         figure(7)
%         set(gcf,'Position',[1070 42 532 344])
%         TCaxe = 5:3:11;
%         set(gca,'ColorOrder',newcolor([TCaxe TCaxe+15],:),'ColorOrderIndex',1)
%         for ii = 1:numel(TCaxe)
%         hold on
%         if ii==1
%             p = plot(TC.Time,TA_core{:,TCaxe(ii)},DisplayName=['TC ' num2str(TCaxe(ii)) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCaxe(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core{:,TCaxe(ii)},DisplayName=['TC ' num2str(TCaxe(ii))],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCaxe(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         end
%         lgd = legend();
%         lgd.NumColumns=2;
%         lgd.Location='northoutside';
%         end
%         xlabel("t [s]")
%         ylabel("T [^oC]")
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
% 
% 
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Plot difference compared to beginning
%         figure(8)
%         set(gcf,'Position',[802 42 798 774])
%         plot(TC.Time,TC_0beg{:,1},DisplayName='Src ac. 1',Color=RIXcolor,Marker='square',...
%             MarkerIndices=T_end*Conf.Acquisition.F_resampling,LineWidth=LW,LineStyle=newLS)
%         set(gca,'ColorOrder',newcolor,'ColorOrderIndex',1)
%         for ii = 1:15
%         hold on
%         if ii == 1
%             p = plot(TC.Time,TA_core0beg{:,ii},DisplayName=['TC ' num2str(ii) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(ii));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core0beg{:,ii},DisplayName=['TC ' num2str(ii)],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(ii));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         end
%         lgd = legend();
%         lgd.NumColumns=6;
%         lgd.Location='northoutside';
%         end
%         xlabel("t [s]")
%         ylabel("T-T_i [^oC]")
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
% 
%         figure(9)
%         set(gcf,'Position',[2 472 532 344])
%         plot(TC.Time,TC_0beg{:,1},DisplayName='Src ac. 1',Color=RIXcolor,Marker='square',...
%             MarkerIndices=T_end*Conf.Acquisition.F_resampling,LineWidth=LW,LineStyle=newLS)
%         set(gca,'ColorOrder',newcolor([1:3 16:18],:),'ColorOrderIndex',1)
%         for ii = 1:3
%             hold on%on %(all prevent clearing LineStyleOrder)
%         if ii==1
%             p = plot(TC.Time,TA_core0beg{:,ii},DisplayName=['TC ' num2str(ii) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(ii));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core0beg{:,ii},DisplayName=['TC ' num2str(ii)],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(ii));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         end
%         lgd = legend();
%         lgd.NumColumns=2;
%         lgd.Location='northoutside';
%         end
%         xlabel("t [s]")
%         ylabel("T-T_i [^oC]")
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
% 
%         figure(10)
%         set(gcf,'Position',[536 472 532 344])
%         TCcoldin = 4:6;
%         set(gca,'ColorOrder',newcolor([TCcoldin TCcoldin+15],:),'ColorOrderIndex',1)
%         for ii = 1:numel(TCcoldin)
%        hold on
%         if ii == 1
%             p = plot(TC.Time,TA_core0beg{:,TCcoldin(ii)},DisplayName=['TC ' num2str(TCcoldin(ii)) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCcoldin(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core0beg{:,TCcoldin(ii)},DisplayName=['TC ' num2str(TCcoldin(ii))],LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCcoldin(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});    
%         end
%         lgd = legend();
%         lgd.NumColumns=2;
%         lgd.Location='northoutside';
%         end
%         xlabel("t [s]")
%         ylabel("T-T_i [^oC]")
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
% 
%         figure(11)
%         set(gcf,'Position',[1070 472 532 344])
%         TCmilieu = 7:9;
%         set(gca,'ColorOrder',newcolor([TCmilieu TCmilieu+15],:),'ColorOrderIndex',1)
%         for ii = 1:numel(TCmilieu)
%         hold on
%         if ii == 1
%             p = plot(TC.Time,TA_core0beg{:,TCmilieu(ii)},DisplayName=['TC ' num2str(TCmilieu(ii)) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCmilieu(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core0beg{:,TCmilieu(ii)},DisplayName=['TC ' num2str(TCmilieu(ii))],LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCmilieu(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});    
%         end
%         lgd = legend();
%         lgd.NumColumns=2;
%         lgd.Location='northoutside';
%         end
%         xlabel("t [s]")
%         ylabel("T-T_i [^oC]")
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
% 
%         figure(12)
%         set(gcf,'Position',[2 42 532 344])
%         TCambin = 10:12;
%         set(gca,'ColorOrder',newcolor([TCambin TCambin+15],:),'ColorOrderIndex',1)
%         for ii = 1:numel(TCambin)
%         hold on
%         if ii == 1
%             p = plot(TC.Time,TA_core0beg{:,TCambin(ii)},DisplayName=['TC ' num2str(TCambin(ii)) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCambin(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core0beg{:,TCambin(ii)},DisplayName=['TC ' num2str(TCambin(ii))],LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCambin(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});    
%         end
%         lgd = legend();
%         lgd.NumColumns=2;
%         lgd.Location='northoutside';
%         end
%         xlabel("t [s]")
%         ylabel("T-T_i [^oC]")
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
% 
%         figure(13)
%         set(gcf,'Position',[536 42 532 344])
%         TCambout = 13:15;
%         set(gca,'ColorOrder',newcolor([TCambout TCambout+15],:),'ColorOrderIndex',1)
%         for ii = 1:numel(TCambout)
%         hold on
%         if ii == 1
%             p = plot(TC.Time,TA_core0beg{:,TCambout(ii)},DisplayName=['TC ' num2str(TCambout(ii)) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCambout(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core0beg{:,TCambout(ii)},DisplayName=['TC ' num2str(TCambout(ii))],LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCambout(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});    
%         end
%         lgd = legend();
%         lgd.NumColumns=2;
%         lgd.Location='northoutside';
%         end
%         xlabel("t [s]")
%         ylabel("T-T_i [^oC]")
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
% 
%         figure(14)
%         set(gcf,'Position',[1070 42 532 344])
%         TCaxe = 5:3:11;
%         set(gca,'ColorOrder',newcolor([TCaxe TCaxe+15],:),'ColorOrderIndex',1)
%         for ii = 1:numel(TCaxe)
%        hold on
%         if ii==1
%             p = plot(TC.Time,TA_core0beg{:,TCaxe(ii)},DisplayName=['TC ' num2str(TCaxe(ii)) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCaxe(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core0beg{:,TCaxe(ii)},DisplayName=['TC ' num2str(TCaxe(ii))],LineWidth=LW,...
%                 LineStyle=newLS,Marker=newmarker(TCaxe(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         end
%         lgd = legend();
%         lgd.NumColumns=2;
%         lgd.Location='northoutside';
%         end
%         xlabel("t [s]")
%         ylabel("T-T_i [^oC]")
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
% 
%         n_fin = fix(5000/N_resample);
%         top = [];
%         mid = [];
%         bot = [];
%         z = 2:-2:-2;
%         figure(15)
%         set(gcf,'Position',[1 41 1600 783])
%         set(gca,'ColorOrder',newcolor)
%         for ii = 4:3:10
%             top = [top mean(TA_core{end-n_fin:end,ii})];
%             mid = [mid mean(TA_core{end-n_fin:end,ii+1})];
%             bot = [bot mean(TA_core{end-n_fin:end,ii+2})];
%         end
%         Ptop = polyfit(z,top,1);
%         topFIT = Ptop(1)*z+Ptop(2);
%         Pmid = polyfit(z,mid,1);
%         midFIT = Pmid(1)*z+Pmid(2);
%         Pbot = polyfit(z,bot,1);
%         botFIT = Pbot(1)*z+Pbot(2);
%         hold on
%         plot(z,top,LineWidth=LW,LineStyle=newLS,DisplayName=['TC [4-10] (' Conf.Parameters.Orientation ')'],Marker="*")
%         plot(z,mid,LineWidth=LW,LineStyle=newLS,DisplayName='TC [5-11]',Marker="*")
%         plot(z,bot,LineWidth=LW,LineStyle=newLS,DisplayName='TC [6-12]',Marker="*")
%         % plot(z,topFIT,LineStyle=newLS,LineWidth=1,DisplayName=['Fit [4-10] = ' num2str(Ptop(1)) '\times z + ' num2str(Ptop(2)) ' (' Conf.Parameters.Orientation ')'])
%         % plot(z,midFIT,LineStyle=newLS,LineWidth=0.5,DisplayName=['Fit [5-11] = ' num2str(Pmid(1)) '\times z + ' num2str(Pmid(2))])
%         % plot(z,botFIT,LineStyle=newLS,LineWidth=0.1,DisplayName=['Fit [6-12] = ' num2str(Pbot(1)) '\times z + ' num2str(Pbot(2))])
%         xlabel("\leftarrow AHX    x[cm]    CHX \rightarrow")
%         ylabel("T [^oC]")
%         lgd = legend();
%         lgd.Location = 'southwest';
%         lgd.NumColumns = 2;
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
%     case '6 plots per fig'
%         Figtype = ["AllTC";"5zones";"5zones_norm";"gradients"];
%         figure(1)
%         subplot(121)
%         set(gcf,'Position',[1 41 1600 783])
%         set(gca,'ColorOrder',newcolor)
%         for ii = 1:15
%         % nexttile
%         % set(axes,'ColorOrder',[0 0.4470 0.7410;...
%         %                        0.8500 0.3250 0.0980;...
%         %                        0.9290 0.6940 0.1250],...
%         %     'LineStyleOrder',{'-','--','-.'}',...
%         %     'MarkerOrder',{'o','^','+','square','x'})     %create axes with respective LineStyleOrder and color order
%         hold on%on %(all prevent clearing LineStyleOrder)
%         if ii == 1
%             p = plot(TC.Time,TA_core{:,ii},DisplayName=['TC ' num2str(ii) ' (' Conf.Parameters.Orientation ')'],LineWidth=LW,LineStyle=newLS,Marker=newmarker(ii));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core{:,ii},DisplayName=['TC ' num2str(ii)],LineWidth=LW,LineStyle=newLS,Marker=newmarker(ii));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         end
%         lgd = legend();
%         lgd.NumColumns=6;
%         lgd.Location='northoutside';
%         end
%         %xticks(num2str(t_minute),":",num2str(t_seconde))
%         xlabel("t [s]")
%         ylabel("T [^oC]")
%         plot(TC.Time,TC{:,1},DisplayName='Src ac. 1',Color=RIXcolor,Marker='square',MarkerIndices=T_end*Conf.Acquisition.F_resampling,...
%             LineWidth=LW,LineStyle=newLS)
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
%         % ylim([T_min T_max])
% 
%         figure(2)
%         set(gcf,'Position',[1 41 1600 783])
%         subplot(231)
%         set(gca,'ColorOrder',newcolor)
%         for ii = 1:3
%             % nexttile
%         % set(axes,'ColorOrder',[0 0.4470 0.7410;...
%         %                        0.8500 0.3250 0.0980;...
%         %                        0.9290 0.6940 0.1250],...
%         %     'LineStyleOrder',{'-','--','-.'}',...
%         %     'MarkerOrder',{'o','^','+','square','x'})     %create axes with respective LineStyleOrder and color order
%         hold on%on %(all prevent clearing LineStyleOrder)
%         if ii==1
%             p = plot(TC.Time,TA_core{:,ii},DisplayName=['TC ' num2str(ii) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(ii));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core{:,ii},DisplayName=['TC ' num2str(ii)],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(ii));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         end
%         lgd = legend();
%         lgd.NumColumns=2;
%         lgd.Location='northoutside';
%         end
%         %xticks(num2str(t_minute),":",num2str(t_seconde))
%         xlabel("t [s]")
%         ylabel("T [^oC]")
%         plot(TC.Time,TC{:,1},DisplayName='Src ac. 1',Color=RIXcolor,Marker='square',MarkerIndices=T_end*Conf.Acquisition.F_resampling,LineWidth=LW,LineStyle=newLS)
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
%         % ylim([T_min T_max])
% 
%         subplot(232)
%         set(gca,'ColorOrder',newcolor)
%         TCcoldin = 4:6;
%         for ii = 1:numel(TCcoldin)
%         % nexttile
%         % set(axes,'ColorOrder',[0 0.4470 0.7410;...
%         %                        0.8500 0.3250 0.0980;...
%         %                        0.9290 0.6940 0.1250],...
%         %     'LineStyleOrder',{'-','--','-.'}',...
%         %     'MarkerOrder',{'o','^','+','square','x'})     %create axes with respective LineStyleOrder and color order
%         hold on%on %(all prevent clearing LineStyleOrder)
%         if ii == 1
%             p = plot(TC.Time,TA_core{:,TCcoldin(ii)},DisplayName=['TC ' num2str(TCcoldin(ii)) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCcoldin(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core{:,TCcoldin(ii)},DisplayName=['TC ' num2str(TCcoldin(ii))],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCcoldin(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});    
%         end
%         lgd = legend();
%         lgd.NumColumns=2;
%         lgd.Location='northoutside';
%         end
%         %xticks(num2str(t_minute),":",num2str(t_seconde))
%         xlabel("t [s]")
%         ylabel("T [^oC]")
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
%         % ylim([T_min T_max])
% 
%         subplot(233)
%         set(gca,'ColorOrder',newcolor)
%         TCmilieu = 7:9;
%         for ii = 1:numel(TCmilieu)
%         % nexttile
%         % set(axes,'ColorOrder',[0 0.4470 0.7410;...
%         %                        0.8500 0.3250 0.0980;...
%         %                        0.9290 0.6940 0.1250],...
%         %     'LineStyleOrder',{'-','--','-.'}',...
%         %     'MarkerOrder',{'o','^','+','square','x'})     %create axes with respective LineStyleOrder and color order
%         hold on%on %(all prevent clearing LineStyleOrder)
%         if ii == 1
%             p = plot(TC.Time,TA_core{:,TCmilieu(ii)},DisplayName=['TC ' num2str(TCmilieu(ii)) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCmilieu(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core{:,TCmilieu(ii)},DisplayName=['TC ' num2str(TCmilieu(ii))],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCmilieu(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});    
%         end
%         lgd = legend();
%         lgd.NumColumns=2;
%         lgd.Location='northoutside';
%         end
%         %xticks(num2str(t_minute),":",num2str(t_seconde))
%         xlabel("t [s]")
%         ylabel("T [^oC]")
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
%         % ylim([T_min T_max])
% 
%         subplot(234)
%         set(gca,'ColorOrder',newcolor)
%         TCambin = 10:12;
%         for ii = 1:numel(TCambin)
%         % nexttile
%         % set(axes,'ColorOrder',[0 0.4470 0.7410;...
%         %                        0.8500 0.3250 0.0980;...
%         %                        0.9290 0.6940 0.1250],...
%         %     'LineStyleOrder',{'-','--','-.'}',...
%         %     'MarkerOrder',{'o','^','+','square','x'})     %create axes with respective LineStyleOrder and color order
%         hold on%on %(all prevent clearing LineStyleOrder)
%         if ii == 1
%             p = plot(TC.Time,TA_core{:,TCambin(ii)},DisplayName=['TC ' num2str(TCambin(ii)) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCambin(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core{:,TCambin(ii)},DisplayName=['TC ' num2str(TCambin(ii))],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCambin(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});    
%         end
%         lgd = legend();
%         lgd.NumColumns=2;
%         lgd.Location='northoutside';
%         end
%         %xticks(num2str(t_minute),":",num2str(t_seconde))
%         xlabel("t [s]")
%         ylabel("T [^oC]")
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
%         % ylim([T_min T_max])
% 
%         subplot(235)
%         set(gca,'ColorOrder',newcolor)
%         TCambout = 13:15;
%         for ii = 1:numel(TCambout)
%         % nexttile
%         % set(axes,'ColorOrder',[0 0.4470 0.7410;...
%         %                        0.8500 0.3250 0.0980;...
%         %                        0.9290 0.6940 0.1250],...
%         %     'LineStyleOrder',{'-','--','-.'}',...
%         %     'MarkerOrder',{'o','^','+','square','x'})     %create axes with respective LineStyleOrder and color order
%         hold on%on %(all prevent clearing LineStyleOrder)
%         if ii == 1
%             p = plot(TC.Time,TA_core{:,TCambout(ii)},DisplayName=['TC ' num2str(TCambout(ii)) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCambout(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core{:,TCambout(ii)},DisplayName=['TC ' num2str(TCambout(ii))],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCambout(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});    
%         end
%         lgd = legend();
%         lgd.NumColumns=2;
%         lgd.Location='northoutside';
%         end
%         %xticks(num2str(t_minute),":",num2str(t_seconde))
%         xlabel("t [s]")
%         ylabel("T [^oC]")
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
%         % ylim([T_min T_max])
% 
%         subplot(236)
%         TCaxe = 5:3:11;
%         for ii = 1:numel(TCaxe)
%         % nexttile
%         % set(axes,'ColorOrder',[0 0.4470 0.7410;...
%         %                        0.8500 0.3250 0.0980;...
%         %                        0.9290 0.6940 0.1250],...
%         %     'LineStyleOrder',{'-','--','-.'}',...
%         %     'MarkerOrder',{'o','^','+','square','x'})     %create axes with respective LineStyleOrder and color order
%         hold on%on %(all prevent clearing LineStyleOrder)
%         if ii==1
%             p = plot(TC.Time,TA_core{:,TCaxe(ii)},DisplayName=['TC ' num2str(TCaxe(ii)) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCaxe(ii)),Color=newcolor(2,:));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core{:,TCaxe(ii)},DisplayName=['TC ' num2str(TCaxe(ii))],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCaxe(ii)),Color=newcolor(2,:));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         end
%         lgd = legend();
%         lgd.NumColumns=2;
%         lgd.Location='northoutside';
%         end
%         %xticks(num2str(t_minute),":",num2str(t_seconde))
%         xlabel("t [s]")
%         ylabel("T [^oC]")
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
%         % ylim([T_min T_max])
% 
% 
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Plot difference compared to beginning
%         figure(1)
%         subplot(122)
%         set(gca,'ColorOrder',newcolor)
%         for ii = 1:15
%         % nexttile
%         % set(axes,'ColorOrder',[0 0.4470 0.7410;...
%         %                        0.8500 0.3250 0.0980;...
%         %                        0.9290 0.6940 0.1250],...
%         %     'LineStyleOrder',{'-','--','-.'}',...
%         %     'MarkerOrder',{'o','^','+','square','x'})     %create axes with respective LineStyleOrder and color order
%         hold on%on %(all prevent clearing LineStyleOrder)
%         if ii == 1
%             p = plot(TC.Time,TA_core0beg{:,ii},DisplayName=['TC ' num2str(ii) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(ii));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core0beg{:,ii},DisplayName=['TC ' num2str(ii)],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(ii));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         end
%         lgd = legend();
%         lgd.NumColumns=6;
%         lgd.Location='northoutside';
%         end
%         %xticks(num2str(t_minute),":",num2str(t_seconde))
%         xlabel("t [s]")
%         ylabel("T-T_i [^oC]")
%         plot(TC.Time,TC_0beg{:,1},DisplayName='Src ac. 1',Color=RIXcolor,Marker='square',...
%             MarkerIndices=T_end*Conf.Acquisition.F_resampling,LineWidth=LW,LineStyle=newLS)
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
%         % ylim([T_min2 T_max2])
% 
%         figure(3)
%         set(gcf,'Position',[1 41 1600 783])
%         subplot(231)
%         set(gca,'ColorOrder',newcolor)
%         for ii = 1:3
%             % nexttile
%         % set(axes,'ColorOrder',[0 0.4470 0.7410;...
%         %                        0.8500 0.3250 0.0980;...
%         %                        0.9290 0.6940 0.1250],...
%         %     'LineStyleOrder',{'-','--','-.'}',...
%         %     'MarkerOrder',{'o','^','+','square','x'})     %create axes with respective LineStyleOrder and color order
%         hold on%on %(all prevent clearing LineStyleOrder)
%         if ii==1
%             p = plot(TC.Time,TA_core0beg{:,ii},DisplayName=['TC ' num2str(ii) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(ii));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core0beg{:,ii},DisplayName=['TC ' num2str(ii)],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(ii));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         end
%         lgd = legend();
%         lgd.NumColumns=2;
%         lgd.Location='northoutside';
%         end
%         %xticks(num2str(t_minute),":",num2str(t_seconde))
%         xlabel("t [s]")
%         ylabel("T-T_i [^oC]")
%         plot(TC.Time,TC_0beg{:,1},DisplayName='Src ac. 1',Color=RIXcolor,Marker='square',...
%             MarkerIndices=T_end*Conf.Acquisition.F_resampling,LineWidth=LW,LineStyle=newLS)
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
%         % ylim([T_min2 T_max2])
% 
%         subplot(232)
%         set(gca,'ColorOrder',newcolor)
%         TCcoldin = 4:6;
%         for ii = 1:numel(TCcoldin)
%         % nexttile
%         % set(axes,'ColorOrder',[0 0.4470 0.7410;...
%         %                        0.8500 0.3250 0.0980;...
%         %                        0.9290 0.6940 0.1250],...
%         %     'LineStyleOrder',{'-','--','-.'}',...
%         %     'MarkerOrder',{'o','^','+','square','x'})     %create axes with respective LineStyleOrder and color order
%         hold on%on %(all prevent clearing LineStyleOrder)
%         if ii == 1
%             p = plot(TC.Time,TA_core0beg{:,TCcoldin(ii)},...
%                 DisplayName=['TC ' num2str(TCcoldin(ii)) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCcoldin(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core0beg{:,TCcoldin(ii)},...
%                 DisplayName=['TC ' num2str(TCcoldin(ii))],LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCcoldin(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});    
%         end
%         lgd = legend();
%         lgd.NumColumns=2;
%         lgd.Location='northoutside';
%         end
%         %xticks(num2str(t_minute),":",num2str(t_seconde))
%         xlabel("t [s]")
%         ylabel("T-T_i [^oC]")
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
%         % ylim([T_min2 T_max2])
% 
%         subplot(233)
%         set(gca,'ColorOrder',newcolor)
%         TCmilieu = 7:9;
%         for ii = 1:numel(TCmilieu)
%         % nexttile
%         % set(axes,'ColorOrder',[0 0.4470 0.7410;...
%         %                        0.8500 0.3250 0.0980;...
%         %                        0.9290 0.6940 0.1250],...
%         %     'LineStyleOrder',{'-','--','-.'}',...
%         %     'MarkerOrder',{'o','^','+','square','x'})     %create axes with respective LineStyleOrder and color order
%         hold on%on %(all prevent clearing LineStyleOrder)
%         if ii == 1
%             p = plot(TC.Time,TA_core0beg{:,TCmilieu(ii)},...
%                 DisplayName=['TC ' num2str(TCmilieu(ii)) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCmilieu(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core0beg{:,TCmilieu(ii)},...
%                 DisplayName=['TC ' num2str(TCmilieu(ii))],LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCmilieu(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});    
%         end
%         lgd = legend();
%         lgd.NumColumns=2;
%         lgd.Location='northoutside';
%         end
%         %xticks(num2str(t_minute),":",num2str(t_seconde))
%         xlabel("t [s]")
%         ylabel("T-T_i [^oC]")
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
%         % ylim([T_min2 T_max2])
% 
%         subplot(234)
%         set(gca,'ColorOrder',newcolor)
%         TCambin = 10:12;
%         for ii = 1:numel(TCambin)
%         % nexttile
%         % set(axes,'ColorOrder',[0 0.4470 0.7410;...
%         %                        0.8500 0.3250 0.0980;...
%         %                        0.9290 0.6940 0.1250],...
%         %     'LineStyleOrder',{'-','--','-.'}',...
%         %     'MarkerOrder',{'o','^','+','square','x'})     %create axes with respective LineStyleOrder and color order
%         hold on%on %(all prevent clearing LineStyleOrder)
%         if ii == 1
%             p = plot(TC.Time,TA_core0beg{:,TCambin(ii)},...
%                 DisplayName=['TC ' num2str(TCambin(ii)) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCambin(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core0beg{:,TCambin(ii)},...
%                 DisplayName=['TC ' num2str(TCambin(ii))],LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCambin(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});    
%         end
%         lgd = legend();
%         lgd.NumColumns=2;
%         lgd.Location='northoutside';
%         end
%         %xticks(num2str(t_minute),":",num2str(t_seconde))
%         xlabel("t [s]")
%         ylabel("T-T_i [^oC]")
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
%         % ylim([T_min2 T_max2])
% 
%         subplot(235)
%         set(gca,'ColorOrder',newcolor)
%         TCambout = 13:15;
%         for ii = 1:numel(TCambout)
%         % nexttile
%         % set(axes,'ColorOrder',[0 0.4470 0.7410;...
%         %                        0.8500 0.3250 0.0980;...
%         %                        0.9290 0.6940 0.1250],...
%         %     'LineStyleOrder',{'-','--','-.'}',...
%         %     'MarkerOrder',{'o','^','+','square','x'})     %create axes with respective LineStyleOrder and color order
%         hold on%on %(all prevent clearing LineStyleOrder)
%         if ii == 1
%             p = plot(TC.Time,TA_core0beg{:,TCambout(ii)},...
%                 DisplayName=['TC ' num2str(TCambout(ii)) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCambout(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core0beg{:,TCambout(ii)},...
%                 DisplayName=['TC ' num2str(TCambout(ii))],LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCambout(ii)));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});    
%         end
%         lgd = legend();
%         lgd.NumColumns=2;
%         lgd.Location='northoutside';
%         end
%         %xticks(num2str(t_minute),":",num2str(t_seconde))
%         xlabel("t [s]")
%         ylabel("T-T_i [^oC]")
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
%         % ylim([T_min2 T_max2])
% 
%         subplot(236)
%         TCaxe = 5:3:11;
%         for ii = 1:numel(TCaxe)
%         % nexttile
%         % set(axes,'ColorOrder',[0 0.4470 0.7410;...
%         %                        0.8500 0.3250 0.0980;...
%         %                        0.9290 0.6940 0.1250],...
%         %     'LineStyleOrder',{'-','--','-.'}',...
%         %     'MarkerOrder',{'o','^','+','square','x'})     %create axes with respective LineStyleOrder and color order
%         hold on%on %(all prevent clearing LineStyleOrder)
%         if ii==1
%             p = plot(TC.Time,TA_core0beg{:,TCaxe(ii)},...
%                 DisplayName=['TC ' num2str(TCaxe(ii)) ' (' Conf.Parameters.Orientation ')'],...
%                 LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCaxe(ii)),Color=newcolor(2,:));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         else
%             p = plot(TC.Time,TA_core0beg{:,TCaxe(ii)},...
%                 DisplayName=['TC ' num2str(TCaxe(ii))],LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCaxe(ii)),Color=newcolor(2,:));
%             p.MarkerIndices = T_end*Conf.Acquisition.F_resampling; %1:MarkerSpacer:length(TA_core{:,ii});
%         end
%         lgd = legend();
%         lgd.NumColumns=2;
%         lgd.Location='northoutside';
%         end
%         %xticks(num2str(t_minute),":",num2str(t_seconde))
%         xlabel("t [s]")
%         ylabel("T-T_i [^oC]")
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
%         % ylim([T_min2 T_max2])
% 
%         n_fin = fix(5000/N_resample);
%         top = [];
%         mid = [];
%         bot = [];
%         z = 2:-2:-2;
%         figure(4)
%         set(gcf,'Position',[1 41 1600 783])
%         set(gca,'ColorOrder',newcolor)
%         for ii = 4:3:10
%             top = [top mean(TA_core{end-n_fin:end,ii})];
%             mid = [mid mean(TA_core{end-n_fin:end,ii+1})];
%             bot = [bot mean(TA_core{end-n_fin:end,ii+2})];
%         end
%         Ptop = polyfit(z,top,1);
%         topFIT = Ptop(1)*z+Ptop(2);
%         Pmid = polyfit(z,mid,1);
%         midFIT = Pmid(1)*z+Pmid(2);
%         Pbot = polyfit(z,bot,1);
%         botFIT = Pbot(1)*z+Pbot(2);
%         hold on
%         plot(z,top,LineWidth=LW,LineStyle=newLS,DisplayName=['TC [4-10] (' Conf.Parameters.Orientation ')'],Marker="*")
%         plot(z,mid,LineWidth=LW,LineStyle=newLS,DisplayName='TC [5-11]',Marker="*")
%         plot(z,bot,LineWidth=LW,LineStyle=newLS,DisplayName='TC [6-12]',Marker="*")
%         % plot(z,topFIT,LineWidth=LW,LineStyle=newLS,LineWidth=1,DisplayName=['Fit [4-10] = ' num2str(Ptop(1)) '\times z + ' num2str(Ptop(2)) ' (' Conf.Parameters.Orientation ')'])
%         % plot(z,midFIT,LineWidth=LW,LineStyle=newLS,LineWidth=0.5,DisplayName=['Fit [5-11] = ' num2str(Pmid(1)) '\times z + ' num2str(Pmid(2))])
%         % plot(z,botFIT,LineWidth=LW,LineStyle=newLS,LineWidth=0.1,DisplayName=['Fit [6-12] = ' num2str(Pbot(1)) '\times z + ' num2str(Pbot(2))])
%         xlabel("\leftarrow AHX    x[cm]    CHX \rightarrow")
%         ylabel("T [^oC]")
%         lgd = legend();
%         lgd.Location = 'southwest';
%         lgd.NumColumns = 2;
%         set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
% 
%         % figure(5)
%         % set(gcf,'Position',[1 41 1600 783])
%         % subplot(211)
%         % set(gca,'ColorOrder',newcolor)
%         % for ii = 1:numel(TCmilieu)
%         % % nexttile
%         % % set(axes,'ColorOrder',[0 0.4470 0.7410;...
%         % %                        0.8500 0.3250 0.0980;...
%         % %                        0.9290 0.6940 0.1250],...
%         % %     'LineStyleOrder',{'-','--','-.'}',...
%         % %     'MarkerOrder',{'o','^','+','square','x'})     %create axes with respective LineStyleOrder and color order
%         % hold on%on %(all prevent clearing LineStyleOrder)
%         % if ii == 1
%         %     p = plot(TC.Time,TA_core0beg{:,TCmilieu(ii)},...
%         %         DisplayName=['TC ' num2str(TCmilieu(ii)) ' (' Conf.Parameters.Orientation ')'],...
%         %         LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCmilieu(ii)));
%         %     p.MarkerIndices = 1:MarkerSpacer:length(TA_core{:,ii});
%         % else
%         %     p = plot(TC.Time,TA_core0beg{:,TCmilieu(ii)},...
%         %         DisplayName=['TC ' num2str(TCmilieu(ii))],LineWidth=LW,LineStyle=newLS,Marker=newmarker(TCmilieu(ii)));
%         %     p.MarkerIndices = 1:MarkerSpacer:length(TA_core{:,ii});    
%         % end
%         % lgd = legend();
%         % lgd.NumColumns=2;
%         % lgd.Location='northoutside';
%         % end
%         % %xticks(num2str(t_minute),":",num2str(t_seconde))
%         % ylabel("T-T_i [^oC]")
%         % set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
%         % % ylim([T_min2 T_max2])
%         % subplot(212)
%         % hold on
%         % u = plot(TC.Time,Q_a,Color="k",LineWidth=LW,LineStyle=newLS,DisplayName=Conf.Parameters.Orientation);
%         % u.MarkerIndices = 1:MarkerSpacer:length(TA_core{:,ii});
%         % xlabel("t [s]")
%         % ylabel("Q_a [W]")
%         % set(gca,'XMinorGrid','on'); set(gca,'YMinorGrid','on'); set(gca,'ZMinorGrid','on');
%     case 'No'
%         % return
% end
% 
% save_fig = uifigure();
% selectionfig = uiconfirm(save_fig,'Save .fig ?', 'Save ?',"Options",["Yes","No"]);
% switch selectionfig
%     case 'Yes'
%         mkdir(SAVE_PATH,'Figures\')
%         savepathfig = [SAVE_PATH '\Figures\'];
%         % addpath(savepathfig)
% 
%         for nn = 1:length(Figtype)
%             figname = ['Rix' Conf.Acquisition.Amplitude '_PhaseRIXHP' num2str(Conf.Parameters.PhiHP-Conf.Parameters.PhiRix)...
%     '°_Orientations' CompLabels '_Qc' num2str(Q_c,'%.0f') 'W_Serie' num2str(Conf.Acquisition.Iteration) '_' convertStringsToChars(Figtype(nn))];
%             figure(nn)
%             saveas(gcf,[savepathfig figname],'fig')
%         end
%     case 'No'
%         % return
% end


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


