
score_jd2.mpi.linuxgccrelease -in:file:s fit_nico_cryst_altered.pdb -ignore_unrecognized_res -edensity::mapfile sharpened_map.mrc -edensity::mapreso 4.3 -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile fit_nico_cryst_altered.sc > fit_nico_cryst_altered_rosetta.log

score_jd2.mpi.linuxgccrelease -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile sharpened_map.mrc -edensity::mapreso 4.3 -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log

