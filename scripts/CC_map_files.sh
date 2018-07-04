
phenix.reduce -Trim 3jd8_cryst_altered_autopsf.pdb > trimmed.pdb -Quiet

phenix.map_model_cc trimmed.pdb emd_6640.mrc resolution=4.4 > CC_input.log
phenix.map_model_cc last_frame.pdb emd_6640.mrc resolution=4.4 > CC_lf.log
phenix.map_model_cc last_frame_rsr.pdb emd_6640.mrc resolution=4.4 > CC_rsr.log

rm trimmmed.pdb
