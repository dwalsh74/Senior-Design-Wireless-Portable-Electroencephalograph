%%          WIPEEG MATLAB CODE to Replay Session from Log File           %%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script allows the user to display a previously recorded log file   %
% for analysis. To use this script, simply press Run and enter the        %
% filename of the log file you want to view when prompted.                %
%                                                                         %
% NOTE:                                                                   %
% 1) Do not include the '.txt' extension in the file name.                %
% 2) Make sure the file is located in the current working directory. Log  %
%    files are saved there automatically so this should only be an issue  %
%    if the active directory has changed since the file was generated.    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Constant Parameters

% Clean up workspace on code execution
clear all;
close all;   

%The number of samples to display at a given time on the output plot
%Default is 1000, whole numbers only
numSamplesToDisplay = 1000;

% Y-Axis Voltage Limits
minVoltage = 0;
maxVoltage = 5;

%% Log File

% Request logfile name from user
logFileName = inputdlg('Enter the log file name below:');
logFileName = cell2mat(logFileName);

% Verify file exists in the current directory
if ~isfile(logFileName)
    
    % Get current directory
    currentFolder = pwd;
    
    text = ['Could not find a file by the name ''%s'' in the current',...
                    ' active directory. Please ensure the name was ',...
                    'entered correctly, without the ''.txt'' ',... 
                    'extension and that the file exists in the current',...
                    ' directory: (%s)\nThe code will now exit.'];
                
    msg = sprintf(text,logFileName,currentFolder);                
    msgbox(msg)
    
    % Exit code if file not found
    return;
    
end

% Open log file for reading
logFile = fopen(logFileName,'r');

% Pull data from log file
data = textscan(logFile,'%s','HeaderLines',14);

% Close the log file
fclose(logFile);

%% Process data

% Get the number of readings in the file
len = length(data{1,1});

% Eliminate non numerical and missing values
voltages = zeros(1,len);

for i = 1:len  

    % Extract cell data
    d1 = cell2mat(data{1,1}(i));
    d1 = str2num(d1);
    
    % Skip values that are not numbers
    if ~isempty(d1)
            
        % Write values to arrays
        voltages(i) = d1;
            
    end

end

%% Display Data

% Check if total session has less than 1000 samples
if len < numSamplesToDisplay
    
    % Display all values at once if so
    numSamplesToDisplay = len;
    
end

% Set up array for x axis
samples = zeros(1,numSamplesToDisplay);

for i = 1:len
    samples(i) = i;
end

% Create Plot
outputPlot = plot(samples,voltages);

% Define Plot Parameters
ylim([minVoltage maxVoltage]);
xlim([0 numSamplesToDisplay]);
outputPlot.XDataSource = 'times';
outputPlot.YDataSource = 'voltages';
title('WIPEEG Output Voltage (Click and drag to scroll)');
xlabel('Samples');
ylabel('Voltage (V)');
