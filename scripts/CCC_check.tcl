
package require mdff
package require multiplot

mol new 3jd8_cryst_altered_autopsf.psf
mol addfile simulation-step1.dcd waitfor all
mdff check -ccc -map emd_6640.mrc -res 4.4 waitfor -1 -cccfile ccc_frames.txt
multiplot reset

mol new 3jd8_cryst_altered_autopsf.psf
mol addfile simulation-step1.dcd type dcd first 0 last -1 waitfor all top

set incre [ expr 2000/1000]
for {set i 0} {$i < $incre} {incr i 1} { 
         [atomselect top all frame $i] writepdb frame$i.pdb 
 } 
