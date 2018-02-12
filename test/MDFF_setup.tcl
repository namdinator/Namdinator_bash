package require ssrestraints
package require mdff
package require autopsf
package require cispeptide
package require chirality
mol new fit_nico_cryst_altered.pdb
autopsf -mol 0
cispeptide restrain -o fit_nico_cryst_altered-extrabonds-cis.txt
chirality restrain -o fit_nico_cryst_altered-extrabonds-chi.txt
ssrestraints -psf fit_nico_cryst_altered_autopsf.psf -pdb fit_nico_cryst_altered_autopsf.pdb -o fit_nico_cryst_altered-extrabonds.txt -hbonds
mdff gridpdb -psf fit_nico_cryst_altered_autopsf.psf -pdb fit_nico_cryst_altered_autopsf.pdb -o fit_nico_cryst_altered-grid.pdb
mdff griddx -i sharpened_map.ccp4 -o sharpened_map-grid.dx
mdff setup -o simulation -psf fit_nico_cryst_altered_autopsf.psf -pdb fit_nico_cryst_altered_autopsf.pdb -griddx sharpened_map-grid.dx -gridpdb fit_nico_cryst_altered-grid.pdb -extrab {fit_nico_cryst_altered-extrabonds.txt fit_nico_cryst_altered-extrabonds-cis.txt fit_nico_cryst_altered-extrabonds-chi.txt} -parfiles {/opt/bioxray/programs/vmd-1.93/lib/plugins/noarch/tcl/readcharmmpar1.3/par_all36_lipid.prm /opt/bioxray/programs/vmd-1.93/lib/plugins/noarch/tcl/readcharmmpar1.3/par_all36_prot.prm /opt/bioxray/programs/vmd-1.93/lib/plugins/noarch/tcl/readcharmmpar1.3/par_all36_carb.prm /opt/bioxray/programs/vmd-1.93/lib/plugins/noarch/tcl/readcharmmpar1.3/toppar_water_ions_namd.str /opt/bioxray/programs/vmd-1.93/lib/plugins/noarch/tcl/readcharmmpar1.3/par_all36_cgenff.prm /opt/bioxray/programs/vmd-1.93/lib/plugins/noarch/tcl/readcharmmpar1.3/par_all36_na.prm} -temp 300 -ftemp 300 -gscale 0.3 -numsteps 20000 -minsteps 2000

