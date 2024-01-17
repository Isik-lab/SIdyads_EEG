Screen('Preference','SkipSyncTests',1);
Screen('Preference','VisualDebugLevel', 0);

screen = max(Screen('Screens'));
[win, rect] = Screen('OpenWindow', screen, 0);
[x0,y0] = RectCenter(rect);
Screen('Blendfunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
commandwindow;

half_dim = 250;
dispSize = [x0-half_dim y0-half_dim x0+half_dim y0+half_dim];

priorityLevel=MaxPriority(win);
Priority(priorityLevel);

% Photodiode variables
photodiode_half_size = 10;
photodiode_xcenter = x0;
photodiode_ycenter = y0 + half_dim + 100;
photodiode_square = [photodiode_xcenter-photodiode_half_size photodiode_ycenter-photodiode_half_size photodiode_xcenter+photodiode_half_size photodiode_ycenter+photodiode_half_size];
white = WhiteIndex(win);

Screen('FillRect', win, white, photodiode_square); % to time it on the photodiode
real_trial_end = Screen('Flip', win);

wait = 1;
while wait
    if KbCheck
        wait = 0;
    end
end

sca;