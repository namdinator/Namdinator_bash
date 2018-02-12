package require cispeptide

mol new fit_nico_cryst_altered.pdb
set out1 [open fit_nico_cryst_altered_cis.log w]
puts $out1 [cispeptide check -mol top]
close $out1
cispeptide reset

mol new last_frame.pdb
set out2 [open last_frame_cis.log w]
puts $out2 [cispeptide check -mol top]
close $out2
cispeptide reset

