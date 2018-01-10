# Namdinator

Namdinator is a commandline tool, written in BASH, that sets up and runs  a MDFF (molecular Dynamics Flexible Fit) simulation using the input PDB file and input density file.

To run Namdinator you need the following programs installed:

VMD 1.93: http://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=VMD

NAMD 2.12 cuda version :http://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=NAMD

Phenix software package version 1.13rc1 (2954): https://www.phenix-online.org/download/

Rosetta modelleing software package (ver. 2016.32.58837): https://www.rosettacommons.org/software/license-and-download

NB. Namdinator needs all the input files to be in the same directory as the script is executede from.

Example on how to run Namdinator with default settings and a phenix.real_space_refine run:

./Namdiantor_Rosetta_CSB.sh -p input.pdb -m map.mrc -r 3.5 -x

-p is the input PDB file (mandatory), -m is the input density in .mrc format (mandatory), -r is the resolution of the input density (mandatory) and -x is to turn on phenix.real.space refinement.

