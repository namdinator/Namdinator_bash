# Namdinator

Namdinator is a commandline tool, written in BASH, that sets up and runs a MDFF (molecular Dynamics Flexible Fit) simulation in a semi automatic manner, using only the input PDB file and input density file.

To run Namdinator you need the following programs installed:

VMD 1.93: http://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=VMD

NAMD 2.12 cuda version :http://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=NAMD

Phenix software package version 1.13rc1 (2954): https://www.phenix-online.org/download/

Rosetta modelleing software package (ver. 2016.32.58837): https://www.rosettacommons.org/software/license-and-download

NB. Namdinator needs all the input files to be in the same directory as the script is executede from.

Example on how to run Namdinator with default settings plus including a phenix.real_space_refine run:

./Namdinator_local.sh -p input.pdb -m map.mrc -r 3.5 -x

-p is the input PDB file (mandatory), -m is the input density in .mrc format (mandatory), -r is the resolution of the input density (mandatory) and -x is to turn on phenix.real.space refinement (Optional, but recommended).


----------------------------------
Currently I have 4 versions of Namdinator on my Github:

Namdinator_local.sh: The current local version of Namdinator for CSB, slow but reliable.

Namdinator_paral.sh: A parallelized version of Namdinator_local.sh, which is much faster during the validation steps. This is basically a poor mans version of parallelization, as each step is just split into as many jobs as possible and then executed more less on the same time. But it works!

Namdinator_multiRun.sh: A modified version of the parallelized version, where two more rounds of NAMD and RSR is added, so the output files from the previous runs are run through NAMD+RSR and then repeated once more.  At the end all the output files are validated and compared to each other. This version could be very good for Namdiantor runs where an actual fitting is taking place.

Namdinator_multiRun_mc1.sh: same as the other verion except it only does 1 macro cycle during each RSR run. Still testing this, but it seems to outperform the other version on speed and results.