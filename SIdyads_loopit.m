function SIdyads_loopit(subj_number, do_practice, send_trig, debug)
% Presents the social interactions dyads practice trials
%
% Inputs:
% subj_number - an integer identifying the subject
% do_practice - boolean indicating whether to run the practice
% send_trig - boolean indicating whether to check for responses
%
% Written by Emalie McMahon Oct 3, 2022

if nargin < 1
    subj_number = 77;
    do_practice = 0;
    send_trig = 0;
    debug = 1; 
end

mac = 1; 
n_repeats = 10; %How many times to loop through the full set of stimuli
break_frequency = 0; %There are 275 videos to a run. This value determines
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

% Sync tests skipped on mac
if mac
    Screen('Preference','SkipSyncTests',1);
end 

% Debugging with transparent screen
if debug
    AssertOpenGL;
    PsychDebugWindowConfiguration;
end 

%Suppress frog
Screen('Preference','VisualDebugLevel', 0);

screen = max(Screen('Screens'));
[win, rect] = Screen('OpenWindow', screen, 0);
[x0,y0] = RectCenter(rect);
Screen('Blendfunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
half_size = round(stimulus_size/2);
dispSize = [x0-half_size y0-half_size x0+half_size y0+half_size];
ifi = Screen('GetFlipInterval', window); % Measure the vertical refresh rate of the monitor
s=sprintf('%g screen flip interval', ifi);
fprintf('\n%s\n',WrapString(s));


priorityLevel=MaxPriority(win);
Priority(priorityLevel);


%% EEG - initialize
%triggers: 1 = movie start; 2 = movie end; 3 = response
if send_trig
    %    create an instance of the io64 object
    ioObj = io64; %#ok<*UNRCH>
    %   initialize the interface to the inpoutx64 system driver
    status = io64(ioObj); % if status = 0, you are now ready to write and read to a hardware port
    %  EEG port address
    address = hex2dec('4FB8');%standard LPT1 output port address
end
    
%% Set active keys
KbName('UnifyKeyNames');
active_key(1) = KbName('f');
active_keys = uint8 (zeros (1, 256));
active_keys (active_key) = 1;


%% Practice and Task instructions
if do_practice
    instructions='Watch the actions in each video. \n If there are more than 2 people in the video, hit the button. \n Press any button to begin the practice.';
    DrawFormattedText2(instructions,'win',win,'sx','center','sy','center','xalign','center','yalign', 'center','baseColor',[255, 255, 255]);
    Screen('Flip', win);
    
    if ~mac
        key = 0;
        while (~key)
            [keyPressed, ~, keyCode] = KbCheck;
            if (keyPressed)
                key = find (keyCode) == KbName ('f');
            end
        end
    else
        WaitSecs(0.25);
    end 
    
    %Call practice script
    accuracy = SIdyads_practice(win, dispSize, threshold, iti_length*1.5, send_trig);
    
    
    start_text = sprintf('Your accuracy for this section is %g%%. \n The practice is now complete. \n The time between videos for the rest of the experiment will be a bit faster. \n Press any button to begin the main experiment', accuracy);
    DrawFormattedText2(start_text,'win',win,'sx','center','sy','center','xalign','center','yalign', 'center','baseColor',[255, 255, 255]);
    Screen('Flip', win);
    
    if ~mac
        key = 0;
        while (~key)
            [keyPressed, ~, keyCode] = KbCheck;
            if (keyPressed)
                key = find (keyCode) == KbName ('f');
            end
        end
    else
        WaitSecs(0.25);
    end 
else
    %% Task instructions
    instructions='Watch the actions in each video. \n If there are more than 2 people in the video, hit the button. \n Stay still during the experiment. \n Press any button to begin the experiment.';
    DrawFormattedText2(instructions,'win',win,'sx','center','sy','center','xalign','center','yalign', 'center','baseColor',[255, 255, 255]);
    Screen('Flip', win);
    
    if ~mac
        key = 0;
        while (~key)
            [keyPressed, ~, keyCode] = KbCheck;
            if (keyPressed)
                key = find (keyCode) == KbName ('f');
            end
        end
    else
        WaitSecs(0.25);
    end 
end


%% Presentation loop
for run_number = 1:n_repeats
    %RUN THE EXPERIMENT
    accuracy = SIdyads(subj_number, run_number, win, dispSize, break_frequency, iti_length, send_trig);
    
    %PRESENT BREAK
    break_text=sprintf('Your accuracy for this section is %g%%. \n Press any button to continue.', accuracy);
    DrawFormattedText2(break_text,'win',win,'sx','center','sy','center','xalign','center','yalign', 'center','baseColor',[255, 255, 255]);
    Screen('Flip', win);
    
    if ~mac
        key = 0;
        while (~key)
            [keyPressed, ~, keyCode] = KbCheck;
            if (keyPressed)
                key = find (keyCode) == KbName ('f');
            end
        end
    else
        WaitSecs(0.25);
    end 
end

%% close window
ShowCursor;
Screen('CloseAll');