package require ssrestraints
package require mdff
package require autopsf
package require cispeptide
package require chirality
mol new 3jd8_cryst_altered.pdb
autopsf -mol 0
cispeptide restrain -o 3jd8_cryst_altered-extrabonds-cis.txt
chirality restrain -o 3jd8_cryst_altered-extrabonds-chi.txt
ssrestraints -psf 3jd8_cryst_altered_autopsf.psf -pdb 3jd8_cryst_altered_autopsf.pdb -o 3jd8_cryst_altered-extrabonds.txt -hbonds
mdff gridpdb -psf 3jd8_cryst_altered_autopsf.psf -pdb 3jd8_cryst_altered_autopsf.pdb -o 3jd8_cryst_altered-grid.pdb
mdff griddx -i emd_6640.mrc -o emd_6640-grid.dx
mdff setup -o simulation -psf 3jd8_cryst_altered_autopsf.psf -pdb 3jd8_cryst_altered_autopsf.pdb -griddx emd_6640-grid.dx -gridpdb 3jd8_cryst_altered-grid.pdb -extrab {3jd8_cryst_altered-extrabonds.txt 3jd8_cryst_altered-extrabonds-cis.txt 3jd8_cryst_altered-extrabonds-chi.txt} -parfiles {/opt/bioxray/programs/vmd-1.93/lib/plugins/noarch/tcl/readcharmmpar1.3/par_all36_lipid.prm /opt/bioxray/programs/vmd-1.93/lib/plugins/noarch/tcl/readcharmmpar1.3/par_all36_prot.prm /opt/bioxray/programs/vmd-1.93/lib/plugins/noarch/tcl/readcharmmpar1.3/par_all36_carb.prm /opt/bioxray/programs/vmd-1.93/lib/plugins/noarch/tcl/readcharmmpar1.3/toppar_water_ions_namd.str /opt/bioxray/programs/vmd-1.93/lib/plugins/noarch/tcl/readcharmmpar1.3/par_all36_cgenff.prm /opt/bioxray/programs/vmd-1.93/lib/plugins/noarch/tcl/readcharmmpar1.3/par_all36_na.prm} -temp 300 -ftemp 300 -gscale 0.3 -numsteps 2000 -minsteps 500

