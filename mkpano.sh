#!/bin/bash
# 
# This file tries to make a panorama out of a folder of images
# 

function usage { 
  echo "Usage $0 <inputfolder>"
  exit 1
}

INFOLDER="$1" 
shift 
if [ -z "$INFOLDER" ]; then 
  usage
fi

# Set proper options for rest of script 
set -euox pipefail

PROJ="project_$(basename "$INFOLDER").pto"
KEYCACHE="keypoints.cache"

# 1: create the project file
pto_gen -f 1 -p 1 -o "$PROJ" $INFOLDER/*

# 2: create control points 
# Linear match with linear match length of 3
# Cache keypoints 
# Work on full scale data as the pictures are small (1920*1080)
cpfind \
  --linearmatch --linearmatchlen 5 \
  -c --keypath "$KEYCACHE" \
  --fullscale \
  -o "$PROJ" "$PROJ"

# 3: Set optimization parameters
# ------------------------------

# Unlink all images views (because height above seafloor can vary)
NIMGS="$(find "$INFOLDER" -type f | wc -l)" 
# for (( N=0; N<$NIMGS; N++ )); do 
#   pto_var --unlink "v$N" -o "$PROJ" "$PROJ"
# done
  
# 4: Optimize panorama 
# --------------------
# Optimise positions to get a good start
# Set aside the list of control points
./use_ctrpts.R "$PROJ" "scan"
for (( N=1; N<$NIMGS; N++ )); do 
  imgn=$N
  imgp=$(( N - 1 ))
  pto_var --opt "TrX$imgn,TrY$imgn,r$imgn" -o "$PROJ" "$PROJ"
  # Use only control points of the pair of images 
  ./use_ctrpts.R "$PROJ" "$imgp" "$imgn"
  autooptimiser -n -o "$PROJ" "$PROJ" || true
done 

# Now use all control points, and refit the whole panorama
./use_ctrpts.R "$PROJ" "all"
pto_var --opt "TrX,TrY,r" -o "$PROJ" "$PROJ"
autooptimiser -n -o "$PROJ" "$PROJ"

# 3: Cleanup control points 
# -------------------------
# echo "Cleaning up control points..." 
# cpclean -s --max-distance=2 -o "$PROJ" "$PROJ"

# 4: Refit the panorama after cleanup
# -----------------------------------
# pto_var --opt "TrX,TrY,TrZ" -o "$PROJ" "$PROJ"
# autooptimiser -n -o "$PROJ" "$PROJ"


