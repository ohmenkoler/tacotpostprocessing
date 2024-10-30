function [BigChannels,f_sampling] = importFILES
% This function imports 1 or more .tdms files, then extracts the 
% Channels data and names, and the number of files imported.
%   OUTPUTS:
%       BigChannels: 3D-matrix of the data channels (Nsamples x 30 x Nfiles)
%       f_sampling: sampling frequency of the acquisition

%% Path and name
[filename,filepath] = uigetfile({'*.tdms';'*.xls*'},'Select a .tdms file to process',...
    'Z:\Martin\Measurements\TACOT\V2_AddedSensors',...
    'MultiSelect','on');
if iscell(filename) == true                 % When N file are imported
    pathname = strcat(filepath,filename);   % they are already in a cell
else                                        % but when 1 is imported
    pathname = {strcat(filepath,filename)}; % it is a string (so it should
end                                         % be transtyped to a cell)

Nfiles = length(pathname);

%% Convert the files (first 1...

tmp_info = tdmsinfo(pathname(1));
tmp_channelGroup = tmp_info.ChannelList{1,2};
tmp_channelName = tmp_info.ChannelList{1,4};

tmp_fs = tdmsreadprop(pathname(1),ChannelGroupName=tmp_channelGroup,ChannelName=tmp_channelName);
f_sampling = 1651;%fix(1./tmp_fs{1,13}); %1651

BigChannels = tdmsread(pathname(1),SampleRate=f_sampling);
BigChannels = BigChannels{1,1};
 
%% ... then the other if needed)
if Nfiles ~= 1
    for ifile = 2:Nfiles                        % Start at 2 as first one is already treated in the init
        tmp = tdmsread(pathname(1),SampleRate=f_sampling);
       
        BigChannels = cat(3,BigChannels,tmp);
    end


end

