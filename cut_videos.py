import cv2
from glob import glob
from tqdm import tqdm

def cut_video(input_path, output_path, video_length):
    # Open the input video file
    cap = cv2.VideoCapture(input_path)
    
    # Check if the video file opened successfully
    if not cap.isOpened():
        print("Error: Couldn't open the video file.")
        return
    
    # Get the video frame rate (fps) and frame size
    fps = int(cap.get(cv2.CAP_PROP_FPS))
    frame_size = (int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)), int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT)))
    
    # Create a VideoWriter object to save the output video
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')  # codec for mp4 format
    out = cv2.VideoWriter(output_path, fourcc, fps, frame_size)
    
    # Initialize variables to keep track of time and frames
    total_frames = 0  # total frames processed
    stop_frame = int(video_length * fps)
    
    while cap.isOpened():
        ret, frame = cap.read()  # read a frame
        
        if not ret:
            break  # exit the loop if the video ended or an error occurred
        
        # Write the frame to the output video
        out.write(frame)
        
        # Update the total frames processed
        total_frames += 1
        
        # Stop processing after reaching the stop_frame
        if total_frames >= stop_frame:
            break
    
    # Release the video objects and close the windows
    cap.release()
    out.release()
    cv2.destroyAllWindows()

# Example usage
input_path = '/Users/emcmaho7/Downloads/crowd_videos_3000ms'
output_path = '/Users/emcmaho7/Dropbox/projects/SI_EEG/SIdyads_EEG/videos/crowd_videos_800ms'
input_videos = glob(f'{input_path}/*.mp4')
for video in tqdm(input_videos, total=len(input_videos)):
    vid_name = video.split('/')[-1]
    cut_video(video, f'{output_path}/{vid_name}', .8)
