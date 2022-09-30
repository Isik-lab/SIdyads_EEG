# SIdyads_ECoG
 
## `SIdyads_loopit.m`
This is primarily a wrapping and looping function that calls the practice (if enabled) and the main experiment. No inputs are required, but if none are set, the `subj_number` is set to 77, there will not be practice, and no responses will be recorded by default.

## `SIdyads_practice.m`
This calls the practice code. 5 random videos (3 dyad and 2 crowd videos) are selected to be presented. The participant must reach the input threshold accuracy to be able to progress. The ISI for the practice is 1.5 times as long as for the main experiment.

## `SIdyads.m`
This is the main experiment that presents the stimuli. Breaks are enabled between the long presentation of videos with a frequency determined by the `break_frequency` input parameter. If `RTbox_connected` is set to 1, the code will attempt to connect both to the RTBox and DAQ. The accuracy for the entire run is returned. Attention check videos (videos of crowds) are randomly interspersed in the experiment and occur 9% of the time (250 dyad videos, 25 crowd videos).

## social_dyad_videos_500ms/
To run the experiment, the "social_dyad_videos_500ms/" directory must be added to the main folder. The directory can be downloaded from this [Google Drive link](https://drive.google.com/drive/folders/1-EGqd_Yp0yKg5ooeS0ujAVnPmdAlXAsC?usp=sharing).
