
color Display Background white
mol new emd_6640.mrc
mol modcolor 0 top colorID 2
mol modstyle 0 top Isosurface 0.103826 0 0 1 1 1
mol new data_files/3jd8_cryst_altered_autopsf.psf
mol addfile data_files/simulation-step1.dcd
mol modstyle 0 top NewCartoon
mol modcolor 0 top colorID 0
animate forward
animate style loop
menu graphics on
menu tkcon on
