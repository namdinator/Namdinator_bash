#!/bin/bash
# log to file

VMDMASTER="/opt/bioxray/programs/vmd-1.93"

module load vmd-1.93
module load namd-cuda-2.12
module load rosetta_mpi_2017.08.59291
############################################################################
############################################################################
############################################################################
#################### Namdinator Ver. 1.4 Jan  2018 #########################
############################################################################
####### Namdinator is a Bash script for running an automatic MDFF ##########
####### (Molecular Dynamics Flexible Fitting) simulation from the ##########
####### commandline. Namdinator Ver 1.2 supports VMD-1.93         ##########
####### and charmm36 together with NAMD ver 2.12 (CUDA).          ##########
####### After the simulation an optinal default Phenix.real_space ##########
####### _refine run may be performed after the simulation.        ##########
####### Phenix validation of the input PDB, the output PDB        ##########
####### from the MD simulation alone (last_frame) and the PDB from##########
####### the following real_space refinement run (last_frame_rsr)  ##########
####### is run and the results are displayed side by side in a    ##########
####### table at the end of the run. /Ruki Email: rtk@mbg.au.dk   ##########
############################################################################
############################################################################
############################################################################


############################################################################
########### You can alter the below parameters for the MDFF setup,##########
########### otherwise the stated default values will be used.     ##########
############################################################################

GS=0.3

NUMS=20000

ITEMP=300

FTEMP=300

EM=2000

PROCS="$(( $(lscpu | grep ^CPU\(s\)\: | awk '{print $2}') / $(lscpu | grep ^Thread | awk '{print $4}') ))"

BF=20

############################################################################
################DONT CHANGE ANYTHING BELOW THIS POINT!!!####################
############################################################################

bold=$(tput bold)
normal=$(tput sgr0)

usage()
{
cat <<EOF
usage: $0 options

$normal
Namdinator sets up a MDFF simulation and runs it via NAMD2 to perform a MDFF flexiable fit of the input PDB file into the input density map.

To use Namdinator you $bold have $normal to supply NAmdinator with a standard format PDB file using the -p flag, a densit map file (mrc/map/ccp4 etc) using the -m flag and the resolution of the input map, using the -r flag. If you want to do a default phenix.real space refinement (very much recommended) of the output PDB file (and the input map) from the MDFF simulation you also need to include the -x flag.
$normal.

Examples:

To run Namdinator without phenix.real_space refinement:
$bold
./Namdinator.sh -p input.pdb -m input.map -r resolution_of_map
$normal
To run Namdinator with phenix.real_space refinement:
$bold
./Namdinator.sh -p input.pdb -m input.map -r resolution_of_input_map -x
$normal
To obtain additonal information about Namdinator and  the different flags you can use in Namdinator:
$bold
./Namdinator.sh -help
$normal

Instead of tinkering with the script, you can change some of the standard parameters that Namdinator utilizes, directly from the commandline using vairous flags. Lets say you want to run the simulation for longer than the default length of 20.000, you simply include the flag -s followed by the new value e.g. 150.000.

All of Namdinator's flags are listed below:

      -h Help

      -p Input PDB file

      -m Input map file (.mrc/.ccp4/.map/.situs)

      -e Number of Minimization steps (default is 2000)

      -g G-scale value (default: 0.3)

      -b B-factor value to be applied all atoms in the output PDB file (default: 20).

      -t Inital temperature (default: 300 kelvin)

      -f Final temperature (default: 300 kelvin)

      -s Length of MDFF simulation (default 100000 NB. 1000 = 1 ps)

      -x If set performs  a default phenix real space refinement ru on the output PDB file from the simulation. Needs the -r flag to be set to function. Does not work with HETATMS and .sit density maps unfortuneately.

      -r Resolution of the input map. Used for CCC calculations and for phenix.real space refinement.

      -l If this flag is set, all present HETATM will be allowed to stay in the input PDB file and used throughout the simulation. Does not work well with the -x flag.

      -n Number or processors used (default: number of processors divided by number of threads)

**************************************************************
All files produced by Namdinator pertaining to the actual simulation (and phenix real space refienemnt if relevant), are stored in the folder "data_files" whereas the log files and scripts produced by Namdinator are all stored in the folders "log_files" and "scripts" respectively.

**************************************************************
Namdinator writes out the last frame from the calculated trajectory as a PDB file called last_frame.pdb. Hydrogens are removed from the PDB file and all HSD/HSE/HSP residues are converted back to HIS.
The last_frame.pdb file is then used (if the -x flag is set) as input model for the Phenix.real_space_refine, together with the input map. The output is written as a PDB file named: last_frame_rsr.pdb.
last_frame.pdb and last_frame_rsr.pdb are then, together with the input PDB file, run through selected Phenix validations tools and rosetta score functions. A summary of the results from all three files is displayed in a table at the end of Namdinator for easy comparison.

**************************************************************
To visualize the trajectory calculated during the simulation in VMD afterwards, Namdinator automatically creates a .tcl script$bold (visualize_trj.tcl)$normal which enables easy visualizationt of both the map and the trajectory calculated by Namdinator.

To launch the script from the commandline, simply type:$bold vmd -dispdev win -e visualize_trj.tcl .$normal This will open VMD (if VMD is installed or module loaded) and initiate a looped playback of the trajectory, while enabling you to move around and inspect the model. As all maps are different, chances are very high that the default contour isovalue will not work at all with your map. As I have found no smart automatic way of setting a usefull contour level, you will have to change the isovalue manually in VMD. This is done by going to the "graphical representations" window that should open together with VMD after running the visualize_trj.tcl script. There you will have to alter the isovalue value until your map is displayed as you prefer.

************************************************************** $bold
REMARK:"$normal"The input PDB file is currently not allowed to contain any record's besides the ATOM record, as they tend to make the autoPSF step in MDFF fail and hence make Namdinator crash. This means that any non-ATOM records will be cropped from the PDB used for the simulation, but the orginal input PDB file will remain intact.
The optimal choice of the scaling factor, i.e. the g-scale parameter, depends on the system to be fitted and the map. The higher the value, the stronger the forces acting on the system to fit the map, will be. In general a gscale of 0.3-0.6 works fine, however, too high g-scale values can make the simulation crash due to too high velocity of the atoms. If you, despite using a relativ low g-scale value, still experience to fast movement of the atoms you could try to increase the number of minimization steps to above the default 2000 by using the -e flag, though 2000 seems to work really well.
Also, please note, that due to the stochastic nature of molecular dynamics simulations, it is expected that trajectories obtained from identical input files will differ slightly from each run.

Enjoy

EOF
}

while getopts “hp:m:n:b:g:e:t:f:s:r:lx” OPTION
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

mkdir $DIREC1
mkdir $DIREC2
mkdir $DIREC3

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
PDB=$(echo "$PDBIN"| cut -d\. -f1)
PDBEXT=$(echo "$PDBIN"| rev| cut -d\. -f1|rev )

MAP=$(echo "$MAPIN"| cut -d\. -f1)
MAPEXT=$(echo "$MAPIN"| cut -d\. -f2)



if [ "$PDBIN" = "" ] && [ "$MAPIN" = "" ]; then
   echo ""$normal"

$normal
Namdinator sets up a MDFF simulation and runs it via NAMD2 to perform a MDFF flexiable fit of the input PDB file into the input density map.

To use Namdinator you $bold have $normal to supply NAmdinator with a standard format PDB file using the -p flag, a densit map file (mrc/map/ccp4 etc) using the -m flag and the resolution of the input map, using the -r flag. If you want to do a default phenix.real space refinement (very much recommended) of the output PDB file (and the input map) from the MDFF simulation you also need to include the -x flag.
$normal.

Examples:

To run Namdinator without phenix.real_space refinement:
$bold
./Namdinator.sh -p input.pdb -m input.map -r resolution_of_map
$normal
To run Namdinator with phenix.real_space refinement:
$bold
./Namdinator.sh -p input.pdb -m input.map -r resolution_of_input_map -x
$normal
To obtain additonal information about Namdinator and  the different flags you can use in Namdinator:
$bold
./Namdinator.sh -help
$normal

Instead of tinkering with the script, you can change some of the standard parameters that Namdinator utilizes, directly from the commandline using vairous flags. Lets say you want to run the simulation for longer than the default length of 20.000, you simply include the flag -s followed by the new value e.g. 150.000.

All of Namdinator's flags are listed below:

      -h Help

      -p Input PDB file

      -m Input map file (.mrc/.ccp4/.map/.situs)

      -e Number of Minimization steps (default is 2000)

      -g G-scale value (default: 0.3)

      -b B-factor value to be applied all atoms in the output PDB file (default: 20).

      -t Inital temperature (default: 300 kelvin)

      -f Final temperature (default: 300 kelvin)

      -s Length of MDFF simulation (default 100000 NB. 1000 = 1 ps)

      -x If set performs  a default phenix real space refinement ru on the output PDB file from the simulation. Needs the -r flag to be set to function. Does not work with HETATMS and .sit density maps unfortuneately.

      -r Resolution of the input map. Used for CCC calculations and for phenix.real space refinement.

      -l If this flag is set, all present HETATM will be allowed to stay in the input PDB file and used throughout the simulation. Does not work well with the -x flag.

      -n Number or processors used (default: number of processors divided by number of threads)
"
    exit 1

elif [ "$PDBEXT" != "pdb" ]; then
 echo "You have to input a .pdb file!"
     exit 1

elif [ "$PDBIN" = "" ] && [ "$MAPIN" != "" ]; then
#elif [ "$PDBIN" = "" ]; then
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

    else
    echo -n "
NO CRYST1 record found in input PDB! Inserting default CRYST1 string to enable Phenix real space refine to run
"

sed '1s/^/CRYST1    1.000   1.000    1.000  90.00  90.00  90.00 P 1           1\n/' $PDBIN > "$PDB"_cryst.pdb
fi
fi

PDB="$PDB"_cryst


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

echo -n "Removing any CONECT/SHEET/HELIX records that may be present in $PDBIN, as they can make Namdinator crash.

"

if [ "$LIGANDS" = "1" ]; then


    grep "HETATM\|^TER\|END\|^CRYST1\|^ATOM" $PDBIN > ${PDB}_altered.pdb
    
 else

    grep "^TER\|END\|^CRYST1\|^ATOM" $PDBIN > ${PDB}_altered.pdb

     
fi

sed -i 's/UNK/ALA/g' "$PDB"_altered.pdb

mv "$PDB".pdb $DIREC1/

PDB="$PDB"_altered

REST=""$PDB"-extrabonds.txt "$PDB"-extrabonds-cis.txt "$PDB"-extrabonds-chi.txt"

PARAMS=""${VMDMASTER}"/lib/plugins/noarch/tcl/readcharmmpar1.3/par_all36_lipid.prm "${VMDMASTER}"/lib/plugins/noarch/tcl/readcharmmpar1.3/par_all36_prot.prm "${VMDMASTER}"/lib/plugins/noarch/tcl/readcharmmpar1.3/par_all36_carb.prm "${VMDMASTER}"/lib/plugins/noarch/tcl/readcharmmpar1.3/toppar_water_ions_namd.str "${VMDMASTER}"/lib/plugins/noarch/tcl/readcharmmpar1.3/par_all36_cgenff.prm "${VMDMASTER}"/lib/plugins/noarch/tcl/readcharmmpar1.3/par_all36_na.prm"



############################################################################
################# Generating NAMD files with MDFF setup#####################
############################################################################
echo -n "Running AutoPSF on "$PDB".pdb

Generating the following restraint files for "$PDB.pdb":

"$REST"

Generating simulation files for NAMD2

"
cat<<EOF > "MDFF_setup.tcl"
package require ssrestraints
package require mdff
package require autopsf
package require cispeptide
package require chirality
mol new $PDB.pdb
autopsf -mol 0
cispeptide restrain -o $PDB-extrabonds-cis.txt
chirality restrain -o $PDB-extrabonds-chi.txt
ssrestraints -psf ${PDB}_autopsf.psf -pdb ${PDB}_autopsf.pdb -o ${PDB}-extrabonds.txt -hbonds
mdff gridpdb -psf ${PDB}_autopsf.psf -pdb ${PDB}_autopsf.pdb -o ${PDB}-grid.pdb
mdff griddx -i $MAP.$MAPEXT -o $MAP-grid.dx
mdff setup -o simulation -psf ${PDB}_autopsf.psf -pdb ${PDB}_autopsf.pdb -griddx $MAP-grid.dx -gridpdb $PDB-grid.pdb -extrab {$REST} -parfiles {$PARAMS} -temp $ITEMP -ftemp $FTEMP -gscale $GS -numsteps $NUMS -minsteps $EM

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
module load namd-cuda-2.12

    echo -n "Proceeding with running NAMD2
"
    namd2 +p"$PROCS" simulation-step1.namd | tee NAMD2_step1.log &

    echo -n "PROCESSING..."

    spinner $!

#    cat NAMD2_step1.log

############################################################################
############# Stop script from continuing if autoPSF fails #################
############################################################################

if [[ ! -f ${PDB}_autopsf.psf ]] ; then
       echo -n "
The file "$PDB"_autopsf.psf does not exsist!

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
mol new $MAP.$MAPEXT
mol modcolor 0 top colorID 2
mol modstyle 0 top Isosurface 0.103826 0 0 1 1 1
mol new data_files/${PDB}_autopsf.psf
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

mol new ${PDB}_autopsf.pdb
mol addfile ${PDB}_autopsf.psf
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

phenix.real_space_refine last_frame.pdb $MAPIN resolution=$RES

EOF

sh phenix_rs.sh | tee phenix_rsr.log &

spinner $!

mv -f last_frame_real_space_refined.pdb last_frame_rsr.pdb

fi


############################################################################
################## Cross correlation coefficient check #####################
############################################################################

if [ "$PHENIXRS" = "1" ]; then

cat<<EOF > CCC_check.tcl

package require mdff
package require multiplot

mol new ${PDB}_autopsf.psf
mol addfile simulation-step1.dcd waitfor all
mdff check -ccc -map $MAP.$MAPEXT -res $RES waitfor -1 -cccfile ccc_frames.txt
multiplot reset

mol new ${PDB}.pdb
mdff check -ccc -map $MAP.$MAPEXT -res $RES waitfor -1 -cccfile ccc_input.txt
multiplot reset

mol new last_frame.pdb
mdff check -ccc -map $MAP.$MAPEXT -res $RES waitfor -1 -cccfile ccc_lastframe.txt

mol new last_frame_rsr.pdb
mdff check -ccc -map $MAP.$MAPEXT -res $RES waitfor -1 -cccfile ccc_lastframe_rsr.txt

mol new ${PDB}_autopsf.psf
mol addfile simulation-step1.dcd type dcd first 0 last -1 waitfor all top

set incre [ expr $NUMS/1000]
for {set i 0} {\$i < \$incre} {incr i 1} { 
         [atomselect top all frame \$i] writepdb frame\$i.pdb 
 } 
EOF

echo -n "
Calculating the CCC between the model from each frame of the trajectory simulation-step1.dcd and "$MAP"."$MAPEXT"
"

vmd -dispdev text -eofexit <CCC_check.tcl> CCC_check.log &

spinner $!


else


cat<<EOF > CCC_check.tcl

package require mdff
package require multiplot

mol new ${PDB}_autopsf.psf
mol addfile simulation-step1.dcd waitfor all
mdff check -ccc -map $MAP.$MAPEXT -res $RES waitfor -1 -cccfile ccc_frames.txt
multiplot reset

mol new ${PDB}_autopsf.pdb
mdff check -ccc -map $MAP.$MAPEXT -res $RES waitfor -1 -cccfile ccc_input.txt
multiplot reset

mol new last_frame.pdb
mdff check -ccc -map $MAP.$MAPEXT -res $RES waitfor -1 -cccfile ccc_lastframe.txt

mol new ${PDB}_autopsf.psf
mol addfile simulation-step1.dcd type dcd first 0 last -1 waitfor all top

set incre [ expr $NUMS/1000]
for {set i 0} {\$i < \$incre} {incr i 1} { 
         [atomselect top all frame \$i] writepdb frame\$i.pdb 
 } 
EOF

echo -n "
Calculating the CCC between the model from each frame of the trajectory simulation-step1.dcd and "$MAP"."$MAPEXT"
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

mol new ${PDB}.pdb
set out1 [open ${PDB}_cis.log w]
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

mol new ${PDB}.pdb
set out1 [open ${PDB}_cis.log w]
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

phenix.ramalyze $PDB.pdb > rama_$PDB.log
phenix.rotalyze $PDB.pdb > rota_$PDB.log
phenix.cbetadev $PDB.pdb > cbeta_$PDB.log
phenix.clashscore $PDB.pdb > clash_$PDB.log
EOF

phenix.ramalyze last_frame_rsr.pdb > rama_last_frame_rsr.log & PID[8]=$!
phenix.rotalyze last_frame_rsr.pdb > rota_last_frame_rsr.log & PID[9]=$!
phenix.cbetadev last_frame_rsr.pdb > cbeta_last_frame_rsr.log & PID[10]=$!
phenix.clashscore last_frame_rsr.pdb > clash_last_frame_rsr.log & PID[11]=$!

phenix.ramalyze last_frame.pdb > rama_last_frame.log & PID[12]=$!
phenix.rotalyze last_frame.pdb > rota_last_frame.log & PID1[13]=$!
phenix.cbetadev last_frame.pdb > cbeta_last_frame.log & PID[14]=$!
phenix.clashscore last_frame.pdb > clash_last_frame.log & PID[15]=$!

phenix.ramalyze $PDB.pdb > rama_$PDB.log & PID[16]=$!
phenix.rotalyze $PDB.pdb > rota_$PDB.log & PID[17]=$!
phenix.cbetadev $PDB.pdb > cbeta_$PDB.log & PID[18]=$!
phenix.clashscore $PDB.pdb > clash_$PDB.log & PID[19]=$!

echo -n "
Running Molprobity valdations tools on input and output PDB files
"

 else

     cat<<EOF > molpro.sh
phenix.ramalyze last_frame.pdb > rama_last_frame.log
phenix.rotalyze last_frame.pdb > rota_last_frame.log
phenix.cbetadev last_frame.pdb > cbeta_last_frame.log
phenix.clashscore last_frame.pdb > clash_last_frame.log

phenix.ramalyze $PDB.pdb > rama_$PDB.log
phenix.rotalyze $PDB.pdb > rota_$PDB.log
phenix.cbetadev $PDB.pdb > cbeta_$PDB.log
phenix.clashscore $PDB.pdb > clash_$PDB.log
EOF

phenix.ramalyze last_frame.pdb > rama_last_frame.log & PID[12]=$!
phenix.rotalyze last_frame.pdb > rota_last_frame.log & PID[13]=$!
phenix.cbetadev last_frame.pdb > cbeta_last_frame.log & PID[14]=$!
phenix.clashscore last_frame.pdb > clash_last_frame.log & PID[15]=$!

phenix.ramalyze $PDB.pdb > rama_$PDB.log & PID[16]=$!
phenix.rotalyze $PDB.pdb > rota_$PDB.log & PID[17]=$!
phenix.cbetadev $PDB.pdb > cbeta_$PDB.log & PID[18]=$!
phenix.clashscore $PDB.pdb > clash_$PDB.log & PID[19]=$!

echo -n "
Running Molprobity valdations tools on input and output PDB files
"

 fi
 

############################################################################
###############Rosetta score for whole model against map ###################
############################################################################
if [ "$PHENIXRS" = "1" ]; then

LIMHIGH=4.0
LIMLOW=3.5

RES1=$(echo "($RES*100)" |bc | cut -d\. -f1)
LIM1=$(echo "($LIMHIGH*100)" |bc | cut -d\. -f1)
LIM2=$(echo "($LIMLOW*100)" |bc | cut -d\. -f1)

if [ "$RES1" -le  "$LIM1" ] && [ "$RES1" -ge "$LIM2" ]; then

cat<<EOF > rosetta.sh

score_jd2.mpi.linuxgccrelease -in:file:s ${PDB}.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:sliding_window_wt 2.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile ${PDB}.sc > ${PDB}_rosetta.log

score_jd2.mpi.linuxgccrelease -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:sliding_window_wt 2.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log

score_jd2.mpi.linuxgccrelease -in:file:s last_frame_rsr.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:sliding_window_wt 2.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf_rsr.sc > lf_rsr_rosetta.log

EOF

score_jd2.mpi.linuxgccrelease -in:file:s ${PDB}.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:sliding_window_wt 2.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile ${PDB}.sc > ${PDB}_rosetta.log & PID[20]=$!

score_jd2.mpi.linuxgccrelease -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:sliding_window_wt 2.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log & PID[21]=$!

score_jd2.mpi.linuxgccrelease -in:file:s last_frame_rsr.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:sliding_window_wt 2.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf_rsr.sc > lf_rsr_rosetta.log & PID[22]=$!


echo -n "
Calculating Rosetta scores for input and output PDB files. The lower the score, the more stable the structure is likely to be for a given protein.
"

elif [ "$RES1" -lt "$LIM2" ]; then

cat<<EOF > rosetta.sh

score_jd2.mpi.linuxgccrelease -in:file:s ${PDB}.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:sliding_window_wt 4.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile ${PDB}.sc > ${PDB}_rosetta.log

score_jd2.mpi.linuxgccrelease -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:sliding_window_wt 4.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log

score_jd2.mpi.linuxgccrelease -in:file:s last_frame_rsr.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:sliding_window_wt 4.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf_rsr.sc > lf_rsr_rosetta.log

EOF

score_jd2.mpi.linuxgccrelease -in:file:s ${PDB}.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:sliding_window_wt 4.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile ${PDB}.sc > ${PDB}_rosetta.log & PID[20]=$!

score_jd2.mpi.linuxgccrelease -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:sliding_window_wt 4.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log & PID[21]=$!

score_jd2.mpi.linuxgccrelease -in:file:s last_frame_rsr.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:sliding_window_wt 4.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf_rsr.sc > lf_rsr_rosetta.log & PID[22]=$!

echo -n "
Calculating Rosetta scores for input and output PDB files. The lower the score, the more stable the structure is likely to be for a given protein.
"
elif [ "$RES1" -gt  "$LIM1" ]; then

    cat<<EOF > rosetta.sh

score_jd2.mpi.linuxgccrelease -in:file:s ${PDB}.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile ${PDB}.sc > ${PDB}_rosetta.log

score_jd2.mpi.linuxgccrelease -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log

score_jd2.mpi.linuxgccrelease -in:file:s last_frame_rsr.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf_rsr.sc > lf_rsr_rosetta.log

EOF

score_jd2.mpi.linuxgccrelease -in:file:s ${PDB}.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile ${PDB}.sc > ${PDB}_rosetta.log & PID[20]=$!

score_jd2.mpi.linuxgccrelease -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log & PID[21]=$!

score_jd2.mpi.linuxgccrelease -in:file:s last_frame_rsr.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf_rsr.sc > lf_rsr_rosetta.log & PID[22]=$!


echo -n "
Calculating Rosetta scores for input and output PDB files. The lower the score, the more stable the structure is likely to be for a given protein.
"

else
    :
fi

 else

LIMHIGH=4.0
LIMLOW=3.5

RES1=$(echo "($RES*100)" |bc | cut -d\. -f1)
LIM1=$(echo "($LIMHIGH*100)" |bc | cut -d\. -f1)
LIM2=$(echo "($LIMLOW*100)" |bc | cut -d\. -f1)

if [ "$RES1" -le  "$LIM1" ] && [ "$RES1" -ge "$LIM2" ]; then

cat<<EOF > rosetta.sh

score_jd2.mpi.linuxgccrelease -in:file:s ${PDB}.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:sliding_window_wt 2.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile ${PDB}.sc > ${PDB}_rosetta.log

score_jd2.mpi.linuxgccrelease -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:sliding_window_wt 2.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log

EOF

score_jd2.mpi.linuxgccrelease -in:file:s ${PDB}.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:sliding_window_wt 2.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile ${PDB}.sc > ${PDB}_rosetta.log & PID[20]=$!

score_jd2.mpi.linuxgccrelease -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:sliding_window_wt 2.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log & PID[21]=$!


echo -n "
Calculating Rosetta scores for input and output PDB files. The lower the score, the more stable the structure is likely to be for a given protein.
"


elif [ "$RES1" -lt "$LIM2" ]; then

cat<<EOF > rosetta.sh

score_jd2.mpi.linuxgccrelease -in:file:s ${PDB}.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:sliding_window_wt 4.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile ${PDB}.sc > ${PDB}_rosetta.log

score_jd2.mpi.linuxgccrelease -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:sliding_window_wt 4.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log

EOF

score_jd2.mpi.linuxgccrelease -in:file:s ${PDB}.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:sliding_window_wt 4.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile ${PDB}.sc > ${PDB}_rosetta.log & PID[20]=$!

score_jd2.mpi.linuxgccrelease -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:sliding_window_wt 4.0 -edensity:sliding_window 3 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log & PID[21]=$!


echo -n "
Calculating Rosetta scores for input and output PDB files. The lower the score, the more stable the structure is likely to be for a given protein.
"

elif [ "$RES1" -gt  "$LIM1" ]; then

    cat<<EOF > rosetta.sh

score_jd2.mpi.linuxgccrelease -in:file:s ${PDB}.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile ${PDB}.sc > ${PDB}_rosetta.log

score_jd2.mpi.linuxgccrelease -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log

EOF

score_jd2.mpi.linuxgccrelease -in:file:s ${PDB}.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile ${PDB}.sc > ${PDB}_rosetta.log & PID[20]=$!

score_jd2.mpi.linuxgccrelease -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile ${MAP}.${MAPEXT} -edensity::mapreso ${RES} -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log & PID[21]=$!


echo -n "
Calculating Rosetta scores for input and output PDB files. The lower the score, the more stable the structure is likely to be for a given protein.
"

else
    :
fi

 fi
 
############################################################################
###############Rosetta score for individual residues #######################
############################################################################
if [ "$PHENIXRS" = "1" ]; then
 
cat<<EOF > rosetta_resi.sh

per_residue_energies.mpi.linuxgccrelease -in:file:s ${PDB}.pdb -ignore_unrecognized_res > ${PDB}_perRes.log
sort -k21 -n -r default.out > ${PDB}_perRes.sc
rm default.out

per_residue_energies.mpi.linuxgccrelease -in:file:s last_frame.pdb -ignore_unrecognized_res > lf_perRes.log
sort -k21 -n -r default.out > lf_perRes.sc
rm default.out

per_residue_energies.mpi.linuxgccrelease -in:file:s last_frame_rsr.pdb -ignore_unrecognized_res > lf_rsr_perRes.log 
sort -k21 -n -r default.out > lf_rsr_perRes.sc
rm default.out

EOF

per_residue_energies.mpi.linuxgccrelease -in:file:s ${PDB}.pdb -out:file:silent ${PDB}.out -ignore_unrecognized_res > ${PDB}_perRes.log & PID[23]=$!

per_residue_energies.mpi.linuxgccrelease -in:file:s last_frame.pdb -out:file:silent lf.out -ignore_unrecognized_res > lf_perRes.log & PID[24]=$!

per_residue_energies.mpi.linuxgccrelease -in:file:s last_frame_rsr.pdb -out:file:silent lfr.out -ignore_unrecognized_res > lf_rsr_perRes.log & PID[25]=$! 


echo -n "
Calculating Rosetta scores for individual residues in input and output PDB files. Single residues that scores significantly higher could indicate they are involved in clashes.
"

 else
cat<<EOF > rosetta_resi.sh

per_residue_energies.mpi.linuxgccrelease -in:file:s ${PDB}.pdb -ignore_unrecognized_res > ${PDB}_perRes.log
sort -k21 -n -r default.out > ${PDB}_perRes.sc
rm default.out

per_residue_energies.mpi.linuxgccrelease -in:file:s last_frame.pdb -ignore_unrecognized_res > lf_perRes.log
sort -k21 -n -r default.out > lf_perRes.sc
rm default.out

EOF

per_residue_energies.mpi.linuxgccrelease -in:file:s ${PDB}.pdb -out:file:silent ${PDB}.out -ignore_unrecognized_res > ${PDB}_perRes.log & PID[23]=$!

per_residue_energies.mpi.linuxgccrelease -in:file:s last_frame.pdb -out:file:silent lf.out -ignore_unrecognized_res > lf_perRes.log & PID[24]=$!


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
###################### extracting Rosetta Scores ###########################
############################################################################

if [ "$PHENIXRS" = "1" ]; then

cat<<EOF > sort_perResi_Score.sh

sort -k21 -n -r ${PDB}.out > ${PDB}_perRes.sc
rm ${PDB}.out
sort -k21 -n -r lf.out > lf_perRes.sc
rm lf.out
sort -k21 -n -r lfr.out > lf_rsr_perRes.sc
rm lfr.out

EOF

sh sort_perResi_Score.sh

awk 'NR<=10' ${PDB}_perRes.sc | awk '{print $3, $21}' > pr.sc
awk 'NR<=10' lf_perRes.sc | awk '{print $3, $21}' > pr2.sc
awk 'NR<=10' lf_rsr_perRes.sc | awk '{print $3, $21}' > pr3.sc


else

cat<<EOF > sort_perResi_Score.sh

sort -k21 -n -r ${PDB}.out > ${PDB}_perRes.sc
rm ${PDB}.out
sort -k21 -n -r lf.out > lf_perRes.sc
rm lf.out

EOF

sh sort_perResi_Score.sh

awk 'NR<=10' ${PDB}_perRes.sc | awk '{print $3, $21}' > pr.sc
awk 'NR<=10' lf_perRes.sc | awk '{print $3, $21}' > pr2.sc


fi


############################################################################
###############Displaying all the validation metrics #######################
############################################################################
if [ "$PHENIXRS" = "1" ]; then


CCC1=$(awk '{print $2}' ccc_input.txt)
CCC2=$(awk '{print $2}' ccc_lastframe.txt)
CCC3=$(awk '{print $2}' ccc_lastframe_rsr.txt)
     
claINP=$(awk 'END {print $NF}' clash_"$PDB".log)
claLF=$(awk 'END {print $NF}' clash_last_frame.log)
claLFR=$(awk 'END {print $NF}' clash_last_frame_rsr.log)

FAVINP=$(grep SUMMARY rama_"$PDB".log | awk '{print $2}' | head -n1)
FAVLF=$(grep SUMMARY rama_last_frame.log | awk '{print $2}' | head -n1)
FAVLFR=$(grep SUMMARY rama_last_frame_rsr.log | awk '{print $2}' | head -n1)

ALWINP=$(grep SUMMARY rama_"$PDB".log | awk '{print $4}' | head -n1)
ALWLF=$(grep SUMMARY rama_last_frame.log | awk '{print $4}' | head -n1)
ALWLFR=$(grep SUMMARY rama_last_frame_rsr.log | awk '{print $4}' | head -n1)

OUTINP=$(grep SUMMARY rama_"$PDB".log | awk '{print $6}' | head -n1)
OUTLF=$(grep SUMMARY rama_last_frame.log | awk '{print $6}' | head -n1)
OUTLFR=$(grep SUMMARY rama_last_frame_rsr.log | awk '{print $6}' | head -n1)

CBEINP=$(grep "SUMMARY" cbeta_"$PDB".log | awk '{print $2}')
CBELF=$(grep "SUMMARY" cbeta_last_frame.log | awk '{print $2}')
CBELFR=$(grep "SUMMARY" cbeta_last_frame_rsr.log | awk '{print $2}')

ROTINP=$(grep "SUMMARY" rota_"$PDB".log | awk '{print $2}')
ROTLF=$(grep "SUMMARY" rota_last_frame.log | awk '{print $2}')
ROTLFR=$(grep "SUMMARY" rota_last_frame_rsr.log | awk '{print $2}')

CISINP=$(awk '{print $1}' ${PDB}_cis.log)
CISLF=$(awk '{print $1}' last_frame_cis.log)
CISLFR=$(awk '{print $1}' last_frame_rsr_cis.log)


ROSINP=$(awk 'NR==3' ${PDB}.sc | awk '{print $2}')
ROSLF=$(awk 'NR==3' lf.sc | awk '{print $2}')
ROSLFR=$(awk 'NR==3' lf_rsr.sc | awk '{print $2}')


INP=INP
LF=LF
LFR=LFR

 else

CCC1=$(awk '{print $2}' ccc_input.txt)
CCC2=$(awk '{print $2}' ccc_lastframe.txt)
     
claINP=$(awk 'END {print $NF}' clash_"$PDB".log)
claLF=$(awk 'END {print $NF}' clash_last_frame.log)

FAVINP=$(grep SUMMARY rama_"$PDB".log | awk '{print $2}' | head -n1)
FAVLF=$(grep SUMMARY rama_last_frame.log | awk '{print $2}' | head -n1)

ALWINP=$(grep SUMMARY rama_"$PDB".log | awk '{print $4}' | head -n1)
ALWLF=$(grep SUMMARY rama_last_frame.log | awk '{print $4}' | head -n1)

OUTINP=$(grep SUMMARY rama_"$PDB".log | awk '{print $6}' | head -n1)
OUTLF=$(grep SUMMARY rama_last_frame.log | awk '{print $6}' | head -n1)

CBEINP=$(grep "SUMMARY" cbeta_"$PDB".log | awk '{print $2}')
CBELF=$(grep "SUMMARY" cbeta_last_frame.log | awk '{print $2}')

ROTINP=$(grep "SUMMARY" rota_"$PDB".log | awk '{print $2}')
ROTLF=$(grep "SUMMARY" rota_last_frame.log | awk '{print $2}')

CISINP=$(awk '{print $1}' ${PDB}_cis.log)
CISLF=$(awk '{print $1}' last_frame_cis.log)

ROSINP=$(awk 'NR==3' ${PDB}.sc | awk '{print $2}')
ROSLF=$(awk 'NR==3' lf.sc | awk '{print $2}')

INP=INP
LF=LF
LFR=LFR


fi


echo -n '
'$bold'
To visualize the simulation in VMD simply copy/paste this command: vmd -dispdev win -e scripts/visualize_trj.tcl '$normal'
'
echo -n "
Legend to the below table:

INP = "$PDBIN" > This is the input PDB file.
LF = last_frame.pdb    > This is the output PDB file from the MD simulation (last frame of the trajectory).
LFR = last_frame_rsr.pdb  > Output PDB file from the Phenix real space refinement run on last_frame.pdb.
CCC = Cross correlation coefficient between "$MAP"."$MAPEXT" and either of the above PDB files.
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
printf "|  CCC:            | %10s | %10s | %10s |          \n" ${CCC1:0:7} ${CCC2:0:7} ${CCC3:0:7}
printf "|  Cis-Peptides:   | %10s | %10s | %10s |          \n" $CISINP $CISLF $CISLFR
printf "|  Rosetta score:  | %10s | %10s | %10s |          \n" ${ROSINP:0:7} ${ROSLF:0:7} ${ROSLFR:0:7}
printf "+---------------------------------------------------------+\n"
echo ""


if [ "$PHENIXRS" = "1" ]; then
    
    pr -mts pr.sc pr2.sc pr3.sc > perRes_scores_all.sc

    sed -i '1s/^/ Resid_Inp Score_Inp Resid_LF Score_LF Resid_LFR Score_LFR\n/' perRes_scores_all.sc

else
    pr -mts pr.sc pr2.sc > perRes_scores_all.sc

    sed -i '1s/^/ Resid_inp Score_inp Resid_LF Score_LF\n/' perRes_scores_all.sc
fi

echo -n "Displaying the top 10 Rosetta scoring residues from each PDB file. Significantly higher score values for an indivdual residue may indicate it is involved in a clash:                                                                                                   

"
column -t perRes_scores_all.sc

echo -n "                                                                                                                                                                                                                                                                         
"

############################################################################
########################Light Clean up/organization#########################
############################################################################

cat<<EOF > cleanup.sh
mv *.pkl $DIREC2/ 2> /dev/null
mv *.csv $DIREC2/ 2> /dev/null
mv *_plots $DIREC2/ 2> /dev/null
mv simulation-step* $DIREC1/ 2> /dev/null
mv mdff_template.namd $DIREC1/ 2> /dev/null
mv $PDB-extrabonds-cis.txt $DIREC1/ 2> /dev/null
mv $PDB-extrabonds-chi.txt $DIREC1/ 2> /dev/null
mv $PDB-extrabonds.txt $DIREC1/ 2> /dev/null
mv $PDB.pdb $DIREC1/ 2> /dev/null
mv ${PDB}_autopsf*.* $DIREC1/ 2> /dev/null
mv $PDB-grid.pdb $DIREC1/ 2> /dev/null
mv $MAP-grid.dx $DIREC1/ 2> /dev/null
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
