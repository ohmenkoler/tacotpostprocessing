clear
close all
clc
%% load all
[filename,filepath] = uigetfile('*.mat','Select a .mat files to process',...
    'C:\Users\mfontbon\Desktop\sDrive\Manips\ConvectionNaturelle\PerformancesStudy',...
    'MultiSelect','on');
if ~iscell(filename)
    filename = cellstr(filename);
end

for nfile = 1:length(filename)
    tmp = strcat(filepath,filename(nfile));
    BigData(nfile) = load(tmp{:});
end

%% Extract stuff
t = seconds(BigData.TC.Time);
n_TC = 2:3:15;
TC = BigData.TC_0beg{:,n_TC};
[~,N]=size(TC);
PT = BigData.PT{:,:};
DeltaPT = PT(:,2) - PT(:,1);

t_TC = [t TC];
t_PT = [t DeltaPT];

%%
figure;
subplot(211)
hold on;
plot(t, TC)
subplot(212)
hold on;
plot(t,DeltaPT)

%%
SAVE_PATH = uigetdir('Z:\Martin\Measurements\TACOT\V2_AddedSensors',"Where to store things?");
save([SAVE_PATH '\Water_PT.txt'],"t_PT",'-ascii')
for ii = 1:N
    tmp = [t TC(:,ii)];
    save([SAVE_PATH '\Water_TC' num2str(n_TC(ii)) '.txt'],"tmp",'-ascii')
end






