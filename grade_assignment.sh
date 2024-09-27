#!/bin/bash

debug=1

student_number=0

gradefile=grades.dat

assignments_dir="works"
student_log_dir="logs"
assignment_name="grading"

while [[ $# -gt 0 ]]; do

	key="$1"

	case $key in
		--output-dir|-o)
		assignments_dir="$2"
		
		if [[ "${assignments_dir}" == "" ]]; then
			echo "ERROR: empty assignment dir"!
			exit -1
		fi
		
		shift # past argument
		shift # past value
		;;
		
		--assignment-name|-a)
		assignment_name="$2"
		
		if [[ "${assignment_name}" == "" ]]; then
			echo "ERROR: empty work name!"
			exit -1
		fi
		
		shift # past argument
		shift # past value
		;;		

		*)    # unknown option
		POSITIONAL+=("$1") # save it in an array for later
		shift # past argument
		;;
	esac
done

logfile="${assignment_name}.log"

if [[ ! -d "${assignments_dir}" ]]; then
	rm -rf "${assignments_dir}"
fi

mkdir -p "${assignments_dir}"

cp Dockerfile "${assignments_dir}/Dockerfile_base"

if [[ $debug -eq 1 ]]; then

	echo "[DEBUG] Creating test file..."
	
	echo "https://github.com/bptfreitas/TINF_NF_Template-UsuariosGruposPermissoes.git" \
		>> test_repositories.txt
		
	mv test_repositories.txt "${assignments_dir}/main_repository.txt"
	
	echo "NOME COMPLETO; REPOSITORIO" > test_repositories.txt
		
	echo "ALUNO ERRADO; https://github.com/bptfreitas/TINF_NF_ALUNO-UsuariosGruposPermissoes.git" \
		>> test_repositories.txt
		
	mv test_repositories.txt "${assignments_dir}/student_repositories.txt"
	
	image_name="grading-dev"

else

	echo "Copying main repository ..."
	
	cp main_repository.txt "${assignments_dir}/."

	echo "Copying student repositories ..."

	cp student_repositories.txt "${assignments_dir}/."
	
fi

cd "${assignments_dir}"

mkdir logs

cp ../grade_student.sh .

> $logfile

> $gradefile

repo="`cat main_repository.txt`"

echo "Cloning base repository ..."

base_repo=`basename $repo .git`
		
git clone $repo 1>> $logfile 2>&1

if [[ ! -d "$base_repo" ]]; then
	echo -e "[ERROR] Base repository '$base_repo' could not be cloned!\nAborting" | tee -a $logfile
	exit -1
fi

student_number=0

echo "Base repository: $base_repo" | tee -a $logfile

while read work; do

	[[ $debug -eq 1 ]] && echo "[DEBUG] Work: $work"
	
	if [[ $student_number -eq 0 ]]; then
	
		echo "Header line, skipping" | tee -a $logfile
		
		student_number=$((student_number+1))	
		continue
	fi
		
	name="`echo "$work" | cut -f1 -d';' | sed 'y/ÃẼĨÕŨ/AEIOU/'`"
	
	repo="`echo "$work" | cut -f2 -d';'`"
	
	# formatting name for the image tag and folder
	fmt_name="`echo $name | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g'`"
	
	first_name=`echo $name | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]' `
	last_name=`echo $name | awk -F' ' '{ print $NF }' | tr '[:upper:]' '[:lower:]'`
	
	tag="${first_name}-${last_name}"
	
	student_repo="${student_number}_${tag}"
				
	echo "[$(( student_number ))] Student: $name" | tee -a $logfile
		
	echo "Cloning student repository: $repo" | tee -a $logfile
	
	git clone $repo "$student_repo" 1>> $logfile 2>&1 | tee -a $logfile
			
	# student_repo="`basename $repo .git`"
	
	if [[ ! -d "${student_repo}" ]]; then
		echo "[WARN] $name's repository $repo could not be cloned! Skipping..." | tee -a $logfile
		continue
	fi
	
	sed "s/@BASE_REPOSITORY@/${base_repo//\//\\\/}/g" Dockerfile_base > Dockerfile_base.1
	
	sed "s/@STUDENT_REPOSITORY@/${student_repo//\//\\\/}/g" Dockerfile_base.1 > Dockerfile_base.2
	
	mv Dockerfile_base.2 Dockerfile
	
	# formatting name for the image tag 
	fmt_name="`echo $name | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g' | sed -i 'y/ÃẼĨÕŨ/AEIOU/'`"
	
	first_name=`echo $name | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]' `
	last_name=`echo $name | awk -F' ' '{ print $NF }' | tr '[:upper:]' '[:lower:]'`
	
	tag="${first_name}-${last_name}"
	
	echo "Tag: $tag" | tee -a $logfile
	
	student_log="${student_repo}/$tag.log"
	
	# Running container
	
	sudo docker rm ${assignment_name}:${tag} | tee -a $logfile
	
	sudo docker build -t ${assignment_name}:${tag} . | tee -a $logfile
	
	sudo docker run --stop-timeout 60 ${assignment_name}:${tag} | tee -a $student_log
	
	nota=`tail -1 $logfile | grep -E -o '[0-9]+\.[0-9]+'`
	
	echo "$name: $nota"	| tee -a ./$gradefile
	
	# container_id="`sudo docker ps -a | grep 'grading:$tag' | awk '{ print $1 } '`"
		
	# echo "ID: $container_id"
	
	# sudo docker exec $container_id "/root/${base_repo}/trabalho.sh" 
	
	student_number=$((student_number+1))
	
done < student_repositories.txt

