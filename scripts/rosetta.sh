
score_jd2.mpi.linuxgccrelease -in:file:s 3jd8_cryst_altered.pdb -ignore_unrecognized_res -edensity::mapfile emd_6640.mrc -edensity::mapreso 4.4 -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile 3jd8_cryst_altered.sc > 3jd8_cryst_altered_rosetta.log

score_jd2.mpi.linuxgccrelease -in:file:s last_frame.pdb -ignore_unrecognized_res -edensity::mapfile emd_6640.mrc -edensity::mapreso 4.4 -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf.sc > lf_rosetta.log

score_jd2.mpi.linuxgccrelease -in:file:s last_frame_rsr.pdb -ignore_unrecognized_res -edensity::mapfile emd_6640.mrc -edensity::mapreso 4.4 -edensity:fastdens_wt 20.0 -edensity::cryoem_scatterers -crystal_refine -out:file:scorefile lf_rsr.sc > lf_rsr_rosetta.log

