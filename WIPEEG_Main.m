
%%                         WIPEEG MATLAB CODE                            %%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script is used to read, process, save, and display data transmitted%
% by the WIPEEG device. The script's performance and behavior can be      %
% modified by changing the 'Constant Parameters' variables listed below.  %
%                                                                         %
% To use, simply make sure the WIPEEG is turned on and in range then      %
% press Run. If it has trouble connecting, verify the WIPEEG is           %
% transmitting to the serial port specified in the constant parameters    %
% below                                                                   %
%                                                                         %
% For more details, please see the readme which has been included in the  %
% project handover package.                                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Constant Parameters

% Clean up workspace on code execution
clear all;
close all;

% The Serial port to look for incoming WIPEEG data
% Change this value if the WIPEEG is connecting to a different COM port 
% on your pc
SerialPort='COM4'; 

% The number of data packets to process between each plot refresh
% Lower to increase plot refresh rate at the cost of processing speed
% Increase if the plot is not keeping up with the data in real time
% Default is 2, whole numbers only, do not reduce below 1
refreshConstant = 1; 
       
% Output Plot Parameters      

%The number of samples to display at any given time on the output plot
%Default is 1000, whole numbers only
numSamplesToDisplay = 1000;

% This constant dictates how many samples to shift the plot to the left 
% each time the data reaches the end
% Recommended to be around 25% of 'numSamplesToDisplay'
shiftConstant = 250;

% Y-Axis Voltage Limits
minVoltage = 0;
maxVoltage = 5;


%% Clean up  Serial Port

delete(instrfind({'Port'},{SerialPort}));
s = serialport(SerialPort,9600);

global stopToggle
stopToggle = false;

%% Set up log file

%Create new log file and get name
logFileName = fileInit();

%Open log file
logFile = fopen(logFileName,'a');

%% Set up the figure 

%Initial values for time and voltage
time = zeros(1,numSamplesToDisplay);
count = 1;

for i = 1:1:numSamplesToDisplay
    time(count) = i;
    count = count + 1;
end

voltage = zeros(1,numSamplesToDisplay);

% Used for shifting array values
voltageShift = zeros(1,shiftConstant);

% Create the plot
outputPlot = plot(time,voltage);

% Format the plot
ylim([minVoltage maxVoltage]);
outputPlot.XDataSource = 'time';
outputPlot.YDataSource = 'voltage';
title('WIPEEG Output Voltage');
xlabel('Samples');
ylabel('Voltage (V)');

% Add push button to figure to stop code execution
button = uicontrol('style','push',...
                 'units','pix',...
                 'position',[2 2 150 25],...
                 'fontsize',11,...
                 'string','Stop Recording',...
                 'callback',{@toggle});

%% Initializing variables

% Misc variables for loop
count = 1;
displayCount = 0;
firstLoop = true;
k=1;
tempStr = "";

% For the four points in each package
pointTimes = zeros(1,4);
pointVolts = zeros(1,4);

% Used to track time since last warning
warningTime = now();

%Wait one second to allow MATLAB to generate the plot
pause(1)

% Continuously read until stop button is pushed
while stopToggle == false
   
    %Shift array every n data points to allow for continuous plotting
    if count > numSamplesToDisplay - 1 
        firstLoop = false;
        count = numSamplesToDisplay - (shiftConstant - 1);
        voltage = [voltage((shiftConstant+1):numSamplesToDisplay),voltageShift];
    end
    
    % Wait until 16 bytes are available to read
    while s.NumBytesAvailable < 16
        doNothing = 1;
    end
    
    %Read from serial port
    if s.NumBytesAvailable > 15
        
        %Read serial data
        tempStr = read(s,16,"string");
        
        %Clear newline character from serial
        tt = readline(s);
        
        %Process data
        if tempStr ~= ""

            %Unpack and format data
            tempVal = strSplit(tempStr);
            
            % Update data on plot
            for i = 1:4
                
                %Convert data to volts
                volts = tempVal(i)*5/1023;
                voltage(count) = volts;
                count = count +1;
                
                % Save data to log file
                fprintf(logFile,'%f\n',volts);                 
                
            end
        end
    end
    
    % Update plot every n data points
    displayCount = displayCount + 1;
    
    if displayCount > refreshConstant
        
        refreshdata
        warning('off')
        drawnow
        warning('on')  
        
        displayCount = 0;
        
    end
    
    % Monitor if MATLAB processing begins lagging behind the transmissions
    % Create and display a warning if so
    if s.NumBytesAvailable > 150
        
        %Don't display this warning more than once every 5 second
        if (now() - warningTime) > (5e-5)
            
            % Template of warning message
            message = ['Warning at %s:\nDisplay is currently lagging %d ', ...
                        'samples behind the data transmission rate.\n', ...
                        'Consider closing other programs on your PC to ', ...
                        'improve MATLAB performance\nor increasing the ', ...
                        'refresh constant if this problem persists.'];

            % Get current time
            messageTimestamp = datetime('now','Format','HH:mm:ss');

            message = sprintf(message,messageTimestamp,s.NumBytesAvailable);

            disp(message);

            warningTime = now();
            
        end
        
    end
    
end

disp('Execution Terminated by User'); 

%% Clean up the serial port
delete(s);
clear s;

%% Functions

% A function to split a string of length 16 into 4 substrings of length 4
function [newStrArr] = strSplit(inStr)

    newStrArr(1) = parseData(extractBetween(inStr,1,4));
    newStrArr(2) = parseData(extractBetween(inStr,5,8));
    newStrArr(3) = parseData(extractBetween(inStr,9,12));
    newStrArr(4) = parseData(extractBetween(inStr,13,16));

end

% A function to take in a string, parse it and return a number
function newStr = parseData(inStr)
    
    %Default Output
    newStr = 0;
    
    %Find index of the first 'A' in the string
    index = 0;
    
    if inStr{1}(1) == 'A'
        index = 1;
        
    elseif inStr{1}(2) == 'A'
        index = 2; 
        
    elseif inStr{1}(3) == 'A'
        index = 3;
        
    elseif inStr{1}(4) == 'A'
        index = 4;
        
    end

    if index == 0
        
        %Don't change the string
        newStr = inStr;
        
        %Convert to a number
        newStr = str2double(newStr);
        
    elseif index > 0

        %Take only the numerical piece of the string
        newStr = extractBefore(inStr,index);
        
        %Convert to a number
        newStr = str2double(newStr);
        
    end
       
end

% A function to initialize the session in a text file
function logFileName = fileInit()

    %Get the current time
    timeStamp = datestr(now,'dd_mm_yyyy-HH-MM');
    
    %Create a name for the log file
    logFileName = sprintf('WIPEEG_LOG_%s',timeStamp);
    
    %Check if text file exists
    if not(isfile(logFileName))
       
        disp('Creating a new log file...');
        
        %Create the log file if not
        logFile = fopen(logFileName,'a');
        
        %Add initial header
        fprintf(logFile,"###############################################\n");        
        fprintf(logFile,"##########                           ##########\n");
        fprintf(logFile,"##########      WIPEEG LOG FILE      ##########\n");
        fprintf(logFile,"##########                           ##########\n");
        fprintf(logFile,"########## CREATED  %s ##########\n",timeStamp);
        fprintf(logFile,"##########                           ##########\n");
        fprintf(logFile,"###############################################\n");
        
        %Add header for current session
        fprintf (logFile,"\n\n############ Start of New Session ############");
        fprintf (logFile,"\n############   %s   ############\n",timeStamp);
        
        disp('Log file successfully created');
       
    else
        logFile = fopen(logFileName,'a');
    end
   
    fprintf (logFile,"\nVoltage(v)\n\n");
    
    
    %Close the file
    fclose('all');

end

function toggle(~,~)
    global stopToggle
    stopToggle = true;
end

