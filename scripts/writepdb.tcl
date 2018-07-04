
mol new 3jd8_cryst_altered_autopsf.pdb
mol addfile 3jd8_cryst_altered_autopsf.psf
mol addfile simulation-step1.coor
animate write pdb last_frame.pdb beg [expr [molinfo top get numframes] -1] end [expr [molinfo top get numframes] -1] skip 1 top
