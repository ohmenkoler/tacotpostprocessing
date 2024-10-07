function [BigChannels,BigChannelsNames,f_sampling] = importFILES
% This function imports 1 or more .tdms files, then extracts the 
% Channels data and names, and the number of files imported.
%   OUTPUTS:
%       BigChannels: 3D-matrix of the data channels (Nsamples x 30 x Nfiles)
%       BigChannelsNames: vector of the channels names (1 x 30)

%% Path and name
[filename,filepath] = uigetfile({'conv*.tdms';'*.xls*'},'MultiSelect','on');
if iscell(filename) == true                 % When N file are imported
    pathname = strcat(filepath,filename);   % they are already in a cell
else                                        % but when 1 is imported
    pathname = {strcat(filepath,filename)}; % it is a string (so it should
end                                         % be transtyped to a cell)

Nfiles = length(pathname);

%% Convert the files (first 1...
tmp = convertTDMS(0,pathname(1));
BigChannels = [tmp.Data.MeasuredData.Data] ;    % Initialising the BigChannels matrix 
                                                % + getting the channels for 1 file import
BigChannelsNames = {tmp.Data.MeasuredData.Name};
BigChannelsNames = BigChannelsNames(3:end);

%% ... then the other if needed)
if Nfiles ~= 1
    for ifile = 2:Nfiles                        % Start at 2 as first one is already treated in the init
        tmp = convertTDMS(0,pathname(ifile));
        Channels = [tmp.Data.MeasuredData.Data];
%         ChannelsNames = {tmp.Data.MeasuredData.Name};
%         ChannelsNames = ChannelsNames(3:end);

        BigChannels = cat(3,BigChannels,Channels);
%         BigChannelsNames = cat(3,BigChannelsNames,ChannelsNames);
    end
end
%% Sampling info
T_sampling = tmp.Data.MeasuredData(3).Property(3).Value;
f_sampling = 1 / T_sampling;

end

