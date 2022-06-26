#!/usr/bin/env python3

import ffmpy, subprocess, json, shutil
from pathlib import Path
import os
import logging

# Uses ffmpy FFprobe to pull metadata and save relevant info to dictionary. Reference - https://stackoverflow.com/questions/42118339/how-to-get-the-metadata-from-a-file-using-ffmpy

def checkCodec(v):
    pullMeta = ffmpy.FFprobe(
        inputs={v: None},
        global_options=[
            '-v', 'quiet',
            '-print_format', 'json',
            '-show_format', '-show_streams']
    ).run(stdout=subprocess.PIPE)
    meta = json.loads(pullMeta[0].decode('utf-8'))
    codecs = {
        'extension': v.suffix,
        'video': meta['streams'][0]['codec_name'],
        'audio': meta['streams'][1]['codec_name'],
        'subtitle': ''
        }
    try:
        codecs['subtitle'] = meta['streams'][2]['codec_name']                               # Not all videos of a subtitle track
    except:
        codecs['subtitle'] = None

    return codecs

# Sets location of finished torrent and lists of files

name = os.environ.get('TR_TORRENT_NAME')
dir = os.environ.get('TR_TORRENT_DIR')
path = Path(dir) / name
newPath = path.parents[1] / 'TV Shows' / path.name
videoList = list(path.glob('**/*.mkv')) + list(path.glob('**/*.mp4'))                       # Creates list if videos
nonVideoList = [i for i in list(path.glob('**/*.*')) if i not in videoList]                 # Creates list of non-video files 

# Converts subtitles if they are not in SRT format
for video in videoList:
    try:
        videoCodecs = checkCodec(video)
        newVideo = str(video).replace(str(path), str(newPath))                                  # Creates path for new file
        Path(newVideo).parents[0].mkdir(exist_ok=True)                                          # Creates directories for above path

        if not Path(newVideo).is_file():                                                        # Checks if file exists already or not
            if videoCodecs['subtitle'] != 'srt' and videoCodecs['subtitle'] != None:            # Checks if subtitles are not in SRT format
                ff = ffmpy.FFmpeg(
                    inputs={video: None},
                    outputs={newVideo: '-c copy -c:s srt'}
                )
                ff.run()
            else:
                shutil.copy2(video, newVideo)
    except Exception as Argument:
        f = open('/home/pi/scripts/pythonLog.log', 'a')
        f.write(str(Argument) + '\n')
        f.close()

# Copies non-video files

try:
    for file in nonVideoList:
        newFile = str(file).replace(str(path), str(newPath))                                    # Creates path for new file
        Path(newFile).parents[0].mkdir(exist_ok=True)   
        if not Path(newFile).is_file():
            shutil.copy2(file, newFile)
except Exception as Argument:
    f = open('/home/pi/scripts/pythonLog.log', 'a')
    f.write(str(Argument) + '\n')
    f.close()


