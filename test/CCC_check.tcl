
package require mdff
package require multiplot

mol new fit_nico_cryst_altered_autopsf.psf
mol addfile simulation-step1.dcd waitfor all
mdff check -ccc -map sharpened_map.ccp4 -res 4.3 waitfor -1 -cccfile ccc_frames.txt
multiplot reset

mol new fit_nico_cryst_altered_autopsf.pdb
mdff check -ccc -map sharpened_map.ccp4 -res 4.3 waitfor -1 -cccfile ccc_input.txt
multiplot reset

mol new last_frame.pdb
mdff check -ccc -map sharpened_map.ccp4 -res 4.3 waitfor -1 -cccfile ccc_lastframe.txt

mol new fit_nico_cryst_altered_autopsf.psf
mol addfile simulation-step1.dcd type dcd first 0 last -1 waitfor all top

set incre [ expr 20000/1000]
for {set i 0} {$i < $incre} {incr i 1} { 
         [atomselect top all frame $i] writepdb frame$i.pdb 
 } 
