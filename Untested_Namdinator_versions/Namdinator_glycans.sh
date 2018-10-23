#!/bin/bash
# log to file
############################################################################
############################################################################
############## Namdinator Ver. 2.0 May  2018 by Rune Kidmose ###############
############################################################################
####### Namdinator is a Bash script for running an automatic MDFF ##########
####### (Molecular Dynamics Flexible Fitting) simulation from the ##########
####### commandline. Namdinator v 2.0 depends on VMD-1.93         ##########
####### (using charmm36), NAMD ver 2.12 (CUDA version), gnuplot,  ##########
####### rossetta and phenix package. /Ruki Email: rtk@mbg.au.dk   ##########
############################################################################
############################################################################
############################################################################
############################################################################
# To run Namdinator it is required to set the path for each of the programs
# listed below
############################################################################
module load vmd-1.93
module load namd-cuda-2.12
module load rosetta_mpi_2017.08.59291

############################################################################
# You can alter the below parameters for Namdinator in order to change the
# used default values. Each parameter can also be set with individual flags
# during initiation of each namdinator run, see help (-h) for morfe details.
############################################################################

GS=0.3

MC=5

NUMS=20000

ITEMP=300

FTEMP=300

EM=2000

PROCS="$(( $(lscpu | grep ^CPU\(s\)\: | awk '{print $2}') / $(lscpu | grep ^Thread | awk '{print $4}') ))"

BF=20


############################################################################
################DONT CHANGE ANYTHING BELOW THIS POINT!!!####################
############################################################################



############################################################################
######################### Loading the environments ######################### 
############################################################################

# check if vmd is in PATH and set VMDMASTERDIR
if [ "$(which vmd)" != "" ]; then
    if [ "${VMDMASTER}" = "" ]; then
	VMDMASTERDIR=$(grep "^set defaultvmddir" $(which vmd) | cut -d\= -f2- | sed 's/\"//g')
    else
	VMDMASTERDIR=${VMDMASTER}
    fi
else
    echo "No 'vmd' executable found in PATH"
    exit 1
fi

# Check if namd2 is in PATH and set NAMDMASTERDIR 
if [ "$(which namd2)" != "" ]; then
    if [ "${NAMDMASTER}" = "" ]; then
	NAMDMASTERDIR=$(which namd2 | rev| cut -d\/ -f2- |rev)
    else
	NAMDMASTERDIR=${NAMDMASTER}
	PATH=${NAMDMATERDIR}:${PATH}
    fi
else
    if [ "${NAMDMASTER}" = "" ]; then
	echo "No 'namd2' executable found in PATH"
        exit 1
    else
	NAMDMASTERDIR=${NAMDMASTER}
	PATH=${NAMDMATERDIR}:${PATH}
    fi
fi
if [ "$(which namd2)" = "" ]; then
    echo "No 'namd2' executable found in PATH"
    exit 1
fi

# Check if ROSETTA is in PATH and set ROSETTA_BINDIR
if [ "${ROSETTA_BIN}" != "" ]; then
    ROSETTA_BINDIR=${ROSETTA_BIN}
    PATH=${ROSETTA_BINDIR}:${PATH}
    ROSETTA_TAIL="$(ls -rt ${ROSETTA_BINDIR} | grep "score_jd2." | tail -n 1 | cut -d\. -f2- )"
fi

if [ "${PHENIX}" != "" ]; then
    if [ "${PHENIXMASTER}" = "" ]; then
	PHENIXMASTERDIR="${PHENIX}"
    else 
	PHENIXMASTERDIR="${PHENIXMASTER}"
    fi
 else
   PHENIXMASTERDIR="${PHENIXMASTER}"
fi
if [ "${PHENIXMASTERDIR}" != "" ]; then
    source ${PHENIXMASTERDIR}/phenix_env.sh
  else
    echo "No PHENIXMASTER Dir is set"
fi


LD_LIBRARY_PATH=${VMDMASTERDIR}:${LD_LIBRARY_PATH}



bold=$(tput bold)
normal=$(tput sgr0)

usage()
{
cat <<EOF
usage: $0 options
Namdinator sets up and runs a MDFF simulation using VMD and NAMD2. MDFF is basically a flexiable fittting of the input PDB file into the input density map, inside a molecular dynamics simulation using the density as a steering force for the fitting procedure.
To use Namdinator the minimum you  $bold have $normal to supply Namdinator with is: a standard formatted PDB file using the -p flag (e.g. -p fit.pdb), a density map file (mrc/map/ccp4 etc) using the -m flag (e.g. -m map.mrc) and the resolution of the input map in Å using the -r flag (e.g. -r 4.4). Optionally, but highly recommended, If you can add a default phenix.real space refinement step to the output PDB file from the MDFF simulation, using the -x flag (no value needed).
$normal.
Examples:
To run a minimal Namdinator run:
$bold
./Namdinator.sh -p input.pdb -m input.map -r 4.4
$normal
To run Namdinator with phenix.real_space refinement added:
$bold
./Namdinator.sh -p input.pdb -m input.map -r 4.4 -x
$normal
To read about Namdinator and all of the additional flags you can use to customize Namdinator further you simply have to type:
$bold
./Namdinator.sh -h
$normal
Instead of editing the Namdinator script, you can simply change many of the standard parameters directly from the commandline using the below flags.
      -h Help
      -p Input PDB file
      -m Input map file (.mrc/.ccp4/.map/.situs)
      -r Resolution of the input map. Used for only CCC calculations and for phenix.real space refinement (if applicable).
      -e Number of Minimization steps (default is 2000)
      -g G-scale value (default: 0.3): The force of which the density is able to pull the model with. Too high and you risk the simulations breaks due to too high velocity of some of the atoms. Typical values to test are between 0.01-10.
      -b B-factor value to be applied to all of the atoms in the output PDB file(s) (default: 20).
      -t Inital temperature (default: 300 kelvin): the temperature the simulation starts at. 
      -f final temperature (default: 300 kelvin) the target temp the simulation is either cooled or heated to during the simulation. If Initial and Final temp is identical no cooling or heating is performed.
      -s Number of steps the simulation runs (default 20000). Should be increased (typical values: 20000-500000) if large conformational changes are needed to fit a model, in order to enable the model to reach a convergence.
      -x When set performs a default phenix real space refinement run on the output PDB file(s) from the simulation. 
      -l If this flag is set, all HETATM in the input PDB file, will be not be removed and hence be included in the autoPSF step and, if autoPSF does not fail in the simulation as well. Does not work well with the -x flag!!!
      -n Number or processors used (default: number of processors on the workstation Namdinator is run from, divided by number of threads)
      -c Number or macro cycles to run during phenix.real_space refine (default is 5).
      -i If set the simulation will use implicit solvent (Generalized Born Implicit Solvent) instead of default vacuum. NB: MDFF GBIS is about seven times slower than in vacuo MDFF, but does yield better results (geometry of output models). 

****************************************************************************************************************************
All files produced by Namdinator pertaining to the actual simulation (and phenix real space refienemnt), are stored in the folder "data_files", whereas the log files and scripts produced by Namdinator are all stored in the folders "log_files" and "scripts" respectively.

****************************************************************************************************************************
Namdinator writes out the last frame from the calculated trajectory as a PDB file called last_frame.pdb. Hydrogens are removed from the PDB file and the file is converted back to standard PDB format.
The last_frame.pdb file is then used (if the -x flag is set) as input model for Phenix.real_space_refine, together with the input map. The output froom that is written as another PDB file named: last_frame_rsr.pdb.
last_frame.pdb and last_frame_rsr.pdb are then, together with the input PDB file, run through selected Phenix validations tools and rosetta score functions. A summary of the results from all three files is displayed in a table at the end of Namdinator for easy comparison. A separate table showing the top-10 highest (worst) scoring residues, based on the rosetta score function, is also listed at the end of the run.

****************************************************************************************************************************
To visualize the trajectory calculated during the simulation in VMD afterwards, Namdinator automatically creates a .tcl script$bold (visualize_trj.tcl)$normal which enables visualization of both the input map and the trajectory calculated by Namdinator.
To launch the script from the commandline, simply type:$bold vmd -dispdev win -e visualize_trj.tcl .$normal This will open VMD (if VMD is available) and initiate a looped playback of the trajectory, while enabling you to move around and inspect the model. As all maps are different, chances are very high that the picked default contour isovalue will not work at with your map, and will instead either show nothing or a very noisy map. As I have found no smart automatic way of setting a usefull contour level, you will have to change the isovalue manually in VMD. This is done by going to the "graphical representations" window that should open together with VMD after running the visualize_trj.tcl script. There you will have to alter the isovalue value until the map is contoured to your liking.

**************************************************************************************************************************** $bold
REMARK:$normal Default Namdinator settings will remove all HETATM records, as they generally tend to make the autoPSF step in MDFF fail and hence make Namdinator crash. This means that all non-ATOM records will be cropped from the PDB used for the simulation, and that the output files will not contain these atoms. The orginal input PDB file will of course remain intact.
The optimal choice of the scaling factor, i.e. the g-scale parameter, depends on the system to be fitted and the map. The higher the value, the stronger the forces acting on the system to fit the map, will be. In general a gscale of 0.3-0.6 works fine, however, too high g-scale values can make the simulation crash due to too high velocity of the atoms. If you, despite using a relativ low g-scale value, still experience to fast movement of the atoms you could try to increase the number of minimization steps to a higher value than the default 2000 by using the -e flag, though 2000 seems to work really well.

**************************************************************************************************************************** $bold
Tips for getting the most out of Namdinator $normal
If Namdinator fails with errors like “Bad global bond/angle/dihedral count” it is advisable to load the input PDB file (with HETATM removed manually) into VMD and run autopsf on it. If the resulting model displays any extraordinary long bonds, remove either of the involved residues from the PDB file and try again.

If the simulations crashes due to atoms moving too fast and increasing the minimization steps did not solve it, it is advisable to visually look at the involved atoms, as stated in the log file. It is important to know NAMD only outputs an atom number and that atom number does not correlate with the atom numbering in the input PDB file. Instead the atom number corresponds to atom numbering in the .psf file created by autoPSF. Within the .psf file the residue number and Chain ID belonging to the problematic atom(s), can be obtained, thus enabling visual inspection of the atoms in the input PDB file. Often it is obvious why these atoms are causing the simulation to crash and it is advisable to correct these residues manually or deleting them before trying again.

In general, it is always a good idea to run iterative rounds of Namdinator, where the output from one round is used as input for the next round. This have been shown to be good at catching models stuck in a small local minimum or tidy up more severe clashes. Varying the number of maco crycles (between 1 to 5) used for phenix real space refinement, has also been observed to give very different results. This can be down using the flag –c.
To focus a fitting procedure on a specific part of the map, segmentation of the input map can be a very powerful approach. This is especially useful for fitting individual domains from a multi domain model or to avoid the model going into density you know it does not belong in e.g. micelle density of membrane proteins etc. Furthermore, if the input map contains density for large glycosylation’s or large ligands, removing the corresponding density via segmentation could improve the obtained results, as HETATM’s are automatically removed from the input PDB file.

To obtain good results when trying to fit a model, where relative large conformational changes are needed, it can be very beneficial to use different filtered versions of the input map. The input map can be low-pass filtered to either 10, 15 or 20 Å using various EM software (EMAN, Relion, Chimera etc.) and then used as input for Namdinator. The resulting output model can then be used as input for another round of Namdinator against the original unfiltered map this time. For such scenarios it may be beneficial to run the first Namdinator run using a relative low G-scale value (-g 0.05-0.1) and high number of steps (-s 100.000-500.000) together with the low-passed filtered version of the map. Followed by the second Namdinator run where the g-scale is increased relative to the first round (0.5-5) for the original unfiltered map. To identify the correct combinations of the above-mentioned parameters several Namdinator runs are most likely needed.

MDFF in general is not very well suited for dealing with conformational changes where parts of the model undergo large rotations (=> 40-45 degrees). In such cases it is highly recommended that the input model is split into independent domains, if applicable, and rotated manually, in programs like Coot or Chimera. Then the domains can either be used as one single PDB file for a Namdinator run or run independent of each other in multiple Namdinator runs. This kind of manual intervention can not only greatly enhance the quality of the obtained results when using Namdinator but can also sometimes be the difference between failure or success.

If phenix.real_space_refine is enabled, via the -x flag, default settings are used. While this is sufficient and beneficial for many scenarios, it will not work well for all cases. For such cases it is advisable to run phenix.real_space_refine manually in order to utilize non-default settings. Make sure to use the last_frame.pdb file as input together with the input map and the stated resolution of the map. 

Lastly, please keep in mind that due to the stochastic nature of molecular dynamics simulations, it is expected that trajectories obtained from identical input files will differ slightly from each run.
Enjoy!

EOF
}

while getopts “hp:m:n:c:b:g:e:t:f:s:r:lxi” OPTION
do
    case $OPTION in
         h)
           usage
           exit 1
           ;;
        p)
            PDBIN=$OPTARG
            ;;
        m)
            MAPIN=$OPTARG
            ;;
        c)
            MC=$OPTARG
            ;;
        n)
            PROCS=$OPTARG
            ;;
	b)
            BF=$OPTARG
            ;;
	g)
            GS=$OPTARG
            ;;
	e)
            EM=$OPTARG
            ;;
 	t)
            ITEMP=$OPTARG
            ;;
 	f)
            FTEMP=$OPTARG
            ;;
        s)
            NUMS=$OPTARG
            ;;
        r)
            RES=$OPTARG
            ;;
        l)
            LIGANDS=1
            ;;
        x)
            PHENIXRS=1
            ;;
        i)
            IMPLICIT="-gbis"
            ;;
        ?)
             usage
             exit
             ;;
         *)
            if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
                echo "Non-option argument: '-${OPTARG}'" >&2
            fi
            ;;
    esac
done


if [[ "$PHENIXRS" = "1" ]] && [[ "${PHENIXMASTERDIR}" = "" ]] ; then

       echo "
Phenix real space refine was invoked using the -x flag, but it seems Phenix is either not installed or not installed correctly. 
"
       exit 1

fi


############################################################################
################# start log, timer and create directories ##################
############################################################################

LOGFILE=namdinator_stdout.log
exec > >(tee -a $LOGFILE)
exec 2>&1

export LC_NUMERIC="en_US.UTF-8"
trap "exit" INT TERM
trap "kill 0" EXIT
START_TIME=$SECONDS

DIREC1=data_files
DIREC2=log_files
DIREC3=scripts

mkdir -p $DIREC1
mkdir -p $DIREC2
mkdir -p $DIREC3

############################################################################
####################### Code for the Spinner animation######################
############################################################################
spinner()
{
    local pid=$1
    local delay=0.05
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}
############################################################################
#################### Variables and test of input files #####################
############################################################################

PDBPATH=$(echo "$PDBIN" | rev | cut -d\/ -f2- | rev | xargs -I "%" echo "%/")
PDBFILE=$(echo "$PDBIN" | rev | cut -d\/ -f1 | rev )
PDBNAME=$(echo "$PDBFILE"| rev | cut -d\. -f2- |rev )
PDBEXT=$(echo "$PDBFILE"| rev| cut -d\. -f1|rev )


MAPPATH=$(echo "$MAPIN" | rev | cut -d\/ -f2- | rev | xargs -I "%" echo "%/")
MAPFILE=$(echo "$MAPIN" | rev | cut -d\/ -f1 | rev )
MAPNAME=$(echo "$MAPFILE"| rev | cut -d\. -f2- |rev )
MAPEXT=$(echo "$MAPFILE"| rev| cut -d\. -f1|rev )

PDBCOUNTDOT=$(tr -dc '.' <<<"$PDBFILE" | awk '{print length}')
MAPCOUNTDOT=$(tr -dc '.' <<<"$MAPFILE" | awk '{print length}')

if [[ "$PDBCOUNTDOT" -gt 1 ]]  ||  [[ "$MAPCOUNTDOT" -gt 1 ]] ; then
   echo "
Namdinator does not support input files with multiple \".\" in them. Please rename input files so they only contain one \".\" per file
"
   exit 1
fi


if [ "$PDBIN" = "" ] && [ "$MAPIN" = "" ]; then
   echo "$normal
Namdinator sets up and runs a MDFF simulation using VMD and NAMD2. MDFF is basically a flexiable fittting of the input PDB file into the input density map, inside a molecular dynamics simulation using the density as a steering force for the fitting procedure.
To use Namdinator the minimum you  $bold have $normal to supply Namdinator with is: a standard formatted PDB file using the -p flag (e.g. -p fit.pdb), a density map file (mrc/map/ccp4 etc) using the -m flag (e.g. -m map.mrc) and the resolution of the input map in Å using the -r flag (e.g. -r 4.4). Optionally, but highly recommended, If you can add a default phenix.real space refinement step to the output PDB file from the MDFF simulation, using the -x flag (no value needed).
$normal.
Examples:
To run a minimal Namdinator run:
$bold
./Namdinator.sh -p input.pdb -m input.map -r 4.4
$normal
To run Namdinator with phenix.real_space refinement added:
$bold
./Namdinator.sh -p input.pdb -m input.map -r 4.4 -x
$normal
To read about Namdinator and all of the additional flags you can use to customize Namdinator further you simply have to type:
$bold
./Namdinator.sh -h
$normal
Instead of editing the Namdinator script, you can simply change many of the standard parameters directly from the commandline using the below flags.
      -h Help
      -p Input PDB file
      -m Input map file (.mrc/.ccp4/.map/.situs)
      -r Resolution of the input map. Used for only CCC calculations and for phenix.real space refinement (if applicable).
      -e Number of Minimization steps (default is 2000)
      -g G-scale value (default: 0.3): The force of which the density is able to pull the model with. Too high and you risk the simulations breaks due to too high velocity of some of the atoms. Typical values to test are between 0.01-10.
      -b B-factor value to be applied to all of the atoms in the output PDB file(s) (default: 20).
      -t Inital temperature (default: 300 kelvin): the temperature the simulation starts at. 
      -f final temperature (default: 300 kelvin) the target temp the simulation is either cooled or heated to during the simulation. If Initial and Final temp is identical no cooling or heating is performed.
      -s Number of steps the simulation runs (default 20000). Should be increased (typical values: 20000-500000) if large conformational changes are needed to fit a model, in order to enable the model to reach a convergence.
      -x When set performs a default phenix real space refinement run on the output PDB file(s) from the simulation. 
      -l If this flag is set, all HETATM in the input PDB file, will be not be removed and hence be included in the autoPSF step and, if autoPSF does not fail in the simulation as well. Does not work well with the -x flag!!!
      -n Number or processors used (default: number of processors on the workstation Namdinator is run from, divided by number of threads)
      -c Number or macro cycles to run during phenix.real_space refine (default is 5).
      -i If set the simulation will use implicit solvent (Generalized Born Implicit Solvent) instead of default vacuum. NB: MDFF GBIS is about seven times slower than in vacuo MDFF, but does yield better results (geometry of output models). 
"
sleep 0.3
   exit 1

elif [ "$PDBEXT" != "pdb" ]; then
 echo "You have to input a .pdb file!"
     exit 1

elif [ "$PDBIN" = "" ] && [ "$MAPIN" != "" ]; then
    echo "You must input a PDB file also!"
    exit 1

elif [ "$PDBIN" != "" ] && [ "$MAPIN" = "" ]; then
    echo "You must input a MAP file also!"
    exit 1

fi

if [ "$RES" = "" ]; then
    echo "You must input the resolution of the map, using the -r flag!"
    exit 1
fi


if [ "$PHENIXRS" = "1" ]; then

    if grep -q -E ^CRYST1 "$PDBIN"; then
	
    echo -n "
CRYST1 record identified in input PDB.
"
    PDB1="$PDBNAME"
  
    else

    echo -n "
NO CRYST1 record found in input PDB! Inserting default CRYST1 string to enable Phenix real space refine to run
"

    sed '1s/^/CRYST1    1.000   1.000    1.000  90.00  90.00  90.00 P 1           1\n/' $PDBIN > "$PDBNAME"_cryst.pdb

    PDB1="$PDBNAME"_cryst

    fi

else

    PDB1="$PDBNAME"    
fi

############################################################################
################# Testing if input map is in P1 spacegroup #################
############################################################################

test=$(phenix.show_map_info $MAPIN | grep "space group number:")

INPUT_SPG=$(echo $test | awk '{print $4}')

if [ "$INPUT_SPG" \> "1" ]; then
    echo 'Space group of '$MAPIN' is '${INPUT_SPG}', but must be 1 (P1)'
    exit 1
else
    echo 'Space group of '$MAPIN' is 1 (P1)'
fi     



############################################################################
################# Testing if all needed programs are installed #############
############################################################################

DIST="$(uname -a)"
echo -n "
System information: $DIST
"


echo -n '
Testing if all needed programs are installed

'

which vmd

if [ "$?" = "0" ] ; then
    echo -n 'VMD seems to be installed on this machine

'
else
    echo -n '
VMD is not installed on this machine
'
    exit 1
fi

which namd2

if [ "$?" = "0" ] ; then
    echo -n 'NAMD2 seems to be installed on this machine

'
else
    echo -n '
NAMD2 is not installed on this machine
'
    exit 1
fi


which phenix

if [ "$?" = "0" ] ; then
    echo -n 'PHENIX seems to be installed on this machine

'
else
    echo -n '
PHENIX is not installed on this machine
'
    exit 1
fi

############################################################################
############# Removing all non-ATOM records from input PDB #################
############################################################################

echo -n "Removing any CONECT/SHEET/HELIX records that may be present in $PDBFILE, as they can make Namdinator crash.
"

if [ "$LIGANDS" = "1" ]; then


    grep "HETATM\|^TER\|END\|^CRYST1\|^ATOM" $PDBIN > ${PDB1}_altered.pdb
    
 else

    grep "^TER\|END\|^CRYST1\|^ATOM" $PDBIN > ${PDB1}_altered.pdb
     
fi

sed -i 's/UNK/ALA/g' "$PDB1"_altered.pdb

PDB2="$PDB1"_altered

REST=""$PDB2"-extrabonds.txt "$PDB2"-extrabonds-cis.txt "$PDB2"-extrabonds-chi.txt"

#PARAMS=""${VMDMASTER}"/lib/plugins/noarch/tcl/readcharmmpar1.3/par_all36_lipid.prm "${VMDMASTER}"/lib/plugins/noarch/tcl/readcharmmpar1.3/par_all36_prot.prm "${VMDMASTER}"/lib/plugins/noarch/tcl/readcharmmpar1.3/par_all36_carb.prm "${VMDMASTER}"/lib/plugins/noarch/tcl/readcharmmpar1.3/toppar_water_ions_namd.str "${VMDMASTER}"/lib/plugins/noarch/tcl/readcharmmpar1.3/par_all36_cgenff.prm "${VMDMASTER}"/lib/plugins/noarch/tcl/readcharmmpar1.3/par_all36_na.prm"

PARAMS=""${VMDMASTERDIR}"/plugins/noarch/tcl/readcharmmpar1.3/par_all36_lipid.prm "${VMDMASTERDIR}"/plugins/noarch/tcl/readcharmmpar1.3/par_all36_prot.prm "${VMDMASTERDIR}"/plugins/noarch/tcl/readcharmmpar1.3/par_all36_carb.prm "${VMDMASTERDIR}"/plugins/noarch/tcl/readcharmmpar1.3/toppar_water_ions_namd.str "${VMDMASTERDIR}"/plugins/noarch/tcl/readcharmmpar1.3/par_all36_cgenff.prm "${VMDMASTERDIR}"/plugins/noarch/tcl/readcharmmpar1.3/par_all36_na.prm"

TOPO="/opt/bioxray/programs/vmd-1.93/lib/plugins/noarch/tcl/readcharmmtop1.2/top_all36_prot.rtf /opt/bioxray/programs/vmd-1.93/lib/plugins/noarch/tcl/readcharmmtop1.2/top_all36_lipid.rtf /opt/bioxray/programs/vmd-1.93/lib/plugins/noarch/tcl/readcharmmtop1.2/top_all36_na.rtf /opt/bioxray/programs/vmd-1.93/lib/plugins/noarch/tcl/readcharmmtop1.2/top_all36_cgenff.rtf /opt/bioxray/programs/vmd-1.93/lib/plugins/noarch/tcl/readcharmmtop1.2/toppar_all36_carb_glycopeptide.str /opt/bioxray/programs/vmd-1.93/lib/plugins/noarch/tcl/readcharmmtop1.2/toppar_water_ions_namd.str /home/rtk/namdinator/c4/top_all36_carb.rtf"
############################################################################
################# Generating NAMD files with MDFF setup#####################
############################################################################
echo -n "Running AutoPSF on "$PDB2".pdb
Generating the following restraint files for "$PDB2.pdb":
"$REST"
Generating simulation files for NAMD2
"
cat<<EOF > "MDFF_setup.tcl"
package require ssrestraints
package require mdff
package require autopsf
package require cispeptide
package require chirality
mol new $PDB2.pdb
autopsf -mol 0 -top {$TOPO}
cispeptide restrain -o $PDB2-extrabonds-cis.txt
chirality restrain -o $PDB2-extrabonds-chi.txt
ssrestraints -psf ${PDB2}_autopsf.psf -pdb ${PDB2}_autopsf.pdb -o ${PDB2}-extrabonds.txt -hbonds
mdff gridpdb -psf ${PDB2}_autopsf.psf -pdb ${PDB2}_autopsf.pdb -o ${PDB2}-grid.pdb
mdff griddx -i $MAPIN -o $MAPNAME-grid.dx
mdff setup -o simulation -psf ${PDB2}_autopsf.psf -pdb ${PDB2}_autopsf.pdb -griddx $MAPNAME-grid.dx -gridpdb $PDB2-grid.pdb -extrab {$REST} -parfiles {$PARAMS} -temp $ITEMP -ftemp $FTEMP -gscale $GS -numsteps $NUMS -minsteps $EM $IMPLICIT
EOF

vmd -dispdev text -eofexit <MDFF_setup.tcl> MDFF.log &
echo -n "PROCESSING..."

    spinner $!

cat MDFF.log

while [ ! -f simulation-step1.namd ] ; do

     sleep 1
done

############################################################################
##################Running MDFF generated files in NAMD #####################
############################################################################

echo -n "
Trying to module load the CUDA accelerated version of NAMD (namd-cuda-2.12).
"
    echo -n "Proceeding with running NAMD2
"
    namd2 +p"$PROCS" simulation-step1.namd | tee NAMD2_step1.log &

    echo -n "PROCESSING..."

    spinner $!

#    cat NAMD2_step1.log

############################################################################
############# Stop script from continuing if autoPSF fails #################
############################################################################

if [[ ! -f ${PDB2}_autopsf.psf ]] ; then
       echo -n "
The file "$PDB2"_autopsf.psf does not exsist!
"
       grep "Warning: This molecule contains" MDFF.log
       grep "Warning: I found some undefined atom types" MDFF.log

       echo -n "
Terminating Namdinator!
"
       exit 1
fi

############################################################################
############## Stop script from continuing if NAMD2 fails ##################
############################################################################

if grep -q 'ERROR: Exiting prematurely; see error messages above.' NAMD2_step1.log; then

    echo -n '
NAMD2 have unfortunately stopped prematurely, see the below Error message for further details or consult the NAMD2 log file:
'
    grep -B 4 'ERROR: Exiting prematurely; see error messages above.' NAMD2_step1.log;

    exit 1
fi

############################################################################
##################Creating a VMD visualizing .tcl scrip#####################
############################################################################
cat <<EOF > visualize_trj.tcl
color Display Background white
mol new $MAPIN
mol modcolor 0 top colorID 2
mol modstyle 0 top Isosurface 0.103826 0 0 1 1 1
mol new data_files/${PDB2}_autopsf.psf
mol addfile data_files/simulation-step1.dcd
mol modstyle 0 top NewCartoon
mol modcolor 0 top colorID 0
animate forward
animate style loop
menu graphics on
menu tkcon on
EOF

############################################################################
###########Export last frame out from the last trajectory as a PDB##########
############################################################################
cat<<EOF > writepdb.tcl
mol new ${PDB2}_autopsf.pdb
mol addfile ${PDB2}_autopsf.psf
mol addfile simulation-step1.coor
animate write pdb last_frame.pdb beg [expr [molinfo top get numframes] -1] end [expr [molinfo top get numframes] -1] skip 1 top
EOF

echo -n "
Writing last frame of trajectory to last_frame.pdb
"

if grep -F 'End of program' NAMD2_step1.log >/dev/null 2>&1 ; then

    vmd -dispdev text -eofexit <writepdb.tcl> writepdb.log

fi

############################################################################
####################Remove hydrogens from last frame PDB####################
############################################################################
echo -n '
Renaming all HSD/HSE/HSP residues in last_frame.pdb back to HIS, all CD ILE back to CD1 ILE and OT1/OT2 to O and OXT for terminal residues
'
sed -e 's/OT1/O  /g; s/OT2/OXT/g' last_frame.pdb > last_frame_OXT.pdb

while [ ! -f last_frame_OXT.pdb ] ; do

    sleep 1
done

sed -e 's/CD  ILE/CD1 ILE/g' last_frame_OXT.pdb > last_frame_ILE.pdb


while [ ! -f last_frame_ILE.pdb ] ; do

     sleep 1
done

sed -e 's/HSD/HIS/g; s/HSE/HIS/g; s/HSP/HIS/g' last_frame_ILE.pdb > last_frame_his.pdb


while [ ! -f last_frame_his.pdb ] ; do

     sleep 1
done

echo -n '
Applying the default or user input B-factor value to all atoms in last_frame.pdb
'

sed -e "s/\ [0,1]\.00\ \ 0.00\ /\ 1.00\ $BF\.00\ /g" last_frame_his.pdb > last_frame_bf.pdb


phenix.reduce -Trim last_frame_bf.pdb > last_frame_nohydro.pdb -Quiet

echo -n '
Removing hydrogens from last_frame.pdb using Phenix.Reduce
'
while [ ! -f last_frame_nohydro.pdb ] ; do

     sleep 1
done

echo -n '
Renaming all GUA/URA/ADE/CYT/THY nucleotides, if present, back to single letter identifiers to enable phenix.real_space_refine to run.
'
sed -e 's/URA/U  /g; s/GUA/G  /g; s/CYT/C  /g; s/ADE/A  /g; s/THY/T  /g' last_frame_nohydro.pdb > last_frame_nucleo.pdb


mv -f last_frame_nucleo.pdb last_frame.pdb

############################################################################
######################Phenix real space refinement #########################
############################################################################

if [ "$PHENIXRS" = "1" ]; then

cat <<EOF > phenix_rs.sh
phenix.real_space_refine last_frame.pdb $MAPIN resolution=$RES macro_cycles=$MC
EOF

sh phenix_rs.sh | tee phenix_rsr.log &

spinner $!

mv -f last_frame_real_space_refined.pdb last_frame_rsr.pdb

fi


############################################################################
################## Cross correlation coefficient check #####################
############################################################################

#phenix.reduce -Trim ${PDB2}_autopsf.pdb > trimmed.pdb -Quiet
#rm trimmmed.pdb

if [ "$PHENIXRS" = "1" ]; then

cat<<EOF > CC_map_files.sh

phenix.map_model_cc $PDB2.pdb $MAPIN resolution=$RES > CC_input.log
phenix.map_model_cc last_frame.pdb $MAPIN resolution=$RES > CC_lf.log
phenix.map_model_cc last_frame_rsr.pdb $MAPIN resolution=$RES > CC_rsr.log


EOF


echo -n "
Calculating Phenix CC values for the input PDB and output PDB files vs "$MAPNAME"."$MAPEXT"
"
sh CC_map_files.sh > cc_map_files.log &

spinner $!
    
cat<<EOF > CCC_check.tcl
package require mdff
package require multiplot
mol new ${PDB2}_autopsf.psf
mol addfile simulation-step1.dcd waitfor all
mdff check -ccc -map $MAPIN -res $RES waitfor -1 -cccfile ccc_frames.txt
multiplot reset
mol new ${PDB2}.pdb
mdff check -ccc -map $MAPIN -res $RES waitfor -1 -cccfile ccc_input.txt
multiplot reset
mol new last_frame.pdb
mdff check -ccc -map $MAPIN -res $RES waitfor -1 -cccfile ccc_lastframe.txt
mol new last_frame_rsr.pdb
mdff check -ccc -map $MAPIN -res $RES waitfor -1 -cccfile ccc_lastframe_rsr.txt
mol new ${PDB2}_autopsf.psf
mol addfile simulation-step1.dcd type dcd first 0 last -1 waitfor all top
set incre [ expr $NUMS/1000]
for {set i 0} {\$i < \$incre} {incr i 1} { 
         [atomselect top all frame \$i] writepdb frame\$i.pdb 
 } 
EOF

echo -n "
Calculating the CCC between the model from each frame of the trajectory simulation-step1.dcd and "$MAPFILE"
"

vmd -dispdev text -eofexit <CCC_check.tcl> CCC_check.log &

spinner $!


else

cat<<EOF > CC_map_files.sh

phenix.map_model_cc $PDB2.pdb $MAPIN resolution=$RES > CC_input.log
phenix.map_model_cc last_frame.pdb $MAPIN resolution=$RES > CC_lf.log

EOF


echo -n "
Calculating Phenix CC values for the input PDB and the output PDB file vs "$MAPNAME"."$MAPEXT"
"
sh CC_map_files.sh > cc_map_files.log &

spinner $!

    

cat<<EOF > CCC_check.tcl
package require mdff
package require multiplot
mol new ${PDB2}_autopsf.psf
mol addfile simulation-step1.dcd waitfor all
mdff check -ccc -map $MAPIN -res $RES waitfor -1 -cccfile ccc_frames.txt
multiplot reset
mol new ${PDB2}_autopsf.pdb
mdff check -ccc -map $MAPIN -res $RES waitfor -1 -cccfile ccc_input.txt
multiplot reset
mol new last_frame.pdb
mdff check -ccc -map $MAPIN -res $RES waitfor -1 -cccfile ccc_lastframe.txt
mol new ${PDB2}_autopsf.psf
mol addfile simulation-step1.dcd type dcd first 0 last -1 waitfor all top
set incre [ expr $NUMS/1000]
for {set i 0} {\$i < \$incre} {incr i 1} { 
         [atomselect top all frame \$i] writepdb frame\$i.pdb 
 } 
EOF

echo -n "
Calculating the CCC between the model from each frame of the trajectory simulation-step1.dcd and "$MAPFILE"
"

vmd -dispdev text -eofexit <CCC_check.tcl> CCC_check.log &

spinner $!
     
fi

############################################################################
###############Generating Gnuplots of CCC from all frames###################
############################################################################


cat<<EOF > gnuplot_dumb.sh
set terminal dumb 110 35
unset xtics
plot "ccc_frames.txt" using 1:2 w points pt "*" notitle
EOF


cat<<EOF > gnuplot_png.sh
set term png size 1400,800
set output "CCC_all_frames.png"
plot "ccc_frames.txt" using 1:2 with lines notitle
replot
EOF



############################################################################
###################### Clash score calculations ############################
############################################################################
cat<<EOF > clash_allframes.sh
#!/bin/bash
for i in \$(ls -1v frame*.pdb); do
    f=\$(echo \$i| cut -d\. -f1)
    
    sed -e "s/\ [0,1]\.00\ \ 0.00\ /\ 1.00\ 20\.00\ /g" \$i > \$f-bf.pdb
done
NUM=0
for i in \$(ls -1v frame*-bf.pdb); do
    NUM=\$(( \$NUM + 1 ))
    f=\$(echo \$i| cut -d\. -f1)
    while [ \$(pgrep -f clashscore.py | wc -l) -ge $PROCS ]; do
    sleep 1
    done
    phenix.clashscore \$i > \$f.log & pids[\${NUM}]=\$!
done
for pid in \${pids[*]}; do
    wait \$pid     
done
ls -1v frame*-bf.log | xargs -d '\n' grep "clashscore" | sed -e "s/:clashscore =//g" | sed -e 's/-bf.log/.pdb/g' > all_frames_clash.txt
EOF

chmod +x clash_allframes.sh
./clash_allframes.sh & PID[4]=$!

echo -n "
Calculating Clashscores for all individual frames from the trajectory
"

############################################################################
########## Generating Gnuplots of Clash scores from all frames #############
############################################################################
cat<<EOF > gnuplot_clash_dumb.sh
set terminal dumb 110 35
unset xtics 
plot "all_frames_clash.txt" using 2:xtic(1) w points pt "*" notitle
EOF


cat<<EOF > gnuplot_clash_png.sh
set autoscale
set term png
set xtics rotate
set output "clash_all_frames.png"
plot "all_frames_clash.txt" using 2:xtic(1) with lines notitle
replot
EOF


############################################################################
################ Calculatiing  number of cispeptide ########################
############################################################################

if [ "$PHENIXRS" = "1" ]; then

cat<<EOF > cispeptides.tcl
package require cispeptide
mol new ${PDB2}.pdb
set out1 [open ${PDB2}_cis.log w]
puts \$out1 [cispeptide check -mol top]
close \$out1
cispeptide reset
mol new last_frame.pdb
set out2 [open last_frame_cis.log w]
puts \$out2 [cispeptide check -mol top]
close \$out2
cispeptide reset
mol new last_frame_rsr.pdb
set out3 [open last_frame_rsr_cis.log w]
puts \$out3 [cispeptide check -mol top]
close \$out3
cispeptide reset
EOF

vmd -dispdev text eofexit<cispeptides.tcl> cispeptides.log & PID[7]=$!

echo -n "Identifying Cispeptides in input PDB file and output PDB files
"

 else
cat<<EOF > cispeptides.tcl
package require cispeptide
mol new ${PDB2}.pdb
set out1 [open ${PDB2}_cis.log w]
puts \$out1 [cispeptide check -mol top]
close \$out1
cispeptide reset
mol new last_frame.pdb
set out2 [open last_frame_cis.log w]
puts \$out2 [cispeptide check -mol top]
close \$out2
cispeptide reset
EOF

vmd -dispdev text eofexit<cispeptides.tcl> cispeptides.log & PID[7]=$!

echo -n "Identifying Cispeptides in input PDB file and output PDB file
"
   
 fi
 
############################################################################
##################### Validation checks of PDB files #######################
############################################################################
if [ "$PHENIXRS" = "1" ]; then

cat<<EOF > molpro.sh
phenix.ramalyze last_frame_rsr.pdb > rama_last_frame_rsr.log
phenix.rotalyze last_frame_rsr.pdb > rota_last_frame_rsr.log
phenix.cbetadev last_frame_rsr.pdb > cbeta_last_frame_rsr.log
phenix.clashscore last_frame_rsr.pdb > clash_last_frame_rsr.log
phenix.ramalyze last_frame.pdb > rama_last_frame.log
phenix.rotalyze last_frame.pdb > rota_last_frame.log
phenix.cbetadev last_frame.pdb > cbeta_last_frame.log
phenix.clashscore last_frame.pdb > clash_last_frame.log
phenix.ramalyze $PDB2.pdb > rama_$PDB2.log
phenix.rotalyze $PDB2.pdb > rota_$PDB2.log
phenix.cbetadev $PDB2.pdb > cbeta_$PDB2.log
phenix.clashscore $PDB2.pdb > clash_$PDB2.log
EOF

phenix.ramalyze last_frame_rsr.pdb > rama_last_frame_rsr.log & PID[8]=$!
phenix.rotalyze last_frame_rsr.pdb > rota_last_frame_rsr.log & PID[9]=$!
phenix.cbetadev last_frame_rsr.pdb > cbeta_last_frame_rsr.log & PID[10]=$!
phenix.clashscore last_frame_rsr.pdb > clash_last_frame_rsr.log & PID[11]=$!

phenix.ramalyze last_frame.pdb > rama_last_frame.log & PID[12]=$!
phenix.rotalyze last_frame.pdb > rota_last_frame.log & PID1[13]=$!
phenix.cbetadev last_frame.pdb > cbeta_last_frame.log & PID[14]=$!
phenix.clashscore last_frame.pdb > clash_last_frame.log & PID[15]=$!

phenix.ramalyze $PDB2.pdb > rama_$PDB2.log & PID[16]=$!
phenix.rotalyze $PDB2.pdb > rota_$PDB2.log & PID[17]=$!
phenix.cbetadev $PDB2.pdb > cbeta_$PDB2.log & PID[18]=$!
phenix.clashscore $PDB2.pdb > clash_$PDB2.log & PID[19]=$!

echo -n "
Running Molprobity valdations tools on input and output PDB files
"

 else

     cat<<EOF > molpro.sh
phenix.ramalyze last_frame.pdb > rama_last_frame.log
phenix.rotalyze last_frame.pdb > rota_last_frame.log
phenix.cbetadev last_frame.pdb > cbeta_last_frame.log
phenix.clashscore last_frame.pdb > clash_last_frame.log
phenix.ramalyze $PDB2.pdb > rama_$PDB2.log
phenix.rotalyze $PDB2.pdb > rota_$PDB2.log
phenix.cbetadev $PDB2.pdb > cbeta_$PDB2.log
phenix.clashscore $PDB2.pdb > clash_$PDB2.log
EOF

phenix.ramalyze last_frame.pdb > rama_last_frame.log & PID[12]=$!
phenix.rotalyze last_frame.pdb > rota_last_frame.log & PID[13]=$!
phenix.cbetadev last_frame.pdb > cbeta_last_frame.log & PID[14]=$!
phenix.clashscore last_frame.pdb > clash_last_frame.log & PID[15]=$!

phenix.ramalyze $PDB2.pdb > rama_$PDB2.log & PID[16]=$!
phenix.rotalyze $PDB2.pdb > rota_$PDB2.log & PID[17]=$!
phenix.cbetadev $PDB2.pdb > cbeta_$PDB2.log & PID[18]=$!
phenix.clashscore $PDB2.pdb > clash_$PDB2.log & PID[19]=$!

echo -n "
Running Molprobity valdations tools on input and output PDB files
"

 fi
 

############################################################################
###############Rosetta score for whole model against map ###################
############################################################################

if [[ "$PHENIXRS" = "1" ]] && [[ "${ROSETTA_BIN}" != "" ]] ; then

LIMHIGH=4.0
LIMLOW=3.5

RES1=$(echo "($RES*100)" |bc | cut -d\. -f1)
LIM1=$(echo "($LIMHIGH*100)" |bc | cut -d\. -f1)
LIM2=$(echo "($LIMLOW*100)" |bc | cut -d\. -f1)

elif [[ "$PHENIXRS" != "1" ]] && [[ "${ROSETTA_BIN}" != "" ]] ; then

LIMHIGH=4.0
LIMLOW=3.5

RES1=$(echo "($RES*100)" |bc | cut -d\. -f1)
LIM1=$(echo "($LIMHIGH*100)" |bc | cut -d\. -f1)
LIM2=$(echo "($LIMLOW*100)" |bc | cut -d\. -f1)

fi



if [[ "$PHENIXRS" = "1" ]] && [[ "${ROSETTA_BIN}" != "" ]] && [ "$RES1" -le  "$LIM1" ] && [ "$RES1" -ge "$LIM2" ]; then

cat<<EOF > rosetta.sh
score_jd2.${ROSETTA_TAIL} -in:file:s ${PDB2}.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:sliding_window_wt 2.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile ${PDB2}.sc > ${PDB2}_rosetta.log
score_jd2.${ROSETTA_TAIL} -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:sliding_window_wt 2.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log
score_jd2.${ROSETTA_TAIL} -in:file:s last_frame_rsr.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:sliding_window_wt 2.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf_rsr.sc > lf_rsr_rosetta.log
EOF

score_jd2.${ROSETTA_TAIL} -in:file:s ${PDB2}.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:sliding_window_wt 2.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile ${PDB2}.sc > ${PDB2}_rosetta.log & PID[20]=$!

score_jd2.${ROSETTA_TAIL} -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:sliding_window_wt 2.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log & PID[21]=$!

score_jd2.${ROSETTA_TAIL} -in:file:s last_frame_rsr.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:sliding_window_wt 2.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf_rsr.sc > lf_rsr_rosetta.log & PID[22]=$!


echo -n "
Calculating Rosetta scores for input and output PDB files. The lower the score, the more stable the structure is likely to be for a given protein.
"

elif [[ "$PHENIXRS" = "1" ]] && [[ "${ROSETTA_BIN}" != "" ]] && [ "$RES1" -lt "$LIM2" ]; then

cat<<EOF > rosetta.sh
score_jd2.${ROSETTA_TAIL} -in:file:s ${PDB2}.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:sliding_window_wt 4.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile ${PDB2}.sc > ${PDB2}_rosetta.log
score_jd2.${ROSETTA_TAIL} -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:sliding_window_wt 4.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log
score_jd2.${ROSETTA_TAIL} -in:file:s last_frame_rsr.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:sliding_window_wt 4.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf_rsr.sc > lf_rsr_rosetta.log
EOF

score_jd2.${ROSETTA_TAIL} -in:file:s ${PDB2}.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:sliding_window_wt 4.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile ${PDB2}.sc > ${PDB2}_rosetta.log & PID[20]=$!

score_jd2.${ROSETTA_TAIL} -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:sliding_window_wt 4.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log & PID[21]=$!

score_jd2.${ROSETTA_TAIL} -in:file:s last_frame_rsr.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:sliding_window_wt 4.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf_rsr.sc > lf_rsr_rosetta.log & PID[22]=$!

echo -n "
Calculating Rosetta scores for input and output PDB files. The lower the score, the more stable the structure is likely to be for a given protein.
"
elif [[ "$PHENIXRS" = "1" ]] && [[ "${ROSETTA_BIN}" != "" ]] && [ "$RES1" -gt  "$LIM1" ]; then

    cat<<EOF > rosetta.sh
score_jd2.${ROSETTA_TAIL} -in:file:s ${PDB2}.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile ${PDB2}.sc > ${PDB2}_rosetta.log
score_jd2.${ROSETTA_TAIL} -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log
score_jd2.${ROSETTA_TAIL} -in:file:s last_frame_rsr.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf_rsr.sc > lf_rsr_rosetta.log
EOF

score_jd2.${ROSETTA_TAIL} -in:file:s ${PDB2}.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile ${PDB2}.sc > ${PDB2}_rosetta.log & PID[20]=$!

score_jd2.${ROSETTA_TAIL} -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log & PID[21]=$!

score_jd2.${ROSETTA_TAIL} -in:file:s last_frame_rsr.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf_rsr.sc > lf_rsr_rosetta.log & PID[22]=$!


echo -n "
Calculating Rosetta scores for input and output PDB files. The lower the score, the more stable the structure is likely to be for a given protein.
"
fi


if [[ "$PHENIXRS" != "1" ]] && [[ "${ROSETTA_BIN}" != "" ]] && [ "$RES1" -le  "$LIM1" ] && [ "$RES1" -ge "$LIM2" ]; then

cat<<EOF > rosetta.sh
score_jd2.${ROSETTA_TAIL} -in:file:s ${PDB2}.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:sliding_window_wt 2.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile ${PDB2}.sc > ${PDB2}_rosetta.log
score_jd2.${ROSETTA_TAIL} -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:sliding_window_wt 2.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log
EOF

score_jd2.${ROSETTA_TAIL} -in:file:s ${PDB2}.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:sliding_window_wt 2.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile ${PDB2}.sc > ${PDB2}_rosetta.log & PID[20]=$!

score_jd2.${ROSETTA_TAIL} -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:sliding_window_wt 2.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log & PID[21]=$!


echo -n "
Calculating Rosetta scores for input and output PDB files. The lower the score, the more stable the structure is likely to be for a given protein.
"


elif [[ "$PHENIXRS" != "1" ]] && [[ "${ROSETTA_BIN}" != "" ]] && [ "$RES1" -lt "$LIM2" ]; then

cat<<EOF > rosetta.sh
score_jd2.${ROSETTA_TAIL} -in:file:s ${PDB2}.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:sliding_window_wt 4.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile ${PDB2}.sc > ${PDB2}_rosetta.log
score_jd2.${ROSETTA_TAIL} -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:sliding_window_wt 4.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log
EOF

score_jd2.${ROSETTA_TAIL} -in:file:s ${PDB2}.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:sliding_window_wt 4.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile ${PDB2}.sc > ${PDB2}_rosetta.log & PID[20]=$!

score_jd2.${ROSETTA_TAIL} -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:sliding_window_wt 4.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log & PID[21]=$!


echo -n "
Calculating Rosetta scores for input and output PDB files. The lower the score, the more stable the structure is likely to be for a given protein.
"

elif [[ "$PHENIXRS" != "1" ]] && [[ "${ROSETTA_BIN}" != "" ]] && [ "$RES1" -gt  "$LIM1" ]; then

    cat<<EOF > rosetta.sh
score_jd2.${ROSETTA_TAIL} -in:file:s ${PDB2}.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile ${PDB2}.sc > ${PDB2}_rosetta.log
score_jd2.${ROSETTA_TAIL} -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log
EOF

score_jd2.${ROSETTA_TAIL} -in:file:s ${PDB2}.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile ${PDB2}.sc > ${PDB2}_rosetta.log & PID[20]=$!

score_jd2.${ROSETTA_TAIL} -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile ${MAPIN} -edensity::mapreso ${RES} -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log & PID[21]=$!


echo -n "
Calculating Rosetta scores for input and output PDB files. The lower the score, the more stable the structure is likely to be for a given protein.
"

fi
 
############################################################################
###############Rosetta score for individual residues #######################
############################################################################


if [[ "$PHENIXRS" = "1" ]] && [[ "${ROSETTA_BIN}" != "" ]] ; then
 
cat<<EOF > rosetta_resi.sh
per_residue_energies.${ROSETTA_TAIL} -in:file:s ${PDB2}.pdb -ignore_unrecognized_res > ${PDB2}_perRes.log
sort -k21 -n -r default.out > ${PDB2}_perRes.sc
rm default.out
per_residue_energies.${ROSETTA_TAIL} -in:file:s last_frame.pdb -ignore_unrecognized_res > lf_perRes.log
sort -k21 -n -r default.out > lf_perRes.sc
rm default.out
per_residue_energies.${ROSETTA_TAIL} -in:file:s last_frame_rsr.pdb -ignore_unrecognized_res > lf_rsr_perRes.log 
sort -k21 -n -r default.out > lf_rsr_perRes.sc
rm default.out
EOF

per_residue_energies.${ROSETTA_TAIL} -in:file:s ${PDB2}.pdb -out:file:silent ${PDB2}.out -ignore_unrecognized_res > ${PDB2}_perRes.log & PID[23]=$!

per_residue_energies.${ROSETTA_TAIL} -in:file:s last_frame.pdb -out:file:silent lf.out -ignore_unrecognized_res > lf_perRes.log & PID[24]=$!

per_residue_energies.${ROSETTA_TAIL} -in:file:s last_frame_rsr.pdb -out:file:silent lfr.out -ignore_unrecognized_res > lf_rsr_perRes.log & PID[25]=$! 


echo -n "
Calculating Rosetta scores for individual residues in input and output PDB files. Single residues that scores significantly higher could indicate they are involved in clashes.
"

elif [[ "$PHENIXRS" != "1" ]] && [[ "${ROSETTA_BIN}" != "" ]] ; then
cat<<EOF > rosetta_resi.sh
per_residue_energies.${ROSETTA_TAIL} -in:file:s ${PDB2}.pdb -ignore_unrecognized_res > ${PDB2}_perRes.log
sort -k21 -n -r default.out > ${PDB2}_perRes.sc
rm default.out
per_residue_energies.${ROSETTA_TAIL} -in:file:s last_frame.pdb -ignore_unrecognized_res > lf_perRes.log
sort -k21 -n -r default.out > lf_perRes.sc
rm default.out
EOF

per_residue_energies.${ROSETTA_TAIL} -in:file:s ${PDB2}.pdb -out:file:silent ${PDB2}.out -ignore_unrecognized_res > ${PDB2}_perRes.log & PID[23]=$!

per_residue_energies.${ROSETTA_TAIL} -in:file:s last_frame.pdb -out:file:silent lf.out -ignore_unrecognized_res > lf_perRes.log & PID[24]=$!


echo -n "
Calculating Rosetta scores for individual residues in input and output PDB files. Single residues that scores significantly higher could indicate they are involved in clashes.
"
fi
############################################################################
######################## wait for all PIDS to finish #######################
############################################################################

for PIDS in ${PID[*]};do
     #echo "check wait on $(ps -p $PIDS -o comm=)"
     while lsof -p $PIDS > /dev/null 2>&1; do
	 spinner $!
        #echo "wating on $(ps -p $PIDS -o comm=) to finish"
     done
done

############################################################################
#############Creating plots of CCC and Clash from all frames################
############################################################################

echo -n '
Plotting the CCC for every frame of the trajectory simulation-step1.dcd'

cat ccc_frames.txt | gnuplot gnuplot_dumb.sh

echo -n '
Writing a prettified version of the above plot as a PNG (CCC_all_frames.png).
'
cat ccc_frames.txt | gnuplot gnuplot_png.sh


echo -n '
Plotting the Clashscores for every '$NUMS'/1000 frame of the trajectory simulation-step1.dcd'
cat all_frames_clash.txt | gnuplot gnuplot_clash_dumb.sh


echo -n '
Writing a prettified version of the above plot as a PNG (clash_all_frames.png).
'
cat all_frames_clash.txt | gnuplot gnuplot_clash_png.sh

############################################################################
################ extracting Per Residue Rosetta Scores #####################
############################################################################

if [[ "$PHENIXRS" = "1" ]] && [[ "${ROSETTA_BIN}" != "" ]] ; then
        
    awk '{print $3, $(NF-1)}' ${PDB2}.out | sort -nr -k2 > ${PDB2}_perRes.sc
    awk '{print $3, $(NF-1)}' lf.out | sort -nr -k2 > lf_perRes.sc
    awk '{print $3, $(NF-1)}' lfr.out | sort -nr -k2  > lf_rsr_perRes.sc
    rm ${PDB2}.out
    rm lf.out
    rm lfr.out
    awk 'NR<=10' ${PDB2}_perRes.sc | awk '{print $1, $2}' > pr.sc
    awk 'NR<=10' lf_perRes.sc | awk '{print $1, $2}' > pr2.sc
    awk 'NR<=10' lf_rsr_perRes.sc | awk '{print $1, $2}' > pr3.sc


elif [[ "$PHENIXRS" != "1" ]] && [[ "${ROSETTA_BIN}" != "" ]] ; then 

    awk '{print $3, $(NF-1)}' ${PDB2}.out | sort -nr -k2 > ${PDB2}_perRes.sc
    awk '{print $3, $(NF-1)}' lf.out | sort -nr -k2 > lf_perRes.sc
    rm ${PDB2}.out
    rm lf.out
    awk 'NR<=10' ${PDB2}_perRes.sc | awk '{print $1, $2}' > pr.sc
    awk 'NR<=10' lf_perRes.sc | awk '{print $1, $2}' > pr2.sc

fi


############################################################################
###############Displaying all the validation metrics #######################
############################################################################

if [[ "$PHENIXRS" = "1" ]] && [[ "${ROSETTA_BIN}" != "" ]] ; then


PCCC1=$(grep "masked):" CC_input.log | awk '{print $4}')
PCCC2=$(grep "masked):" CC_lf.log | awk '{print $4}')    
PCCC3=$(grep "masked):" CC_rsr.log | awk '{print $4}')
    
CCC1=$(awk '{print $2}' ccc_input.txt)
CCC2=$(awk '{print $2}' ccc_lastframe.txt)
CCC3=$(awk '{print $2}' ccc_lastframe_rsr.txt)
     
claINP=$(awk 'END {print $NF}' clash_"$PDB2".log)
claLF=$(awk 'END {print $NF}' clash_last_frame.log)
claLFR=$(awk 'END {print $NF}' clash_last_frame_rsr.log)

FAVINP=$(grep SUMMARY rama_"$PDB2".log | awk '{print $2}' | head -n1)
FAVLF=$(grep SUMMARY rama_last_frame.log | awk '{print $2}' | head -n1)
FAVLFR=$(grep SUMMARY rama_last_frame_rsr.log | awk '{print $2}' | head -n1)

ALWINP=$(grep SUMMARY rama_"$PDB2".log | awk '{print $4}' | head -n1)
ALWLF=$(grep SUMMARY rama_last_frame.log | awk '{print $4}' | head -n1)
ALWLFR=$(grep SUMMARY rama_last_frame_rsr.log | awk '{print $4}' | head -n1)

OUTINP=$(grep SUMMARY rama_"$PDB2".log | awk '{print $6}' | head -n1)
OUTLF=$(grep SUMMARY rama_last_frame.log | awk '{print $6}' | head -n1)
OUTLFR=$(grep SUMMARY rama_last_frame_rsr.log | awk '{print $6}' | head -n1)

CBEINP=$(grep "SUMMARY" cbeta_"$PDB2".log | awk '{print $2}')
CBELF=$(grep "SUMMARY" cbeta_last_frame.log | awk '{print $2}')
CBELFR=$(grep "SUMMARY" cbeta_last_frame_rsr.log | awk '{print $2}')

ROTINP=$(grep "SUMMARY" rota_"$PDB2".log | awk '{print $2}')
ROTLF=$(grep "SUMMARY" rota_last_frame.log | awk '{print $2}')
ROTLFR=$(grep "SUMMARY" rota_last_frame_rsr.log | awk '{print $2}')

CISINP=$(awk '{print $1}' ${PDB2}_cis.log)
CISLF=$(awk '{print $1}' last_frame_cis.log)
CISLFR=$(awk '{print $1}' last_frame_rsr_cis.log)

ROSINP=$(awk 'NR==3' ${PDB2}.sc | awk '{print $2}')
ROSLF=$(awk 'NR==3' lf.sc | awk '{print $2}')
ROSLFR=$(awk 'NR==3' lf_rsr.sc | awk '{print $2}')


INP=INP
LF=LF
LFR=LFR

elif [[ "$PHENIXRS" != "1" ]] && [[ "${ROSETTA_BIN}" != "" ]] ; then 


PCCC1=$(grep "masked):" CC_input.log | awk '{print $4}')
PCCC2=$(grep "masked):" CC_lf.log | awk '{print $4}')    
PCCC3="n/a"

CCC1=$(awk '{print $2}' ccc_input.txt)
CCC2=$(awk '{print $2}' ccc_lastframe.txt)
CCC3="n/a"
     
claINP=$(awk 'END {print $NF}' clash_"$PDB2".log)
claLF=$(awk 'END {print $NF}' clash_last_frame.log)
claLFR="n/a"

FAVINP=$(grep SUMMARY rama_"$PDB2".log | awk '{print $2}' | head -n1)
FAVLF=$(grep SUMMARY rama_last_frame.log | awk '{print $2}' | head -n1)
FAVLFR="n/a"

ALWINP=$(grep SUMMARY rama_"$PDB2".log | awk '{print $4}' | head -n1)
ALWLF=$(grep SUMMARY rama_last_frame.log | awk '{print $4}' | head -n1)
ALWLFR="n/a"

OUTINP=$(grep SUMMARY rama_"$PDB2".log | awk '{print $6}' | head -n1)
OUTLF=$(grep SUMMARY rama_last_frame.log | awk '{print $6}' | head -n1)
OUTLFR="n/a"

CBEINP=$(grep "SUMMARY" cbeta_"$PDB2".log | awk '{print $2}')
CBELF=$(grep "SUMMARY" cbeta_last_frame.log | awk '{print $2}')
CBELFR="n/a"

ROTINP=$(grep "SUMMARY" rota_"$PDB2".log | awk '{print $2}')
ROTLF=$(grep "SUMMARY" rota_last_frame.log | awk '{print $2}')
ROTLFR="n/a"

CISINP=$(awk '{print $1}' ${PDB2}_cis.log)
CISLF=$(awk '{print $1}' last_frame_cis.log)
CISLFR="n/a"

ROSINP=$(awk 'NR==3' ${PDB2}.sc | awk '{print $2}')
ROSLF=$(awk 'NR==3' lf.sc | awk '{print $2}')
ROSLFR="n/a"

INP=INP
LF=LF
LFR=LFR

elif [[ "$PHENIXRS" = "1" ]] && [[ "${ROSETTA_BIN}" = "" ]] ; then

PCCC1=$(grep "CC_volume" CC_input.log | awk '{print $2}')
PCCC2=$(grep "CC_volume" CC_lf.log | awk '{print $2}')    
PCCC3=$(grep "CC_volume" CC_rsr.log | awk '{print $2}')

CCC1=$(awk '{print $2}' ccc_input.txt)
CCC2=$(awk '{print $2}' ccc_lastframe.txt)
CCC3=$(awk '{print $2}' ccc_lastframe_rsr.txt)
     
claINP=$(awk 'END {print $NF}' clash_"$PDB2".log)
claLF=$(awk 'END {print $NF}' clash_last_frame.log)
claLFR=$(awk 'END {print $NF}' clash_last_frame_rsr.log)

FAVINP=$(grep SUMMARY rama_"$PDB2".log | awk '{print $2}' | head -n1)
FAVLF=$(grep SUMMARY rama_last_frame.log | awk '{print $2}' | head -n1)
FAVLFR=$(grep SUMMARY rama_last_frame_rsr.log | awk '{print $2}' | head -n1)

ALWINP=$(grep SUMMARY rama_"$PDB2".log | awk '{print $4}' | head -n1)
ALWLF=$(grep SUMMARY rama_last_frame.log | awk '{print $4}' | head -n1)
ALWLFR=$(grep SUMMARY rama_last_frame_rsr.log | awk '{print $4}' | head -n1)

OUTINP=$(grep SUMMARY rama_"$PDB2".log | awk '{print $6}' | head -n1)
OUTLF=$(grep SUMMARY rama_last_frame.log | awk '{print $6}' | head -n1)
OUTLFR=$(grep SUMMARY rama_last_frame_rsr.log | awk '{print $6}' | head -n1)

CBEINP=$(grep "SUMMARY" cbeta_"$PDB2".log | awk '{print $2}')
CBELF=$(grep "SUMMARY" cbeta_last_frame.log | awk '{print $2}')
CBELFR=$(grep "SUMMARY" cbeta_last_frame_rsr.log | awk '{print $2}')

ROTINP=$(grep "SUMMARY" rota_"$PDB2".log | awk '{print $2}')
ROTLF=$(grep "SUMMARY" rota_last_frame.log | awk '{print $2}')
ROTLFR=$(grep "SUMMARY" rota_last_frame_rsr.log | awk '{print $2}')

CISINP=$(awk '{print $1}' ${PDB2}_cis.log)
CISLF=$(awk '{print $1}' last_frame_cis.log)
CISLFR=$(awk '{print $1}' last_frame_rsr_cis.log)

INP=INP
LF=LF
LFR=LFR
  
    
elif [[ "$PHENIXRS" != "1" ]] && [[ "${ROSETTA_BIN}" = "" ]] ; then 

PCCC1=$(grep "CC_volume" CC_input.log | awk '{print $2}')
PCCC2=$(grep "CC_volume" CC_lf.log | awk '{print $2}')    
PCCC3="n/a"
    
CCC1=$(awk '{print $2}' ccc_input.txt)
CCC2=$(awk '{print $2}' ccc_lastframe.txt)
CCC3="n/a"
     
claINP=$(awk 'END {print $NF}' clash_"$PDB2".log)
claLF=$(awk 'END {print $NF}' clash_last_frame.log)
claLFR="n/a"

FAVINP=$(grep SUMMARY rama_"$PDB2".log | awk '{print $2}' | head -n1)
FAVLF=$(grep SUMMARY rama_last_frame.log | awk '{print $2}' | head -n1)
FAVLFR="n/a"

ALWINP=$(grep SUMMARY rama_"$PDB2".log | awk '{print $4}' | head -n1)
ALWLF=$(grep SUMMARY rama_last_frame.log | awk '{print $4}' | head -n1)
ALWLFR="n/a"

OUTINP=$(grep SUMMARY rama_"$PDB2".log | awk '{print $6}' | head -n1)
OUTLF=$(grep SUMMARY rama_last_frame.log | awk '{print $6}' | head -n1)
OUTLFR="n/a"

CBEINP=$(grep "SUMMARY" cbeta_"$PDB2".log | awk '{print $2}')
CBELF=$(grep "SUMMARY" cbeta_last_frame.log | awk '{print $2}')
CBELFR="n/a"

ROTINP=$(grep "SUMMARY" rota_"$PDB2".log | awk '{print $2}')
ROTLF=$(grep "SUMMARY" rota_last_frame.log | awk '{print $2}')
ROTLFR="n/a"

CISINP=$(awk '{print $1}' ${PDB2}_cis.log)
CISLF=$(awk '{print $1}' last_frame_cis.log)
CISLFR="n/a"

INP=INP
LF=LF
LFR=LFR

fi


if [[ "$PHENIXRS" != "1" ]] && [[ "${ROSETTA_BIN}" = "" ]] ; then

ROSINP="n/a"
ROSLF="n/a"

elif [[ "$PHENIXRS" = "1" ]] && [[ "${ROSETTA_BIN}" = "" ]] ; then 

ROSINP="n/a"
ROSLF="n/a"
ROSLFR="n/a"

fi

echo -n '
'$bold'
To visualize the simulation in VMD simply copy/paste this command: vmd -dispdev win -e scripts/visualize_trj.tcl '$normal'
'
echo -n "
Legend to the below table:
INP = "$PDBIN" > This is the input PDB file.
LF = last_frame.pdb > This is the output PDB file from the MD simulation (last frame of the trajectory).
LFR = last_frame_rsr.pdb > Output PDB file from the Phenix real space refinement run on last_frame.pdb.
CCC = Cross correlation coefficient between "$MAPFILE" and either of the above PDB files.
"

echo ""
printf "+---------------------------------------------------------+\n"
printf "|                  | %10s | %10s | %10s |          \n" $INP $LF $LFR
printf "+---------------------------------------------------------+\n"
printf "|  Clashscore:     | %10s | %10s | %10s |          \n" $claINP $claLF $claLFR
printf "|  Favored:        | %10s | %10s | %10s |          \n" $FAVINP $FAVLF $FAVLFR
printf "|  Allowed :       | %10s | %10s | %10s |          \n" $ALWINP $ALWLF $ALWLFR
printf "|  Outliers:       | %10s | %10s | %10s |          \n" $OUTINP $OUTLF $OUTLFR
printf "|  C-beta dev:     | %10s | %10s | %10s |          \n" $CBEINP $CBELF $CBELFR
printf "|  Rota-outliers:  | %10s | %10s | %10s |          \n" $ROTINP $ROTLF $ROTLFR
printf "|  VMD CCC:        | %10s | %10s | %10s |          \n" ${CCC1:0:7} ${CCC2:0:7} ${CCC3:0:7}
printf "|  Phenix FSC:     | %10s | %10s | %10s |          \n" ${PCCC1:0:7} ${PCCC2:0:7} ${PCCC3:0:7}
printf "|  Cis-Peptides:   | %10s | %10s | %10s |          \n" $CISINP $CISLF $CISLFR
printf "|  Rosetta score:  | %10s | %10s | %10s |          \n" ${ROSINP:0:7} ${ROSLF:0:7} ${ROSLFR:0:7}
printf "+---------------------------------------------------------+\n"
echo ""

if [ -f lf_perRes.log ] ; then
    
    SCORFUNC="$(grep -o -P '.{0,0}SCOREFUNCTION.{0,20}' lf_perRes.log)"

fi

if [[ "$PHENIXRS" = "1" ]] && [[ "${ROSETTA_BIN}" != "" ]] ; then

    pr -mts pr.sc pr2.sc pr3.sc > perRes_scores_all.sc

    sed -i '1s/^/ Resid_Inp Score_Inp Resid_LF Score_LF Resid_LFR Score_LFR\n/' perRes_scores_all.sc
    echo -n "Displaying the top 10 Rosetta scoring residues from each PDB file. Significantly higher score values for an indivdual residue may indicate it is involved in a clash:                                                                                                   

"
    column -t perRes_scores_all.sc

      echo -n "
Calculated using the $SCORFUNC
"

  
elif [[ "$PHENIXRS" != "1" ]] && [[ "${ROSETTA_BIN}" != "" ]] ; then

    pr -mts pr.sc pr2.sc > perRes_scores_all.sc

    sed -i '1s/^/ Resid_inp Score_inp Resid_LF Score_LF\n/' perRes_scores_all.sc
    echo -n "Displaying the top 10 Rosetta scoring residues from each PDB file. Significantly higher score values for an indivdual residue may indicate it is involved in a clash:                                                                                                   

"
    column -t perRes_scores_all.sc

      echo -n "
Calculated using the $SCORFUNC
"
fi


############################################################################
########################Light Clean up/organization#########################
############################################################################

cat<<EOF > cleanup.sh
mv *.pkl $DIREC2/ 2> /dev/null
mv *.csv $DIREC2/ 2> /dev/null
mv *_plots $DIREC2/ 2> /dev/null
mv simulation-step* $DIREC1/ 2> /dev/null
mv mdff_template.namd $DIREC1/ 2> /dev/null
mv $PDB2-extrabonds-cis.txt $DIREC1/ 2> /dev/null
mv $PDB2-extrabonds-chi.txt $DIREC1/ 2> /dev/null
mv $PDB2-extrabonds.txt $DIREC1/ 2> /dev/null
mv $PDB2.pdb $DIREC1/ 2> /dev/null
mv "$PDBNAME"_cryst.pdb $DIREC1/ 2> /dev/null
mv ${PDB2}_autopsf*.* $DIREC1/ 2> /dev/null
mv $PDB2-grid.pdb $DIREC1/ 2> /dev/null
mv $MAPNAME-grid.dx $DIREC1/ 2> /dev/null
mv *.log $DIREC2/ 2> /dev/null
mv *.tcl $DIREC3/ 2> /dev/null
mv molpro.sh $DIREC3/ 2> /dev/null
mv last_frame_ILE.pdb $DIREC1/ 2> /dev/null
mv last_frame_his.pdb $DIREC1/ 2> /dev/null
mv last_frame_OXT.pdb $DIREC1/ 2> /dev/null
mv last_frame_bf.pdb $DIREC1/ 2> /dev/null
mv last_frame_nohydro.pdb $DIREC1/ 2> /dev/null
mv frame*.pdb $DIREC1/ 2> /dev/null
mv clash_allframes.sh $DIREC3/ 2> /dev/null
mv cleanup.sh $DIREC3/ 2> /dev/null
mv *.png $DIREC2/ 2> /dev/null
mv last_frame_real_space_refined_all_states.pdb $DIREC1/ 2> /dev/null
mv ccc_*.txt $DIREC1/ 2> /dev/null
mv all_frames_clash.txt $DIREC1/ 2> /dev/null
mv gnuplot*.sh $DIREC3/ 2> /dev/null
mv phenix_rs.sh $DIREC3/ 2> /dev/null
mv rosetta.sh $DIREC3/ 2> /dev/null
mv rosetta_resi.sh $DIREC3/ 2> /dev/null
mv sort_perResi_Score.sh $DIREC3/ 2> /dev/null
mv *.sc $DIREC2/ 2> /dev/null
mv *.geo $DIREC2/ 2> /dev/null
mv $DIREC2/namdinator_stdout.log . 2> /dev/null
mv CC_map_files.sh $DIREC3/ 2> /dev/null
EOF

if [ -f *.bpseq ] ; then

    echo "mv *.bpseq "$DIREC1"/" >> cleanup.sh

fi


sh cleanup.sh


############################################################################
##################Generate script for complete clean up#####################
############################################################################
cat<<EOF > remove_all_generated_files.sh
rm -r log_files/ scripts/ data_files/
rm last_frame.pdb
rm last_frame_rsr.pdb
rm remove_all_generated_files.sh
EOF

############################################################################
################### Displaying run time for script #########################
############################################################################

ELAPSED_TIME=$(($SECONDS - $START_TIME))

function displaytime {
    local T=$1
    local D=$((T/60/60/24))
    local H=$((T/60/60%24))
    local M=$((T/60%60))
    local S=$((T%60))
    (( $D > 0 )) && printf '%d days ' $D
    (( $H > 0 )) && printf '%d hours ' $H
    (( $M > 0 )) && printf '%d minutes ' $M
    (( $D > 0 || $H > 0 || $M > 0 )) && printf 'and '
    printf '%d seconds\n' $S
    }

echo -n '
Run time for script:'
displaytime $ELAPSED_TIME

############################################################################
############## Removing most of the Spinner output from the log #############
############################################################################

sed -i $'s/[^H^H^H^H^H^H[:print:]\t]//g' namdinator_stdout.log
