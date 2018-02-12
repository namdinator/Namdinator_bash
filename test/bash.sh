cat fit_nico.pdb | grep ATOM | sed 's/./& /22' > PDB_alt.pdb

cat PDB_alt.pdb |grep ATOM | awk '{print $3,$4,$5,$6}' | sort | uniq -dc | sort -n | uniq > duplicate_atoms.plt

if [ -s duplicate_atoms.plt ]; then

    echo "Identified duplicated atoms within "$PDBIN"! stopping the run and listing the duplicats below!"

    cat duplicate_atoms.plt
 
    exit
    
else
    rm -f duplicate_atoms.plt   
fi
