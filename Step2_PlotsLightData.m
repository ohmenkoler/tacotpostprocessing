clear
close all
clc
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

%% Zone selection and corresponding color
CHXout = 1:4;
RegCHX = 5:7;
RegMid = 8:10;
RegAHX = 11:13;
AHXout = 14:16;
RegAxis = [6 9 12];
CoreAxis = [3 6 9 12 15];


% Blue Cyan Green Yellow Red (nuances)
% Mark = ["None" "None" "None" "None" "None"];
% CHXoutcolor = [0,0,0 ; 3,1,100 ; 5,2,150 ; 6,3,200 ; 127,127,127 ; 8,4,250 ; 57,54,251 ; 107,104,252] / 255;
% RegCHXcolor = [0, 74, 102 ; 0, 111, 153 ; 0, 148, 204 ; 0, 185, 255 ; 51, 199, 255 ; 102, 213, 255] / 255;
% RegMidcolor = [0, 102, 0 ; 0, 153, 0 ; 0, 204, 0 ; 0, 255, 0 ; 51, 255, 51 ; 102, 255, 102] / 255;
% RegAHXcolor = [101, 102, 0 ; 153, 153, 0 ; 203, 204, 0 ; 254, 255, 0 ; 254, 255, 51 ; 254, 255, 102] / 255;
% AHXoutcolor = [102, 0, 0 ; 153, 0, 0 ; 204, 0, 0 ; 255, 0, 0 ; 255, 51, 51 ; 255, 102, 102] / 255;
% RegAxiscolor = [RegCHXcolor(2,:) ; RegMidcolor(2,:) ; RegAHXcolor(2,:) ; RegCHXcolor(5,:) ; RegMidcolor(5,:) ; RegAHXcolor(5,:)];
% CoreAxiscolor = [CHXoutcolor(2,:) ; RegAxiscolor(1:3,:) ; AHXoutcolor(2,:) ; CHXoutcolor(5,:) ; RegAxiscolor(4:6,:) ; AHXoutcolor(5,:)];


% 'Gem'
Mark = ["_" "v" "x" "^" "+"];
x = orderedcolors('gem');
x1 = x(1:3,:);
x2 = zeros(3,3,100);
for ii = 1:3
    for jj = 1:3
        x2(ii,jj,:) = linspace(x1(ii,jj),1,100);
    end
end
x2 = x2(:,:,50);
CHXoutcolor = [0 0 0 ; x1 ; 0 0 0 ; x1] ;
RegCHXcolor = [x1 ; x1];
RegMidcolor = [x1 ; x1];
RegAHXcolor = [x1 ; x1];
AHXoutcolor = [x1 ; x1];
RegAxiscolor = [RegCHXcolor(2,:) ; RegMidcolor(2,:) ; RegAHXcolor(2,:) ; RegCHXcolor(5,:) ; RegMidcolor(5,:) ; RegAHXcolor(5,:)];
CoreAxiscolor = [CHXoutcolor(2,:) ; RegAxiscolor(1:3,:) ; AHXoutcolor(2,:) ; CHXoutcolor(5,:) ; RegAxiscolor(4:6,:) ; AHXoutcolor(5,:)];

LineStyle = ["-";"--"];
%% Plot transient temperature
%%%%%%%%%%%%%%%%%%%% With initial temperature
iCHX = 0;           % For colororder
iRegCHX = 0;
iRegMid = 0;
iRegAHX = 0;
iAHX = 0;
iAxis = 0;

Tmin = 300;
Tmin_0beg = 300;
Tmax = -300;
Tmax_0beg = -300;
for nfile = 1:length(filename)
    avg5lastmin = 5 * 60 * BigData(nfile).Conf.Acquisition.F_resampling;    % nb of points for averaging
    Tmin_tmp = min(min(BigData(nfile).TC{:,1:13}));
    Tmin_0beg_tmp = min(min(BigData(nfile).TC_0beg{:,1:13}));
    Tmax_tmp = max(max(BigData(nfile).TC{:,1:13}));
    Tmax_0beg_tmp = max(max(BigData(nfile).TC_0beg{:,1:13}));
    if Tmin_tmp < Tmin
        Tmin = Tmin_tmp;
    end
    if Tmax_tmp > Tmax
        Tmax = Tmax_tmp;
    end
    if Tmin_0beg_tmp < Tmin_0beg
        Tmin_0beg = Tmin_0beg_tmp;
    end
    if Tmax_0beg_tmp > Tmax_0beg
        Tmax_0beg = Tmax_0beg_tmp;
    end
end

Tlim = [Tmin Tmax];
Tlim_0beg = [Tmin_0beg Tmax_0beg];



f1 = figure('units','normalized','outerposition',[0 0 1 1]);
for nfile = 1:length(filename)
toto = 1;
    f11 = subplot(231);hold on;
    xlabel("t [s]");ylabel("T [^oC]")
    for nplot = CHXout
        iCHX = iCHX + 1;
        p = plot(BigData(nfile).TC.Time,BigData(nfile).TC{:,nplot},color=CHXoutcolor(iCHX,:),...
            DisplayName=['TC ' num2str(CHXout(nplot)-1) ' (' BigData(nfile).Conf.Parameters.Orientation ')'],...
            Marker=Mark(1),LineWidth=2);
        p.MarkerIndices = height(BigData(nfile).TC.Time);
        p.LineStyle = LineStyle(nfile);
    end
    ylim(Tlim)
    legend(NumColumns=2)
    set(gca,'XMinorGrid','on');set(gca,'YMinorGrid','on');set(gca,'ZMinorGrid','on');
    f12 = subplot(232);hold on;
    xlabel("t [s]");ylabel("T [^oC]")
    for nplot = RegCHX
        iRegCHX = iRegCHX + 1;
        p = plot(BigData(nfile).TC.Time,BigData(nfile).TC{:,nplot},color=RegCHXcolor(iRegCHX,:),...
            DisplayName=['TC ' num2str(RegCHX(nplot-4)-1) ' (' BigData(nfile).Conf.Parameters.Orientation ')'],...
            Marker=Mark(2),LineWidth=2);
        p.MarkerIndices = height(BigData(nfile).TC.Time);
        p.LineStyle = LineStyle(nfile);
    end
    ylim(Tlim)
    legend(NumColumns=2)
    set(gca,'XMinorGrid','on');set(gca,'YMinorGrid','on');set(gca,'ZMinorGrid','on');
    f13 = subplot(233);hold on;
    xlabel("t [s]");ylabel("T [^oC]")
    for nplot = RegMid
        iRegMid = iRegMid +1;
        p = plot(BigData(nfile).TC.Time,BigData(nfile).TC{:,nplot},color=RegMidcolor(iRegMid,:),...
            DisplayName=['TC ' num2str(RegMid(nplot-7)-1) ' (' BigData(nfile).Conf.Parameters.Orientation ')'],...
            Marker=Mark(3),LineWidth=2);
        p.MarkerIndices = height(BigData(nfile).TC.Time);
        p.LineStyle = LineStyle(nfile);
    end
    ylim(Tlim)
    legend(NumColumns=2)
    set(gca,'XMinorGrid','on');set(gca,'YMinorGrid','on');set(gca,'ZMinorGrid','on');
    f14 = subplot(234);hold on;
    xlabel("t [s]");ylabel("T [^oC]")
    for nplot = RegAHX
        iRegAHX = iRegAHX + 1;
        p = plot(BigData(nfile).TC.Time,BigData(nfile).TC{:,nplot},color=RegAHXcolor(iRegAHX,:),...
            DisplayName=['TC ' num2str(RegAHX(nplot-10)-1) ' (' BigData(nfile).Conf.Parameters.Orientation ')'],...
            Marker=Mark(4),LineWidth=2);
        p.MarkerIndices = height(BigData(nfile).TC.Time);
        p.LineStyle = LineStyle(nfile);
    end
    ylim(Tlim)
    legend(NumColumns=2)
    set(gca,'XMinorGrid','on');set(gca,'YMinorGrid','on');set(gca,'ZMinorGrid','on');
    f15 = subplot(235);hold on;
    xlabel("t [s]");ylabel("T [^oC]")
    for nplot = AHXout
        iAHX = iAHX + 1;
        p = plot(BigData(nfile).TC.Time,BigData(nfile).TC{:,nplot},color=AHXoutcolor(iAHX,:),...
            DisplayName=['TC ' num2str(AHXout(nplot-13)-1) ' (' BigData(nfile).Conf.Parameters.Orientation ')'],...
            Marker=Mark(5),LineWidth=2);
        p.MarkerIndices = height(BigData(nfile).TC.Time);
        p.LineStyle = LineStyle(nfile);
    end
    ylim(Tlim)
    legend(NumColumns=2)
    set(gca,'XMinorGrid','on');set(gca,'YMinorGrid','on');set(gca,'ZMinorGrid','on');
    f16 = subplot(236);hold on;
    xlabel("t [s]");ylabel("T [^oC]")
    for nplot = RegAxis
        iAxis = iAxis + 1;
        p = plot(BigData(nfile).TC.Time,BigData(nfile).TC{:,nplot},color=RegAxiscolor(iAxis,:),...
            DisplayName=['TC ' num2str(RegAxis(toto)-1) ' (' BigData(nfile).Conf.Parameters.Orientation ')'],...
            Marker=Mark(toto+1),LineWidth=2);
        p.MarkerIndices = height(BigData(nfile).TC.Time);
        p.LineStyle = LineStyle(nfile);
        toto = toto+1;
    end
    ylim(Tlim)
    legend(NumColumns=2)
    set(gca,'XMinorGrid','on');set(gca,'YMinorGrid','on');set(gca,'ZMinorGrid','on');
end

%%%%%%%%%%%%%%%%%%%% Without initial temperature
iCHX = 0;
iRegCHX = 0;
iRegMid = 0;
iRegAHX = 0;
iAHX = 0;
iAxis = 0;

f2 = figure('units','normalized','outerposition',[0 0 1 1]);
for nfile = 1:length(filename)
toto = 1;
    f21 = subplot(231);hold on;
    xlabel("t [s]");ylabel("T-T|_{t=0} [^oC]")
    for nplot = CHXout
        iCHX = iCHX + 1;
        p = plot(BigData(nfile).TC_0beg.Time,BigData(nfile).TC_0beg{:,nplot},color=CHXoutcolor(iCHX,:),...
            DisplayName=['TC ' num2str(CHXout(nplot)-1) ' (' BigData(nfile).Conf.Parameters.Orientation ')'],...
            Marker=Mark(1),LineWidth=2);
        p.MarkerIndices = height(BigData(nfile).TC_0beg.Time);
        p.LineStyle = LineStyle(nfile);
    end
    ylim(Tlim_0beg)
    legend(NumColumns=2)
    set(gca,'XMinorGrid','on');set(gca,'YMinorGrid','on');set(gca,'ZMinorGrid','on');
    f22 = subplot(232);hold on;
    xlabel("t [s]");ylabel("T-T|_{t=0} [^oC]")
    for nplot = RegCHX
        iRegCHX = iRegCHX + 1;
        p = plot(BigData(nfile).TC_0beg.Time,BigData(nfile).TC_0beg{:,nplot},color=RegCHXcolor(iRegCHX,:),...
            DisplayName=['TC ' num2str(RegCHX(nplot-4)-1) ' (' BigData(nfile).Conf.Parameters.Orientation ')'],...
            Marker=Mark(2),LineWidth=2);
        p.MarkerIndices = height(BigData(nfile).TC_0beg.Time);
        p.LineStyle = LineStyle(nfile);
    end
    ylim(Tlim_0beg)
    legend(NumColumns=2)
    set(gca,'XMinorGrid','on');set(gca,'YMinorGrid','on');set(gca,'ZMinorGrid','on');
    f23 = subplot(233);hold on;
    xlabel("t [s]");ylabel("T-T|_{t=0} [^oC]")
    for nplot = RegMid
        iRegMid = iRegMid +1;
        p = plot(BigData(nfile).TC_0beg.Time,BigData(nfile).TC_0beg{:,nplot},color=RegMidcolor(iRegMid,:),...
            DisplayName=['TC ' num2str(RegMid(nplot-7)-1) ' (' BigData(nfile).Conf.Parameters.Orientation ')'],...
            Marker=Mark(3),LineWidth=2);
        p.MarkerIndices = height(BigData(nfile).TC_0beg.Time);
        p.LineStyle = LineStyle(nfile);
    end
    ylim(Tlim_0beg)
    legend(NumColumns=2)
    set(gca,'XMinorGrid','on');set(gca,'YMinorGrid','on');set(gca,'ZMinorGrid','on');
    f24 = subplot(234);hold on;
    xlabel("t [s]");ylabel("T-T|_{t=0} [^oC]")
    for nplot = RegAHX
        iRegAHX = iRegAHX + 1;
        p = plot(BigData(nfile).TC_0beg.Time,BigData(nfile).TC_0beg{:,nplot},color=RegAHXcolor(iRegAHX,:),...
            DisplayName=['TC ' num2str(RegAHX(nplot-10)-1) ' (' BigData(nfile).Conf.Parameters.Orientation ')'],...
            Marker=Mark(4),LineWidth=2);
        p.MarkerIndices = height(BigData(nfile).TC_0beg.Time);
        p.LineStyle = LineStyle(nfile);
    end
    ylim(Tlim_0beg)
    legend(NumColumns=2)
    set(gca,'XMinorGrid','on');set(gca,'YMinorGrid','on');set(gca,'ZMinorGrid','on');
    f25 = subplot(235);hold on;
    xlabel("t [s]");ylabel("T-T|_{t=0} [^oC]")
    for nplot = AHXout
        iAHX = iAHX + 1;
        p = plot(BigData(nfile).TC_0beg.Time,BigData(nfile).TC_0beg{:,nplot},color=AHXoutcolor(iAHX,:),...
            DisplayName=['TC ' num2str(AHXout(nplot-13)-1) ' (' BigData(nfile).Conf.Parameters.Orientation ')'],...
            Marker=Mark(5),LineWidth=2);
        p.MarkerIndices = height(BigData(nfile).TC_0beg.Time);
        p.LineStyle = LineStyle(nfile);
    end
    ylim(Tlim_0beg)
    legend(NumColumns=2)
    set(gca,'XMinorGrid','on');set(gca,'YMinorGrid','on');set(gca,'ZMinorGrid','on');
    f26 = subplot(236);hold on;
    xlabel("t [s]");ylabel("T-T|_{t=0} [^oC]")
    for nplot = RegAxis
        iAxis = iAxis + 1;
        p = plot(BigData(nfile).TC_0beg.Time,BigData(nfile).TC_0beg{:,nplot},color=RegAxiscolor(iAxis,:),...
            DisplayName=['TC ' num2str(RegAxis(toto)-1) ' (' BigData(nfile).Conf.Parameters.Orientation ')'],...
            Marker=Mark(toto+1),LineWidth=2);
        p.MarkerIndices = height(BigData(nfile).TC_0beg.Time);
        p.LineStyle = LineStyle(nfile);
        toto = toto+1;
    end
    ylim(Tlim_0beg)
    legend(NumColumns=2)
    set(gca,'XMinorGrid','on');set(gca,'YMinorGrid','on');set(gca,'ZMinorGrid','on');
end


%% Plot thermal maps
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

i_tmp=0;
figure('units','normalized','outerposition',[0 0 1 1]);
for nfile = 1:length(filename)
    avg5lastmin = 5 * 60 * BigData(nfile).Conf.Acquisition.F_resampling;    % nb of points for averaging

    TC_avg = mean(BigData(nfile).TC{end-avg5lastmin:end,2:end},1);
    TC_0beg_avg = mean(BigData(nfile).TC_0beg{end-avg5lastmin:end,2:end},1);

    TC_avg_mat = reshape(TC_avg(:,4:12),3,3);
    TC_0beg_avg_mat = reshape(TC_0beg_avg(:,4:12),3,3);

    subplot(2,2,i_tmp+nfile)
    pcolor(X,R,TC_avg_mat)
    colorbar()
    shading('interp')
    title({[BigData(nfile).Conf.Parameters.Orientation ', with initial temperature'],['Qa = ' num2str(BigData(nfile).Q_a) ' W, DR: ' num2str(BigData(nfile).H_DPS(2,2)/(40e3)) ' %']})
    xlabel("x [mm]");ylabel("r [mm]")

    subplot(2,2,i_tmp+nfile+1)
    pcolor(X,R,TC_0beg_avg_mat)
    title({[BigData(nfile).Conf.Parameters.Orientation ', without initial temperature'],['Qa = ' num2str(BigData(nfile).Q_a) ' W, DR: ' num2str(BigData(nfile).H_DPS(2,2)/(40e3)) ' %']})
    colorbar()
    shading('interp')
    xlabel("x [mm]");ylabel("r [mm]")
    i_tmp=nfile;
end


%% Plot gradients
AxisLabel3 = ["4, 7, 10" "5, 8, 11" "6, 9, 12"];
AxisLabel5 = ["1, 4, 7, 10, 13" "2, 5, 8, 11, 13" "3, 6, 9, 12, 15"];
toutes_orientations=[];

figure('units','normalized','outerposition',[0 0 1 1]);
for nfile = 1:length(filename)
    toutes_orientations=[toutes_orientations BigData(nfile).Conf.Parameters.Orientation];

    avg5lastmin = 5 * 60 * BigData(nfile).Conf.Acquisition.F_resampling;    % nb of points for averaging
    
    TC_avg = mean(BigData(nfile).TC{end-avg5lastmin:end,2:end},1);
    TC_std = std(BigData(nfile).TC{end-avg5lastmin:end,2:end},0,1);
    TC_0beg_avg = mean(BigData(nfile).TC_0beg{end-avg5lastmin:end,2:end},1);
    TC_0beg_std = std(BigData(nfile).TC_0beg{end-avg5lastmin:end,2:end},0,1);

    TC_avg_mat = reshape(TC_avg(:,4:12),3,3);
    TC_std_mat = reshape(TC_std(:,4:12),3,3);
    TC_0beg_avg_mat = reshape(TC_0beg_avg(:,4:12),3,3);
    TC_0beg_std_mat = reshape(TC_0beg_std(:,4:12),3,3);

    subplot(211);hold on;
    for nplot = 1:3
        ntmp = nplot+(nfile-1)*3;
        p = plot(x,TC_avg_mat(nplot,:)',color=RegCHXcolor(ntmp,:),...
            DisplayName=['TC ' convertStringsToChars(AxisLabel3(nplot)) ...
            ' (' BigData(nfile).Conf.Parameters.Orientation ')']);
        e = errorbar(x,TC_avg_mat(nplot,:)',TC_std_mat(nplot,:)',...
            color=RegCHXcolor(ntmp,:));
        p.LineStyle = LineStyle(nfile);
        p.LineWidth = 2;
    end
    legend(NumColumns=2,Location="southeast")
    set(gca,'XMinorGrid','on');set(gca,'YMinorGrid','on');set(gca,'ZMinorGrid','on');
    xlabel("x [mm]");ylabel("T [^oC]")
    title({[toutes_orientations ', with initial temperature'],...
        ['DR: ' num2str(BigData(nfile).H_DPS(2,2)/(40e3)) ' %']})
    ylim(Tlim)
    xlim([x(1) x(end)])

    subplot(212);hold on;
    for nplot = 1:3
        ntmp = nplot+(nfile-1)*3;
        p = plot(x,TC_0beg_avg_mat(nplot,:)',color=RegCHXcolor(ntmp,:),...
            DisplayName=['TC ' convertStringsToChars(AxisLabel3(nplot)) ...
            ' (' BigData(nfile).Conf.Parameters.Orientation ')']);
        e = errorbar(x,TC_0beg_avg_mat(nplot,:)',TC_0beg_std_mat(nplot,:)',...
            color=RegCHXcolor(ntmp,:));
        p.LineStyle = LineStyle(nfile);
        p.LineWidth = 2;
    end
    legend(NumColumns=2,Location="southeast")
    set(gca,'XMinorGrid','on');set(gca,'YMinorGrid','on');set(gca,'ZMinorGrid','on');
    xlabel("x [mm]");ylabel("T-T|_{t=0} [^oC]")
    title({[toutes_orientations ', without initial temperature'],...
        ['DR: ' num2str(BigData(nfile).H_DPS(2,2)/(40e3)) ' %']})
    ylim(Tlim_0beg)
    xlim([x(1) x(end)])
end




figure('units','normalized','outerposition',[0 0 1 1]);
for nfile = 1:length(filename)

    avg5lastmin = 5 * 60 * BigData(nfile).Conf.Acquisition.F_resampling;    % nb of points for averaging
    
    TC_avg = mean(BigData(nfile).TC{end-avg5lastmin:end,2:end},1);
    TC_0beg_avg = mean(BigData(nfile).TC_0beg{end-avg5lastmin:end,2:end},1);

    TC_avg_mat = reshape(TC_avg,3,5);
    TC_0beg_avg_mat = reshape(TC_0beg_avg,3,5);

    subplot(211);hold on;
    for nplot = 1:3
        ntmp = nplot+(nfile-1)*3;
        p = plot(x_core,TC_avg_mat(nplot,:)',color=RegCHXcolor(ntmp,:),...
            DisplayName=['TC ' convertStringsToChars(AxisLabel5(nplot)) ...
            ' (' BigData(nfile).Conf.Parameters.Orientation ')']);
        p.LineStyle = LineStyle(nfile);
        p.LineWidth = 2;
    end
    legend(NumColumns=2,Location="southeast")
    set(gca,'XMinorGrid','on');set(gca,'YMinorGrid','on');set(gca,'ZMinorGrid','on');
    xlabel("x [mm]");ylabel("T [^oC]")
    title({[toutes_orientations ', with initial temperature'],...
        ['DR: ' num2str(BigData(nfile).H_DPS(2,2)/(40e3)) ' %']})
    ylim(Tlim)
    xlim([x_core(1) x_core(end)])

    subplot(212);hold on;
    for nplot = 1:3
        ntmp = nplot+(nfile-1)*3;
        p = plot(x_core,TC_0beg_avg_mat(nplot,:)',color=RegCHXcolor(ntmp,:),...
            DisplayName=['TC ' convertStringsToChars(AxisLabel5(nplot)) ...
            ' (' BigData(nfile).Conf.Parameters.Orientation ')']);
        p.LineStyle = LineStyle(nfile);
        p.LineWidth = 2;
    end
    legend(NumColumns=2,Location="southeast")
    set(gca,'XMinorGrid','on');set(gca,'YMinorGrid','on');set(gca,'ZMinorGrid','on');
    xlabel("x [mm]");ylabel("T-T|_{t=0} [^oC]")
    title({[toutes_orientations ', without initial temperature'],...
        ['DR: ' num2str(BigData(nfile).H_DPS(2,2)/(40e3)) ' %']})
    ylim(Tlim_0beg)
    xlim([x_core(1) x_core(end)])
end

%% Save figures
Figs = findobj('Type','Figure');
Figs = Figs(end:-1:1);
FigsNames = ["Transient","Transient_0","TMaps","AxProfile_3","AxProfile_5"];

fig = uifigure('HandleVisibility','on');
selection = uiconfirm(fig,'Store the figures?',...
    'Figure storage',"Options",...
    ["Yes","No"], ...
    "DefaultOption",1,"CancelOption",2);
switch selection
    case 'Yes'
        SAVE_PATH = uigetdir('Z:\Martin\Measurements\TACOT\V2_AddedSensors',"Where?");
        mkdir(SAVE_PATH,'Figures\')
        savepathfig = [SAVE_PATH '\Figures\'];

        for ifig = 1:length(Figs)
            savefig(Figs(ifig),[savepathfig convertStringsToChars(FigsNames(ifig)) ...
                '_' toutes_orientations '_' BigData(1).Conf.Acquisition.Amplitude])
        end
    case 'No'
end




















