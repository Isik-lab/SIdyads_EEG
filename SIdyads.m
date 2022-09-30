function total_accuracy = SIdyads(subj_number, run_number, win, dispSize, break_frequency, iti_length, RTbox_connected)
% Presents the social interactions dyads experiment for ECoG
%
% Inputs:
% subj_number - an integer identifying the subject
% run_number - an integer identifying the current run
% win - the window pointer for psychtoolbox
% dispSize - the rectangle where the stimulus should be presented
% break_frequency - an integer indicating how often to have breaks in the
% There are 275 videos to a run. A value of 2, for example, would lead to a
% break every ~138 videos (275/2).
% iti_length - the amount of time between stimuli in seconds
% RTbox_connected - boolean indicating whether to check for responses
%
% Outputs:
% The total accuracy for the current run
%
% Written by Emalie McMahon Oct 7, 2021



if nargin < 1
    subj_number = 77;
    run_number = 1;
    RTbox_connected = 0;
    iti_length = 1;
    break_frequency = 0; 
    
    %% open window
    commandwindow;
    %     HideCursor;
    Screen('Preference','SkipSyncTests',1);

    % Uncomment for debugging with transparent screen
%     AssertOpenGL;
%     PsychDebugWindowConfiguration;

    screen = max(Screen('Screens'));
    [win, rect] = Screen('OpenWindow', screen, 0);
    [x0,y0] = RectCenter(rect);
    Screen('Blendfunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    dispSize = [x0-500 y0-500 x0+500 y0+500];

    priorityLevel=MaxPriority(win);
    Priority(priorityLevel);
end

% make output directories
curr = pwd;
topout = fullfile(curr, 'data', ['sub',sprintf('%02d', subj_number)]);
matout = fullfile(topout, 'matfiles');
if ~exist(matout, 'dir'); mkdir(matout); end 
timingout = fullfile(topout, 'timingfiles');
if ~exist(timingout, 'dir'); mkdir(timingout); end 

s=sprintf('Subject number is %g. Run number is %g. ', subj_number, run_number);
fprintf('\n%s\n\n ',WrapString(s));

%% Experiment variables
curr_date = datestr(datetime('now'), 'yyyymmddTHHMMSS');
async = 4;
preloadsecs = 3;
rate = 1;
sound = 0;
blocking = 1;
stimulus_length = 0.5;
iti_jitter = 0.05;
n_response = 25;
n_real = 250;
n_extra_iti = 25;
ending_wait_time = 0;
start_wait_time = iti_length;
n_frames = 15;

%% Make stimulus presentation table

%load video list
video_names = dir('social_dyad_videos_500ms/short_videos/*.mp4');
vid_inds = randperm(length(video_names));
vid_inds = vid_inds(1:n_real); 
video_list = cell(n_real, 1);
for i = 1:n_real
    video_list{i} = video_names(vid_inds(i)).name;
end

%get filler videos
crowd_names = dir(fullfile('social_dyad_videos_500ms','crowd_videos_short','*.mp4'));
inds = randperm(length(crowd_names));
inds = inds(1:n_response); 
response_videos = cell(n_response,1);
for i = 1:n_response
    response_videos{i} = crowd_names(inds(i)).name;
end

video_list = [video_list, num2cell(ones(n_real, 1)), num2cell(zeros(n_real, 1)), num2cell(zeros(n_real, 1)), num2cell(zeros(n_real, 1)), num2cell(zeros(n_real, 1)), num2cell(zeros(n_real, 1));...
    response_videos, num2cell(zeros(n_response, 1)), num2cell(zeros(n_response, 1)), num2cell(zeros(n_response, 1)), num2cell(zeros(n_response, 1)), num2cell(zeros(n_response, 1)), num2cell(zeros(n_response, 1))];
video_table = cell2table(video_list);
video_table.Properties.VariableNames = {'video_name' 'condition' 'onset_time' 'offset_time' 'duration' 'response' 'response_time'};
T = video_table(randperm(size(video_table,1)), :);

add_jitter = [ones(n_extra_iti,1); zeros(size(T,1)-n_extra_iti-1,1)];
add_jitter = add_jitter(randperm(length(add_jitter)));
add_jitter(end+1) = ending_wait_time/iti_jitter;
T.added_jitter = add_jitter;
n_trials = size(T, 1);

%Save the presentation table at the beginning just in case
filename = fullfile(timingout,['run', sprintf('%03d', run_number), '_',curr_date,'.csv']);
writetable(T, filename);

%Get the name of the first movie
for itrial = 1:n_trials
    video_name = split(T.video_name{itrial},'.');
    video_name = [video_name{1},'.mp4'];
    if T.condition(itrial) == 1
        T.movie_path{itrial} = fullfile(curr, 'social_dyad_videos_500ms','short_videos',video_name);
    elseif T.condition(itrial) == 0
        T.movie_path{itrial} = fullfile(curr, 'social_dyad_videos_500ms','crowd_videos_short',video_name);
    end
end
movie = zeros(n_trials, 1);
still_loading = 1; %The first movie is not yet loaded


%% Set up DAQ and RTBox
if RTbox_connected
    % Initialize DAQ
    DAQ_level = 255;
    HID=DaqFind;
    DaqDConfigPort(HID,0,0);
    DaqDOut(HID,0,0);  %Turn off
    % Clear RT Box
    RTBox('ClockRatio', 10);
    RTBox('clear',20);
end 

%% Experiment loop
% experiment start time
start = GetSecs();
Screen('Flip', win);

% wait half a second to start
while (GetSecs-start<start_wait_time)
    if still_loading
        movie(1) = Screen('OpenMovie', win, T.movie_path{1}, async, preloadsecs);
        if movie(1) > 0; still_loading = 0; end
    end
end

for itrial = 1:n_trials
    if RTbox_connected
        RTBox('clear',20); %Clear button box
        bpts = [];
    end 
    still_loading = 1; %Value of one means that the next movie is still loading
    
    Screen('SetMovieTimeIndex', movie(itrial), 0);
    Screen('PlayMovie', movie(itrial), rate, 1, sound);
    frame_stamps = zeros(n_frames,1);
    for idx = 1:n_frames
        tex = Screen('GetMovieImage', win, movie(itrial), blocking);
        Screen('DrawTexture', win, tex, [], dispSize);
        %%%% BEGIN SACRED TIMING SENSITIVE SECTION%%%%
        [frame_stamps(idx),~,~,~] = Screen('Flip',win); % Odd sequencing, but want 'ScreenFlip' right after DAQ on
        if idx==1 && RTbox_connected
            DaqDOut(HID,0,DAQ_level);  % DAQ On
            WaitSecs(0.005);           % Wait 5 ms
            DaqDOut(HID,0,0);          % DAQ Off
        end
        Screen('Close',tex);
    end
    real_trial_end = Screen('Flip', win);
    if RTbox_connected
        DaqDOut(HID,0,DAQ_level);  % DAQ On
        WaitSecs(0.005);           % Wait 5 ms
        DaqDOut(HID,0,0);          % DAQ Off
    end 
    %%%% END SACRED TIMING SENSITIVE SECTION%%%%
    T.onset_time(itrial) = frame_stamps(1) - start;
    
    %Save end time and close movie
    T.offset_time(itrial) = real_trial_end - start;
    T.duration(itrial) = real_trial_end - start - T.onset_time(itrial);
    Screen('CloseMovie', movie(itrial));
    
    while still_loading && itrial < n_trials
        movie(itrial+1) = Screen('OpenMovie', win, T.movie_path{itrial+1}, async, preloadsecs);
        if movie(itrial+1) > 0; still_loading = 0; end
    end
    
    iti_end = T.onset_time(itrial) + stimulus_length + iti_length + T.added_jitter(itrial)*iti_jitter;
    %Wait until the end of the ITI
    while ((GetSecs-start)<iti_end); end
    
    if RTbox_connected
        [bpts,~] = RTBox; % Pull RTBox events and log the last button press
        if ~isempty(bpts)
            T.response_time(itrial) = bpts(end) - T.onset_time(itrial);
            T.response(itrial) = 1;
        end
    end
    
    %% Experiment break
    if break_frequency 
        if rem(itrial, round(n_trials/break_frequency)) == 0
        if RTbox_connected
            RTBox('clear',20); %Clear button box
            bpts = [];
        end
        
        current_accuracy = round(mean(T.condition(1:itrial) ~= T.response(1:itrial)) * 100); 
        break_text=sprintf('Your accuracy for this section is %g%%. \n Press any button to continue.', current_accuracy);
        DrawFormattedText2(break_text,'win',win,'sx','center','sy','center','xalign','center','yalign', 'center','baseColor',[255, 255, 255]);
        Screen('Flip', win);
        
        %If the button box is connected, it should wait for a button press to continue
        if RTbox_connected
            while isempty(bpts)
                [bpts,~] = RTBox; %Check for RTBox events
            end
        else
            WaitSecs(1.5);
        end
        
        save(fullfile(matout,['run', sprintf('%03d', run_number) '_',curr_date,'.mat']))
        end 
    end 
end

save(fullfile(matout,['run', sprintf('%03d', run_number) '_',curr_date,'.mat']))
writetable(T, filename);

%Print participant performance
false_alarms = sum(T.response(T.condition == 1) == 1);
hits = sum(T.response(T.condition == 0) == 1);
total_accuracy = round(mean(T.condition ~= T.response) * 100);
s=sprintf('%g hits out of %g crowd videos. %g false alarms out of %g dyad videos. Overall accuracy is %g%%.', hits, n_response, false_alarms, n_real, total_accuracy);
fprintf('\n\n\n%s\n',WrapString(s));
s=sprintf('Subject %g, run %g: Complete. ', subj_number, run_number);
fprintf('\n%s\n ',WrapString(s));

if nargin < 1
    sca;
end 
end