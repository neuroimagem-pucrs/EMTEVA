#!/bin/bash

###################################################
### SOMENTE EDITAR ESTA PARTE PARA CADA SUJEITO ###
###################################################

study=VIVA
subj=$1
visit=visit1

#####################################
# ALTERE AQUI SOMENTE SE NECESSÁRIO #
#####################################

# get out of script folder
cd ../../../

# go inside subject folder
cd ${study}${subj}
cd ${visit}

#go inside dicom folder
#check if dicom directory exist inside subject folder
if [ ! -d "dicom" ]; then
	printf "\n#########################################################\n"
	printf "# Não foi encontrado diretório dicom em ${study}${subj}/${visit}. #\n"
	printf "#########################################################\n\n"
	exit 1
else
	cd dicom
	dicom_dir=`pwd` #IMPORTANTE
fi

cd ..

#############################################################
########### ALTERE AQUI DE ACORDO COM O PROJETO!  ###########
#####                                                   #####
##### É NECESSÁRIO QUE UM ELEMENTO CORRESPONDA AO OUTRO #####
##### E OBRIGATORIAMENTE POSSUAM A MESMA QUANTIDADE DE  #####
##### ELEMENTOS.                                        #####
##### EX: pastas=("ANAT" "RST" ...)                     #####
#####     series=("AXI3DFSPGRBRAVO" "FMRI" ...)         #####
##### O vetor 'series' vai depender de como for a saída #####
##### do dmcget. VERIFIQUE ISSO ANTES DE EXECUTAR! UMA  #####
##### VEZ CORRETO, NÃO É MAIS NECESSÁRIO MEXER AQUI.    #####
#####                                                   #####
##### O SCRIPT AVISARÁ SE EXISTEM EXAMES FALTANDO OU SE #####
##### HÁ EXAMES REPETIDOS E PEGARÁ SEMPRE O MAIS RECEN- #####
##### TE ENTRE ELES.                                    #####
#####                                                   #####
########### ALTERE AQUI DE ACORDO COM O PROJETO! ############
#############################################################


pastas=("ANAT" "CHANGE" "FALMEM" "RMET1" "RMET2" "RST" "FLAIR")
series=("AXI3DFSPGRBRAVO" "CHANGE" "FALSE_MEM" "FMRIRMETI" "FMRIRMETII" "FMRIRST" "SFlairCube")




#########################################################
########### NÃO MEXA EM NADA A PARTIR DAQUI! ############
#########################################################

if [ "${#pastas[@]}" -ne "${#series[@]}" ]; then
    echo "###########################################"
    echo "# Os vetores 'pastas' e 'series' precisam #"
    echo "# conter a mesma quantidade de elementos. #"
    echo "#              Verifique!                 #"
    echo "###########################################"
    exit 1
fi

for (( i = 0 ; i < ${#series[@]} ; i++ ))
do
	cd ${dicom_dir}
	if [[ $(ls -d "${series[$i]}_"* 2>/dev/null | wc -l) > 1 ]]; then
		printf "\n	EXISTEM EXAMES REPETIDOS:\n"
                for folder in $(ls -d "${series[$i]}_"* 2>/dev/null)
                do
                        printf "	%s\n" "${folder}"
                done
        	printf "\n#########################################\n"
		printf "# Será usado:				#\n"
		printf "# $(ls -d "${series[$i]}_"* 2>/dev/null | tail -1).		#\n"
		printf "#########################################\n"
        fi
	cd ..
done

function check_series_dir() {
	series_dir=("$@")
	for (( i = 0 ; i < ${#series_dir[@]} ; i++ ))
	do
		if [[ $(ls -ld "${dicom_dir}/${series_dir[$i]}_"* 2>/dev/null | tail -1 | cut -c1) == 'd' ]]; then
			printf "\n##################################\n"
			printf "## CRIANDO DIRETÓRIO ${pastas[$i]}	##\n"
			printf "## E CONVERTENDO PARA NIFTI	##\n"
			printf "##################################\n"
			mkdir -v ${pastas[$i]}
			cd ${pastas[$i]}
			dcm2nii -c -g -o . $(ls -d "${dicom_dir}/${series_dir[$i]}_"* 2>/dev/null | tail -1)/*
			mv -v 2*nii* ${study}${subj}.${pastas[$i]}.nii.gz
			cd ..
		else
			printf "\n#################################################\n"
			printf "##  Não foi encontrado o diretório ${series_dir[$i]}	#\n"
			printf "#################################################\n"
		fi
	done

	# Removing junk files
	rm -v *ANAT*/co* 2>/dev/null
	rm -v *ANAT*/o* 2>/dev/null
	# Renaming DTI bval and bvec
	mv -v *DTI*/2*bval DTI/${study}${subj}.DTI.bval 2>/dev/null
	mv -v *DTI*/2*bvec DTI/${study}${subj}.DTI.bvec 2>/dev/null
	# Now we can compact the dicom folder
	echo "####################################"
	echo "# Compactando o diretório dicom... #"
	echo "####################################"
	echo
	echo Aguarde...
	echo
	tar -zcf dicom.tar.gz dicom
	# Now we can delete the original dicom folder
	echo "##################################"
	echo "# Removendo o diretório dicom... #"
	echo "##################################"
	rm -rf dicom/
	echo
	echo "##############"
	echo "# Concluído. #"
	echo "##############"
}

check_series_dir "${series[@]}"
