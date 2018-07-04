
per_residue_energies.mpi.linuxgccrelease -in:file:s 3jd8_cryst_altered.pdb -ignore_unrecognized_res > 3jd8_cryst_altered_perRes.log
sort -k21 -n -r default.out > 3jd8_cryst_altered_perRes.sc
rm default.out

per_residue_energies.mpi.linuxgccrelease -in:file:s last_frame.pdb -ignore_unrecognized_res > lf_perRes.log
sort -k21 -n -r default.out > lf_perRes.sc
rm default.out

per_residue_energies.mpi.linuxgccrelease -in:file:s last_frame_rsr.pdb -ignore_unrecognized_res > lf_rsr_perRes.log 
sort -k21 -n -r default.out > lf_rsr_perRes.sc
rm default.out

