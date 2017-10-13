#!/bin/bash

###################################################
### SOMENTE EDITAR ESTA PARTE PARA CADA SUJEITO ###
###################################################

study=EMT
subj=$1
#visit=visit1


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


pastas=("ANAT" "RST")
series=("AXI3DFSPGRBRAVO" "FMRIRST")

#####################################
# ALTERE AQUI SOMENTE SE NECESSÁRIO #
#####################################

# get out of script folder
cd ../../

# go inside subject folder
cd ${study}${subj}
#cd ${visit}

tar -zxvf *.tar.gz

# ter acesso aos arquivos
chmod -R ug+rw *

#go inside dicom folder
#check if dicom directory exist inside subject folder
if [ ! -d "scans" ]; then
	printf "\n#########################################################\n"
	printf "# Não foi encontrado diretório dicom em ${study}${subj}/${visit}. #\n"
	printf "#########################################################\n\n"
	exit 1
else
	cd scans
	dicom_dir=`pwd` #IMPORTANTE
fi

# list directories inside "scans"
scan_dir=($(ls -d */))

for (( i = 0 ; i < ${#scan_dir[@]} ; i++ ))
do

	#dicomscan_dir=$dicom_dir/${scan_dir[$i]}
#	echo $dicomscan_dir
	dcm_name=`find ${scan_dir[$i]} -type f -print -quit`
        series_name=`dcmdump +P 0008,103E "$dcm_name" +L | cut -f 2 -d '[' | cut -f 1 -d ']' |  sed 's/ //g'`
        mv ${scan_dir[$i]} $series_name


done



cd ..



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
	if [[ $(ls -d "${series[$i]}"* 2>/dev/null | wc -l) > 1 ]]; then
		printf "\n	EXISTEM EXAMES REPETIDOS:\n"
                for folder in $(ls -d "${series[$i]}"* 2>/dev/null)
                do
                        printf "	%s\n" "${folder}"
                done
        	printf "\n#########################################\n"
		printf "# Será usado:				#\n"
		printf "# $(ls -d "${series[$i]}"* 2>/dev/null | tail -1).		#\n"
		printf "#########################################\n"
        fi
	cd ..
done

function check_series_dir() {
	series_dir=("$@")
	for (( i = 0 ; i < ${#series_dir[@]} ; i++ ))
	do
#		if [[ $(ls -ld "${dicom_dir}/${series_dir[$i]}_"* 2>/dev/null | tail -1 | cut -c1) == 'd' ]]; then
		if [[ $(ls -ld "${dicom_dir}/${series_dir[$i]}"* 2>/dev/null | tail -1 | cut -c1) == 'd' ]]; then
			printf "\n##################################\n"
			printf "## CRIANDO DIRETÓRIO ${pastas[$i]}	##\n"
			printf "## E CONVERTENDO PARA NIFTI	##\n"
			printf "##################################\n"
			mkdir -v ${pastas[$i]}
			cd ${pastas[$i]}
			dcm2nii -c -g -o . $(ls -d "${dicom_dir}/${series_dir[$i]}"* 2>/dev/null | tail -1)/*
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
#	mv -v *DTI*/2*bval DTI/${study}${subj}.DTI.bval 2>/dev/null
#	mv -v *DTI*/2*bvec DTI/${study}${subj}.DTI.bvec 2>/dev/null
	# Now we can compact the dicom folder
#	echo "####################################"
#	echo "# Compactando o diretório dicom... #"
#	echo "####################################"
#	echo
#	echo Aguarde...
#	echo
#	tar -zcf dicom.tar.gz dicom
	# Now we can delete the original dicom folder
	echo "##################################"
	echo "# Removendo o diretório dicom... #"
	echo "##################################"
	rm -rf scans/
	echo
	echo "##############"
	echo "# Concluído. #"
	echo "##############"
}

check_series_dir "${series[@]}"
