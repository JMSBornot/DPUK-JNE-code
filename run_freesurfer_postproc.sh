#!/bin/bash

export FREESURFER_HOME=/usr/local/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh
export SUBJECTS_DIR=/home/alahmad/personalimaging/0539/Freesurfer/Subjects

allsubjs=$(ls $SUBJECTS_DIR/*.nii.gz | awk -F'Subjects/' '{print $2}' | awk -F'.nii.gz' '{print $1}' | awk '$1=$1' ORS=' ')

asegstats2table --subjects $allsubjs --meas volume --tablefile aseg_stats.txt

for meas in area volume meancurv thickness thicknessstd;
do
    for hemi in lh rh;
    do
        aparcstats2table --subjects $allsubjs --meas $meas --hemi $hemi --tablefile aparc\_$meas\_$hemi.txt
    done
done

