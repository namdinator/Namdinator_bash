
per_residue_energies.mpi.linuxgccrelease -in:file:s fit_nico_cryst_altered.pdb -ignore_unrecognized_res > fit_nico_cryst_altered_perRes.log
sort -k21 -n -r default.out > fit_nico_cryst_altered_perRes.sc
rm default.out

per_residue_energies.mpi.linuxgccrelease -in:file:s last_frame.pdb -ignore_unrecognized_res > lf_perRes.log
sort -k21 -n -r default.out > lf_perRes.sc
rm default.out

