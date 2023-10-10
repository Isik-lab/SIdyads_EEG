#
import os
import time
import argparse
import numpy as np
from pathlib import Path
import pandas as pd
from glob import glob


def load_video_names(files, n_blocks):
    df = []
    for f in files:
        cur = pd.read_csv(f)
        df.append(cur)
    vid_array = pd.concat(df).video_name.to_numpy()
    np.random.shuffle(vid_array)
    return vid_array.reshape((n_blocks, -1))


def mk_output_paths(SID, toppath):
    print('\nSubject directory not yet created. I will make it for you...')
    Path(toppath).mkdir(parents=True, exist_ok=True)
    Path(os.path.join('data', f'subj{str(SID).zfill(3)}', 
'runfiles')).mkdir(parents=True, exist_ok=True)


def add_filler_trials(n=5):
    crowd_videos = np.array(glob(os.path.join(os.getcwd(), 'videos', 
                                              'crowd_videos_500ms', '*.mp4')))
    movie_path = np.random.choice(crowd_videos, size=n, replace=False)
    video_name = [Path(vid).stem + '.mp4' for vid in movie_path]
    return pd.DataFrame({'video_name': video_name, 'condition': [0 for i in range(n)]})


def mk_block(dyad_block, n):
    crowd_df = add_filler_trials(int(len(dyad_block)*.1))
    dyad_block_df = pd.DataFrame({'video_name': dyad_block,
                                   'condition': np.ones(len(dyad_block), dtype='int')})
    out_df = pd.concat([dyad_block_df, crowd_df]).sample(frac = 1)
    out_df['block'] = n
    return out_df


def save_data(df, filename):
    df.to_csv(filename, index=False, header=True)


def sample_normal_within_range(mu, sigma, low, high, size, precision=1):
    samples = []
    while len(samples) < size:
        s = np.round(np.random.normal(mu, sigma), precision)
        if low <= s <= high:
            samples.append(s)
    return np.array(samples)


def mk_condition_files(SID=77, n_runs=10, n_blocks=5):
    toppath = os.path.join('data', f'subj{str(SID).zfill(3)}')
    mk_output_paths(SID, toppath)
    print('\nWriting run files...')
    videos = load_video_names(['train.csv', 'test.csv'], n_blocks)
    for i in range(n_runs):
        run_df = []
        for j in range(n_blocks):
            block_df = mk_block(videos[j], j+1)
            run_df.append(block_df)
        run_df = pd.concat(run_df)
        run_df['iti'] = sample_normal_within_range(1.25, 0.1, 1, 1.5, len(run_df))
        outname = os.path.join(toppath, 'runfiles', f'run{str(i+1).zfill(3)}.csv')
        save_data(run_df, outname)
    print('\nRuns assigned. Closing...')


def getArgs():
    parser = argparse.ArgumentParser()
    parser.add_argument('--sid', '-s', type=int, default=77)
    parser.add_argument('--n_runs', type=int, default=10)
    parser.add_argument('--n_blocks', type=int, default=5)
    args = parser.parse_args()
    return args


if __name__ == "__main__":
    args = getArgs()
    mk_condition_files(args.sid, args.n_runs, args.n_blocks)
