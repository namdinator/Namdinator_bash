# Namdinator

You need the following programs installed:

VMD 1.93

NAMD 2.12 cuda version

Phenix package

Procheck

rosetta phenix 2016.32.58837 


To run Namdinator with default settings and a phenix.real_space_refine run:

./Namdiantor_Rosetta_CSB.sh -p input.pdb -m map.mrc -r 3.5 -x

-p is the input PDB file (mandatory), -m is the input density in .mrc format (mandatory), -r is the resolution of the input density (mandatory) and -x is to turn on phenix.real.space refinement.



