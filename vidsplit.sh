#!/bin/bash
# 
# This script will split a video into frames every xx seconds
# 

# Options 
FFMPEG_OPTS=""

function usage { 
  echo "Usage $0 <inputvid> <output fps (s)> [<skip length (s)>]"
  exit 1
}

INPUTVID="$1" 
shift 
if [ -z "$INPUTVID" ]; then 
  usage
fi

HERTZ="$1"
shift
if [ -z "$HERTZ" ]; then 
  HERTZ=5
fi

SKIP="$1"
shift

# Set proper options for rest of script 
set -euo pipefail

# Check that programs are installed 
function check_bin { 
  which "$1" &>/dev/null 
  if [ "$?" -ne "0" ]; then 
    echo "$1 is not installed. Please install it to run this script" 
    exit 1
  fi
}

# Create folder for input vid 
OUTPUT_FOLDER="$(basename "$INPUTVID")"
OUTPUT_FOLDER="${OUTPUT_FOLDER%.*}"

if [ -d "$OUTPUT_FOLDER" ]; then 
  echo "Warning: folder $OUTPUT_FOLDER already exists" 
else 
  mkdir "$OUTPUT_FOLDER"
fi

# Launch ffmpeg 
ffmpeg -i "$INPUTVID" $FFMPEG_OPTS \
  -ss "$SKIP" -vf "fps=$HERTZ" \
  "$OUTPUT_FOLDER/%006d.png"

