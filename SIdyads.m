function run_number = SIdyads(subjName, run_number, with_Eyelink, send_trigger)
% Presents the social interaction localizer task
% Inputs:
% subjName as an integer used when saving and loading the sequences
% with_Eyelink is a binaray value whether the code should connect to and
% send messages to the eyetracker
% send_trigger is a binaray value whether the code should send a trigger to
% the EEG system
% runNum is an integer used when saving and loading the sequences
% Written by Emalie McMahon Sept 6, 2023

debug = 0; % Set to zero unless no argumets are passed, then enter debug mode
if nargin < 1
    subjName = 77;
    run_number = 1;
    with_Eyelink = 0;
    send_trigger = 1;
    debug = 1;
end

% make output directories
curr = pwd;
topout = fullfile(curr, 'data', ['subj',sprintf('%03d', subjName)]);
matout = fullfile(topout, 'matfiles');
timingout = fullfile(topout, 'timingfiles');
runfiles = fullfile(topout,'runfiles');
edfout = fullfile(topout, 'edfs');
if ~exist(matout); mkdir(matout); end
if ~exist(timingout); mkdir(timingout); end
if ~exist(edfout); mkdir(edfout); end

if ~exist(topout, 'dir')
    s=sprintf('Run files do not exist of subject %g. Make run files before continuing.', subjName);
    error(s);
end


if isempty(run_number)
    % If the run_number is not assigned, find the last run and
    % increment by 1.
    files = dir(fullfile(timingout, '*.csv'));
    if ~isempty(files)
        runs = [];
        for i=1:length(files)
            f = strsplit(files(i).name, '_');
            f = strsplit(f{1},'n');
            runs(i) = str2num(f{end});
        end
        run_number = max(runs) + 1;
    else
        run_number = 1;
    end
end

s=sprintf('Subject number is %g. Run number is %g. ', subjName, run_number);
fprintf('\n%s\n\n ',WrapString(s));


%% load video list
ftoread = dir(fullfile(runfiles,['run',sprintf('%03d', run_number),'*.csv']));
T = readtable(fullfile(ftoread.folder,ftoread.name));

%% Experiment variables
curr_date = datestr(datetime('now'), 'yyyymmddTHHMMSS');
async = 4;
preloadsecs = 3;
rate = 1;
sound = 0;
blocking = 1;
stimulus_length = 0.5;
TR = .75;
iti_length = TR;
ending_wait_time = 1;
start_wait_time = TR;
n_frames = 15;
half_dim = 250;
if debug
    n_trials = 25;
else
    n_trials = height(T);
end

expected_duration = (height(T) * (stimulus_length + iti_length)) + ending_wait_time + start_wait_time;
fprintf('Expected duration: %g min \n\n', expected_duration / 60);
sca;


%% Make stimulus presentation table
%initialize data columns
T.onset_time = zeros(height(T),1);
T.offset_time = zeros(height(T),1);
T.duration = zeros(height(T),1);
T.response = zeros(height(T),1);

%Get the name of the first movie
for itrial = 1:height(T)
    video_name = T.video_name{itrial};
    if T.condition(itrial) == 1
        T.movie_path{itrial} = fullfile(curr, 'videos','dyad_videos_500ms',video_name);
    elseif T.condition(itrial) == 0
        T.movie_path{itrial} = fullfile(curr, 'videos','crowd_videos_500ms',video_name);
    end
end

movie = zeros(n_trials, 1);

%% open window
commandwindow;
HideCursor;
Screen('Preference','SkipSyncTests',1);

% Uncomment for debugging with transparent screen
AssertOpenGL;
PsychDebugWindowConfiguration;

%Suppress frogs
Screen('Preference','VisualDebugLevel', 0);

screen = max(Screen('Screens'));
[win, rect] = Screen('OpenWindow', screen, 0);
[x0,y0] = RectCenter(rect);
Screen('Blendfunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
dispSize = [x0-half_dim y0-half_dim x0+half_dim y0+half_dim];

priorityLevel=MaxPriority(win);
Priority(priorityLevel);

% Photodiode variables
photodiode_half_size = 10;
photodiode_xcenter = x0 + half_dim + 55;
photodiode_ycenter = y0 + half_dim + 55;
photodiode_square = [photodiode_xcenter-photodiode_half_size photodiode_ycenter-photodiode_half_size photodiode_xcenter+photodiode_half_size photodiode_ycenter+photodiode_half_size];
black = BlackIndex(win);
white = WhiteIndex(win);

%% Init eyelink

if with_Eyelink
    if EyelinkInit()~= 1
        return;
    end

    [~,vs] = Eyelink('GetTrackerVersion');
    fprintf('Running experiment on a ''%s'' tracker.\n', vs );

    edfFile=['run', sprintf('%03d', run_number)]; %fullfile(edfout,['run',  sprintf('%03d', run_number)]);
    el=EyelinkInitDefaults(win);%window is the window you have opened with screen function
    % open file to record data to
    Eyelink('Openfile', edfFile);

    % this line will perform the calibration
    Eyelink('command', 'calibration_type = HV9');
    EyelinkDoTrackerSetup(el);

    % set up configurations.
    Eyelink('command', 'recording_parse_type = GAZE');
    Eyelink('command', 'saccade_acceleration_threshold = 8000');
    Eyelink('command', 'saccade_velocity_threshold = 30');
    Eyelink('command', 'saccade_motion_threshold = 0.15');
    Eyelink('command', 'saccade_pursuit_fixup = 60');

    %	set EDF file contents
    Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
    Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,GAZERES,HREF,AREA');
    Eyelink('command', 'file_event_data  = GAZE,GAZERES,AREA,VELOCITY,HREF');

    %	set link data (used for gaze cursor)
    Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
    Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,HREF,AREA');
    Eyelink('command', 'link_event_data  = GAZE,GAZERES,AREA,VELOCITY,HREF');
    Eyelink('StartRecording');
    % record a few samples before we actually start displaying
    WaitSecs(0.1);

    %     eyeLinkCheck(win,x0,y0); %Additional Eyelink Validation that saves the
    %position at the beginning of the block data to help diagnose systematic
    %errors.
end

%% Init EEG
%triggers: 1 = movie start; 2 = movie end; 3 = response
if send_trigger
    SerialPortObj=serial('COM3', 'TimeOut', 1); % This is specific to the computer. you can check the port number in Device Management > Parallel Ports
    SerialPortObj.BytesAvailableFcnMode='byte';
    SerialPortObj.BytesAvailableFcnCount=1;
    SerialPortObj.BytesAvailableFcn=@ReadCallback;
    fopen(SerialPortObj);
end

%% Task instructions and start with the trigger
instructions='Watch the people in each video.\nIf there are more than 2 people, press any button.\nPress any button to begin.';
DrawFormattedText2(instructions,'win',win,'sx','center','sy','center','xalign','center','yalign', 'center','baseColor',[255, 255, 255]);
Screen('Flip', win);

%% WAIT FOR TRIGGER TO START
still_loading = 1;
while 1
    if KbCheck
        break;
    end

    if still_loading
        movie(1) = Screen('OpenMovie', win, T.movie_path{1}, async, preloadsecs);
        if movie(1) > 0; still_loading = 0; end
    end
end


%% Experiment loop
% experiment start time
% try
start = GetSecs();
Screen('Flip', win);

% wait 2 TRs to start
while (GetSecs-start<start_wait_time)
    if still_loading
        movie(1) = Screen('OpenMovie', win, T.movie_path{1}, async, preloadsecs);
        if movie(1) > 0; still_loading = 0; end
    end
end

if send_trigger
    fwrite(SerialPortObj, 0,'sync');
    WaitSecs(0.005);
end %set trigger to 0

for itrial = 1:n_trials
    still_loading = 1;
    response = 0;
    trial_start = GetSecs;
    Screen('SetMovieTimeIndex', movie(itrial), 0);
    Screen('PlayMovie', movie(itrial), rate, 1, sound);
    frame_stamps = zeros(n_frames,1);
    trial_end = trial_start + stimulus_length;
    iti_end = trial_end + iti_length;
    T.onset_time(itrial) = trial_start - start;

    if with_Eyelink %inside the trial function
        % these messages will be recorded in the output file determining the begining of the trial
        Eyelink('Message', ['TRIALID ', num2str(itrial)]);
        Eyelink('Message', ['TRIAL_VAR_DATA ', T.video_name{itrial}]);
        Eyelink('Message', 'STIMULUS_START');
    end

    frame_counter = 1;
    while 1
        if frame_counter == (n_frames+1) || GetSecs > (trial_end-(1/60))
            break;
        end

        tex = Screen('GetMovieImage', win, movie(itrial), blocking);
        Screen('DrawTexture', win, tex, [], dispSize);
        Screen('FillRect', win, black, photodiode_square); % to time it on the photodiode
        %%%% BEGIN SACRED TIMING SENSITIVE SECTION%%%%
        [frame_stamps(frame_counter),~,~,~] = Screen('Flip',win); % Odd sequencing, but want 'ScreenFlip' right after DAQ on
        if frame_counter==1 && send_trigger
            fwrite(SerialPortObj, 1,'sync');
            WaitSecs(0.005);
        end %send trigger for video start
        Screen('Close', tex);

        if ~response
            if KbCheck
                response = 1;
                T.response(itrial) = 1;

                if send_trigger
                    fwrite(SerialPortObj, 3,'sync');
                    WaitSecs(0.005);
                end %send trigger for response
            end
        end
        frame_counter = frame_counter + 1;
    end
    Screen('FillRect', win, white, photodiode_square); % to time it on the photodiode
    real_trial_end = Screen('Flip', win);
    if send_trigger
        fwrite(SerialPortObj, 2,'sync');
        WaitSecs(0.005);
    end %send trigger for video end
    %%%% END SACRED TIMING SENSITIVE SECTION%%%%

    %Get end time and close movie
    T.offset_time(itrial) = real_trial_end - start;
    T.duration(itrial) = real_trial_end - trial_start;
    Screen('CloseMovie', movie(itrial));

    message_sent = 0;
    while (GetSecs<iti_end)
        if with_Eyelink && ~message_sent
            Eyelink('Message','STIMULUS_OFF');
            message_sent = 1;
        end
        if still_loading && itrial ~= n_trials
            movie(itrial+1) = Screen('OpenMovie', win, T.movie_path{itrial+1}, async, preloadsecs);
            if movie(itrial+1) > 0; still_loading = 0; end
        end

        if ~response
            if KbCheck
                response = 1;
                T.response(itrial) = 1;

                if send_trigger
                    fwrite(SerialPortObj, 3,'sync');
                    WaitSecs(0.005);
                end %send trigger for response

            end
        end
    end

    if itrial ~= height(T)
        if T.block(itrial) ~= T.block(itrial + 1)
            DrawFormattedText2('Take a short break./n Press any button when ready to continue.','win',win,'sx','center','sy','center','xalign','center','yalign', 'center','baseColor',[255, 255, 255]);
            Screen('Flip', win);
            fprintf('Break in experiment');
            while 1
                if KbCheck
                    break;
                end
            end
        end
    else %itrial == height(T)
        instructions = 'You may sit back.\nLonger break is beginning.\nThis window will close.\n';

        DrawFormattedText2(instructions,'win',win,'sx','center','sy','center','xalign','center','yalign', 'center','baseColor',[255, 255, 255]);
        Screen('Flip', win);
        fprintf('End of run');
        WaitSecs(3);
    end
end

%% Save data
actual_duration = GetSecs() - start;
save(fullfile(matout,['run', sprintf('%03d', run_number) '_',curr_date,'.mat']))
filename = fullfile(timingout,['run', sprintf('%03d', run_number), '_',curr_date,'.csv']);
writetable(T, filename);
ShowCursor;
Screen('CloseAll')

%% save eyelink and close
if with_Eyelink
    Eyelink('Stoprecording')
    Eyelink('CloseFile');
    try
        fprintf('Receiving data file ''%s''\n', edfFile );
        status=Eyelink('ReceiveFile',edfFile);
        if status > 0
            fprintf('ReceiveFile status %d\n', status);
        end
        if exist(edfFile, 'file')
            fprintf('Data file ''%s'' can be found in ''%s''\n', edfFile, pwd );
        end
    catch
        fprintf('Problem receiving data file ''%s''\n', edfFile );
    end
    Eyelink('ShutDown');

    try
        movefile([edfFile,'.edf'], fullfile(edfout, [edfFile, '_', curr_date, '.edf']));
        move_error = 'No';
    catch
        move_error = 'Yes';
    end
    fprintf(['Move EDF Error? ',move_error,'\n'])
end

%% Print participant performance
false_alarms = sum(T.response(T.condition == 1) == 1);
hits = sum(T.response(T.condition == 0) == 1);
total_accuracy = mean(T.condition ~= T.response);
s=sprintf('%d hits \n%d false alarms\nOverall accuracy was %0.2f.', hits, false_alarms, total_accuracy);
fprintf('\n\n\n%s\n',WrapString(s));
s=sprintf('Experiment duration %0.1f s', actual_duration);
fprintf('\n\n\n%s\n',WrapString(s));

if send_trigger
    % Reset the port (i.e. bit 0 to 7) to its resting state 255
    fwrite(SerialPortObj, 255,'sync');
    WaitSecs(0.005);
    % Then disconnect/close the serial port object from the serial port
    fclose(SerialPortObj);
    % Remove the serial port object from memory
    delete(SerialPortObj);
    % Remove the serial port object from the MATLAB® workspace
    clear SerialPortObj;
end
end

% Read callback function
function ReadCallback(src, event)
%disp(event.Type);
if(src.BytesAvailable > 0)
    disp(fread(src, src.BytesAvailable));
end
end
