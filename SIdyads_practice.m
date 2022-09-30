function total_accuracy = SIdyads_practice(win, dispSize, threshold, iti_length, RTbox_connected)
% Presents the social interactions dyads practice trials
%
% Inputs:
% win - the window pointer for psychtoolbox
% dispSize - the rectangle where the stimulus should be presented
% threshold - the accuracy needed to progress past the practice trials
% iti_length - the amount of time between stimuli in seconds
% RTbox_connected - boolean indicating whether to check for responses
%
% Outputs:
% The practice accuracy acheived
%
% Written by Emalie McMahon Oct 7, 2021


if nargin < 1
    threshold = 80;
    iti_length = 0.75;
    
    %% open window
    commandwindow;
    %     HideCursor;
    Screen('Preference','SkipSyncTests',1);
    
    % Uncomment for debugging with transparent screen
    AssertOpenGL;
    PsychDebugWindowConfiguration;
    
    screen = max(Screen('Screens'));
    [win, rect] = Screen('OpenWindow', screen, 0);
    [x0,y0] = RectCenter(rect);
    Screen('Blendfunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    dispSize = [x0-500 y0-500 x0+500 y0+500];
    
    priorityLevel=MaxPriority(win);
    Priority(priorityLevel);
end

trigger = 0; %Place holder that needs to be removed

%% Experiment variables
curr = pwd;
async = 4;
preloadsecs = 3;
rate = 1;
sound = 0;
blocking = 1;
stimulus_length = 0.5;
iti_jitter = 0.05;
n_response = 2;
n_real = 3;
n_extra_iti = 0;
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

video_list = [video_list, num2cell(ones(n_real, 1)), num2cell(zeros(n_real, 1)), num2cell(zeros(n_real, 1)), num2cell(zeros(n_real, 1)), num2cell(zeros(n_real, 1));...
    response_videos, num2cell(zeros(n_response, 1)), num2cell(zeros(n_response, 1)), num2cell(zeros(n_response, 1)), num2cell(zeros(n_response, 1)), num2cell(zeros(n_response, 1))];
video_table = cell2table(video_list);
video_table.Properties.VariableNames = {'video_name' 'condition' 'onset_time' 'offset_time' 'duration' 'response'};
T = video_table(randperm(size(video_table,1)), :);

add_jitter = [ones(n_extra_iti,1); zeros(size(T,1)-n_extra_iti-1,1)];
add_jitter = add_jitter(randperm(length(add_jitter)));
add_jitter(end+1) = ending_wait_time/iti_jitter;
T.added_jitter = add_jitter;
n_trials = size(T, 1);

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
still_loading = 1;

%% Set up RTBox
if RTbox_connected
    RTBox('ClockRatio', 10);
    RTBox('clear',20);
end

%% Experiment loop
total_accuracy = 0;
while total_accuracy < threshold
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
        end
        still_loading = 1;
        frame_counter = 1;
        trial_start = GetSecs;
        Screen('SetMovieTimeIndex', movie(itrial), 0);
        Screen('PlayMovie', movie(itrial), rate, 1, sound);
        trial_end = trial_start + stimulus_length;
        iti_end = trial_end + iti_length + T.added_jitter(itrial)*iti_jitter;
        T.onset_time(itrial) = trial_start - start;
        while 1
            if frame_counter == n_frames
                break;
            end
            tex = Screen('GetMovieImage', win, movie(itrial), blocking);
            Screen('DrawTexture', win, tex, [], dispSize);
            Screen('Flip', win);
            Screen('Close', tex);
            
            if still_loading && itrial ~= n_trials
                movie(itrial+1) = Screen('OpenMovie', win, T.movie_path{itrial+1}, async, preloadsecs);
                if movie(itrial+1) > 0; still_loading = 0; end
            end
            frame_counter = frame_counter + 1;
        end
        
        %Get end time and close movie
        real_trial_end = Screen('Flip', win);
        T.offset_time(itrial) = real_trial_end - start;
        T.duration(itrial) = real_trial_end - trial_start;
        Screen('CloseMovie', movie(itrial));
        
        while (GetSecs<iti_end)
            if still_loading && itrial ~= n_trials
                movie(itrial+1) = Screen('OpenMovie', win, T.movie_path{itrial+1}, async, preloadsecs);
                if movie(itrial+1) > 0; still_loading = 0; end
            end
        end
        
        if RTbox_connected
            [~,bps] = RTBox; % Pull RTBox events and log the last button press
            if ~isempty(bps)
                T.response(itrial) = 1;
            end
        end
    end
    
    %Print participant performance
    false_alarms = sum(T.response(T.condition == 1) == 1);
    hits = sum(T.response(T.condition == 0) == 1);
    total_accuracy = round(mean(T.condition ~= T.response) * 100);
    s=sprintf('%g hits out of %g crowd videos. %g false alarms out of %g dyad videos. Overall accuracy is %g%%.', hits, n_response, false_alarms, n_real, total_accuracy);
    fprintf('\n\n\n%s\n',WrapString(s));
    
    if total_accuracy < threshold
        break_text=sprintf('Your accuracy was %g%%. \n Let''s try the practice again. \n If you have any questions, please ask the experimenter now.', total_accuracy);
        DrawFormattedText2(break_text,'win',win,'sx','center','sy','center','xalign','center','yalign', 'center','baseColor',[255, 255, 255]);
        Screen('Flip', win);
        %Add the button press to continue here
        WaitSecs(1.5);
    end
end

if nargin < 1
    sca;
end
end