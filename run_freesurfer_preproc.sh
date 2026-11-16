#!/bin/bash

export FREESURFER_HOME=/usr/local/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh
export SUBJECTS_DIR=/home/alahmad/personalimaging/0539/Freesurfer/Subjects

for fname in $( ls $SUBJECTS_DIR/*.nii.gz )
do
    recon-all -threads 3 -i $fname -subjid ${fname:0:${#fname}-7} -all -qcache
done

