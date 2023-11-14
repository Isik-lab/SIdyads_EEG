#
import os
import time
import argparse
import numpy as np
from pathlib import Path
import pandas as pd
from glob import glob


def load_video_names(files, n_repeats):
    df = []
    for f in files:
        cur = pd.read_csv(f)
        df.append(cur)
    vid_array = pd.concat(df).video_name.to_numpy()
    out_array = []
    for i in range(n_repeats):
        cur_array = vid_array.copy()
        np.random.shuffle(cur_array)
        out_array.append(cur_array)
    out_array = np.concatenate(out_array)
    return out_array


def mk_output_paths(toppath):
    print('\nSubject directory not yet created. I will make it for you...')
    Path(os.path.join(toppath, 'runfiles')).mkdir(parents=True, exist_ok=True)


def add_filler_trials(crowd_videos, n=5):
    movie_path = np.random.choice(crowd_videos, size=n, replace=False)
    video_name = [Path(vid).stem + '.mp4' for vid in movie_path]
    return pd.DataFrame({'video_name': video_name, 'condition': [0 for i in range(n)]})


def mk_block(dyad_block, crowd_videos, n):
    crowd_df = add_filler_trials(crowd_videos, int(len(dyad_block)*.1))
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


def mk_condition_files(SID=77, n_runs=6, n_blocks=8,
                        train_repeats=1, test_repeats=4,
                        top_path=None):
    if top_path is None:
        top_path = os.getcwd()
    crowd_videos = np.array(glob(os.path.join(top_path, 'videos',
                                              'crowd_videos_500ms', '*.mp4')))
    out_path = os.path.join(top_path, 'data', f'subj{str(SID).zfill(3)}')
    print(out_path)
    mk_output_paths(out_path)

    print('\nWriting run files...')
    videos = []
    for dataset, repeats in zip(['train', 'test'],
                                 [train_repeats, test_repeats]):
        videos.append(load_video_names([f'{top_path}/{dataset}.csv'], repeats))
    videos = np.concatenate(videos).reshape((n_blocks, -1))
    blocks = np.arange(n_blocks)
    np.random.shuffle(blocks)
    videos = videos[blocks]

    for i in range(n_runs):
        run_df = []
        for j in range(n_blocks):
            block_df = mk_block(videos[j], crowd_videos, j+1)
            run_df.append(block_df)
        run_df = pd.concat(run_df)
        run_df['iti'] = sample_normal_within_range(1.25, 0.1, 1, 1.5, len(run_df))
        outname = os.path.join(out_path, 'runfiles', f'run{str(i+1).zfill(3)}.csv')
        save_data(run_df, outname)
        print(f'run {i+1} duration = {run_df.iti.sum() + (len(run_df) * .5)} s')
    print('\nRuns assigned. Closing...')


def getArgs():
    parser = argparse.ArgumentParser()
    parser.add_argument('--sid', '-s', type=int, default=77)
    parser.add_argument('--n_runs', type=int, default=4)
    parser.add_argument('--n_blocks', type=int, default=8)
    parser.add_argument('--test_repeats', type=int, default=4)
    parser.add_argument('--train_repeats', type=int, default=1)
    parser.add_argument('--top_path', type=str, default='/Users/emcmaho7/Dropbox/projects/SI_EEG/SIdyads_EEG')
    args = parser.parse_args()
    return args


if __name__ == "__main__":
    args = getArgs()
    mk_condition_files(args.sid, args.n_runs, args.n_blocks, args.train_repeats, args.test_repeats, args.top_path)
