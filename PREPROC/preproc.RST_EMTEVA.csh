#! /bin/csh 

set study = EMT
set subjs = ${1}


set template = MNI152_T1_2009c+tlrc

# get out of scripts folder 
cd ../..

set topdir = `pwd`

# updates:
#   - perform uniformity correction on anat before skull strip
#   - specify non-linear registration of anat to template --> will not do b/c of skull stripping issues
#   - do anaticor (regress local white matter)
#   - censor outliers
#   - regress average eroded CSF --> will not do because of BOLD signal bleed through into draining veins
# - doing a non linear registration to the HaskinsPeds mask

foreach subj ($subjs)  

	cd ${topdir}
	cd ${study}${subj}



	set sdir = `pwd`

	afni_proc.py -subj_id ${study}${subj}                                 	    	\
		-out_dir PROC.RST 							\
		-script proc.${study}${subj}.RST.tcsh		 			\
		-dsets $sdir/RST/${study}${subj}.RST.nii.gz                            	\
		-copy_anat $sdir/ANAT/${study}${subj}.ANAT.nii.gz                       \
		-blocks despike tshift align tlrc volreg blur scale mask regress	\
#		-anat_uniform_method unifize                    			\
		-tlrc_base ${template} 							\
		-tlrc_NL_warp								\
		-align_opts_aea -skullstrip_opts 					\
			-blur_fwhm 2 -use_skull -avoid_vent -avoid_vent -init_radius 75 \
		-mask_segment_anat yes							\
		-tcat_remove_first_trs 3  		                        	\
		-tshift_opts_ts -tpattern alt+z      					\
		-volreg_base_dset $sdir/RST/${study}${subj}.RST.nii.gz  		\
		-volreg_align_e2a                                               	\
		-volreg_tlrc_warp                                               	\
		-blur_size 6                                                    	\
		-regress_anaticor                                               	\
		-regress_anaticor_radius 25                                     	\
		-regress_ROI CSFe 							\
		-regress_censor_outliers 0.1                                    	\
		-regress_motion_per_run                                         	\
		-regress_censor_motion 0.6                                      	\
		-regress_bandpass 0.01 0.1                                      	\
		-regress_apply_mot_types demean deriv                           	\
		-regress_run_clustsim no                                        	\
		-regress_est_blur_errts                                         	\
		-execute
	      

		  # compress brik files
        	cd PROC.RST
        	gzip -v *BRIK
 
end

exit

