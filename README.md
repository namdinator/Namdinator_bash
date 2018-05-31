# Namdinator

Namdinator is a commandline tool, written in BASH, that sets up and runs a MDFF (molecular Dynamics Flexible Fit) simulation in a semi automatic manner, using only the input PDB file and input density file.

To run Namdinator you need the following programs installed:

VMD 1.93: http://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=VMD

NAMD 2.12 cuda version :http://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=NAMD

Phenix software package version 1.13rc1 (2954): https://www.phenix-online.org/download/

Rosetta modelleing software package (ver. 2016.32.58837): https://www.rosettacommons.org/software/license-and-download

Example on how to run Namdinator with default settings plus including a phenix.real_space_refine run:

./Namdinator_local.sh -p input.pdb -m map.mrc -r 3.5 -x

-p is the input PDB file (mandatory), -m is the input density in .mrc format (mandatory), -r is the resolution of the input density (mandatory) and -x is to turn on phenix.real.space refinement (Optional, but recommended).


I have included a test set consisting of a PDB file (3JD8.pdb) and the corresponding EM map (emd_6644.mrc), to easily test if Namdinator is working etc. 

----------------------------------
All the untested/work in progress versions are placed in their own folder, please dont use any of these as they have not been tested thoroughly. Only use the version that is placed in the main folder called Namdinator_current.sh.


Notes on some the untested versions can be found below, but it is not updated often:
Namdinator_paral.sh: A parallelized version of Namdinator_local.sh, which is much faster during the validation steps. This is basically a poor mans version of parallelization, as each step is just split into as many jobs as possible and then executed more less on the same time. But it works!

Namdinator_multiRun.sh: A modified version of the parallelized version, where two additonal rounds of NAMD and RSR is added, so the output files from the previous runs are run through NAMD+RSR and then repeated once more.  At the end all the output files are validated and compared to each other. This version could be very good for Namdiantor runs where an actual fitting is taking place.

Namdinator_multiRun_mc1.sh: same as the other version except it only does 1 macro cycle during each RSR run. Still testing this, but it seems to outperform the other version on speed and results.