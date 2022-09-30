function SIdyads_loopit(subj_number, do_practice, RTbox_connected)
% Presents the social interactions dyads practice trials
%
% Inputs:
% subj_number - an integer identifying the subject
% do_practice - boolean indicating whether to run the practice
% RTbox_connected - boolean indicating whether to check for responses
%
% Written by Emalie McMahon Oct 7, 2021

if nargin < 1
    subj_number = 77;
    do_practice = 0;
    RTbox_connected = 0;
end

n_repeats = 4; %How many times to loop through the full set of stimuli
break_frequency = 2; %There are 275 videos to a run. This value determines
%how frequently to break up those movies. A value of 2 would lead a
%break every ~138 videos (275/2). If set to 0 there are no breaks.
iti_length = 1; %time between stimuli in seconds
threshold = 60; %accuracy threshold for practice to continue.
%There are five trials, so 80% is missing one trial
stimulus_size = 1000; %The size of the movie to display in pixels.
%May need to be adjusted for the size of the screen.

%% open window
commandwindow;
HideCursor;

% Uncomment if presenting on Mac.
% Screen('Preference','SkipSyncTests',1);

% Uncomment for debugging with transparent screen
% AssertOpenGL;
% PsychDebugWindowConfiguration;

%Suppress frog
Screen('Preference','VisualDebugLevel', 0);

screen = max(Screen('Screens'));
[win, rect] = Screen('OpenWindow', screen, 0);
[x0,y0] = RectCenter(rect);
Screen('Blendfunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
half_size = round(stimulus_size/2);
dispSize = [x0-half_size y0-half_size x0+half_size y0+half_size];

priorityLevel=MaxPriority(win);
Priority(priorityLevel);

%% Set up RTBox
if RTbox_connected
    % Clear RT Box
    RTBox('ClockRatio', 10);
    RTBox('clear',20);
    bpts = [];
end

if do_practice
    %% Practice and Task instructions
    instructions='Watch the actions in each video. \n If there are more than 2 people in the video, hit the button. \n Press any button to begin the practice.';
    DrawFormattedText2(instructions,'win',win,'sx','center','sy','center','xalign','center','yalign', 'center','baseColor',[255, 255, 255]);
    Screen('Flip', win);
    %If the button box is connected, it should wait for a button press to continue
    if RTbox_connected
        while isempty(bpts)
            [bpts,~] = RTBox; %Check for RTBox events
        end
    else
        WaitSecs(1.5);
    end
    
    %Call practice script
    accuracy = SIdyads_practice(win, dispSize, threshold, iti_length*1.5, RTbox_connected);
    
    %% Wait to begin
    if RTbox_connected
        % Clear RT Box
        RTBox('clear',20);
        bpts = [];
    end
    start_text = sprintf('Your accuracy for this section is %g%%. \n The practice is now complete. \n The time between videos for the rest of the experiment will be a bit faster. \n Press any button to begin the main experiment', accuracy);
    DrawFormattedText2(start_text,'win',win,'sx','center','sy','center','xalign','center','yalign', 'center','baseColor',[255, 255, 255]);
    Screen('Flip', win);
    if RTbox_connected
        %If the button box is connected, it should wait for a button press to continue
        while isempty(bpts)
            [bpts,~] = RTBox; %Check for RTBox events
        end
    else
        WaitSecs(1.5);
    end
else
    %% Task instructions
    instructions='Watch the actions in each video. \n If there are more than 2 people in the video, hit the button. \n Press any button to begin the experiment.';
    DrawFormattedText2(instructions,'win',win,'sx','center','sy','center','xalign','center','yalign', 'center','baseColor',[255, 255, 255]);
    Screen('Flip', win);
    if RTbox_connected
        %If the button box is connected, it should wait for a button press to continue
        while isempty(bpts)
            [bpts,~] = RTBox; %Check for RTBox events
        end
    else
        WaitSecs(1.5);
    end
end


%% Presentation loop
for run_number = 1:n_repeats
    if RTbox_connected
        % Clear RT Box
        RTBox('clear',20);
        bpts = [];
    end
    
    %RUN THE EXPERIMENT
    accuracy = SIdyads(subj_number, run_number, win, dispSize, break_frequency, iti_length, RTbox_connected);
    
    %PRESENT BREAK
    break_text=sprintf('Your accuracy for this section is %g%%. \n Press any button to continue.', accuracy);
    DrawFormattedText2(break_text,'win',win,'sx','center','sy','center','xalign','center','yalign', 'center','baseColor',[255, 255, 255]);
    Screen('Flip', win);
    if RTbox_connected
        %If the button box is connected, it should wait for a button press to continue
        while isempty(bpts)
            [bpts,~] = RTBox; %Check for RTBox events
        end
    else
        WaitSecs(1.5);
    end
end

%% close window
ShowCursor;
Screen('CloseAll');