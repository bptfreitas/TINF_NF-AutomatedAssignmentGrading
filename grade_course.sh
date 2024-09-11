#!/bin/bash

debug=1

student_number=0

logfile=grade.log

mkdir -p works

cp Dockerfile works/Dockerfile_base

if [[ $debug -eq 1 ]]; then

	echo "[DEBUG] Creating test file..."
	
	echo "NOME COMPLETO; REPOSITORIO" > test_repositories.txt
	
	echo "PROFESSOR; https://github.com/bptfreitas/TINF_NF_Template-UsuariosGruposPermissoes.git" \
		>> test_repositories.txt
		
	echo "NOME DE UM ALUNO; https://github.com/bptfreitas/TINF_NF_ALUNO-UsuariosGruposPermissoes.git" \
		>> test_repositories.txt
		
	mv test_repositories.txt works/student_repositories.txt
	
	image_name="grading-dev"

else

	echo "Copying student repositories ..."

	cp student_repositories.txt works/.

fi

cd works

cp ../grade_student.sh .

> $logfile

base_repo=""

while read work; do

	[[ $debug -eq 1 ]] && echo "[DEBUG] Work: $work"
	
	if [[ $student_number -eq 0 ]]; then
	
		echo "Header line, skipping"
		
		student_number=$((student_number+1))		
		continue
	fi
		
	name="`echo "$work" | cut -f1 -d';'`"
	
	repo="`echo "$work" | cut -f2 -d';'`"
	
	if [[ $student_number -eq 1 ]]; then
	
		# first line clones the base assignment repository
	
		echo "Cloning base repository ..."
		
		git clone $repo 1> $logfile 2>&1 
		
		base_repo=`basename $repo .git`
		
		[[ $debug -eq 1 ]] && echo "[DEBUG] base_repo: $base_repo"								
		
		student_number=$((student_number+1))		
		continue
	fi		
	
	
	echo "[$(( student_number -1))] Student: $name"
		
	echo "Cloning student repository: $repo"
	
	git clone $repo 1> $logfile 2>&1 
	
	student_repo=`basename $repo .git`
	
	sed "s/@BASE_REPOSITORY@/${base_repo//\//\\\/}/g" Dockerfile_base > Dockerfile_base.1
	
	sed "s/@STUDENT_REPOSITORY@/${student_repo//\//\\\/}/g" Dockerfile_base.1 > Dockerfile_base.2
	
	mv Dockerfile_base.2 Dockerfile
	
	# formatting name for the image tag 
	fmt_name="`echo $name | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g'`"
	
	first_name=`echo $name | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]' `
	last_name=`echo $name | awk -F' ' '{ print $NF }' | tr '[:upper:]' '[:lower:]'`
	
	tag="${first_name}-${last_name}"
	
	echo "Tag: $tag"
	
	# Running container
	
	sudo docker rm grading:$tag
	
	sudo docker build -t grading:$tag .
	
	sudo docker run grading:$tag # >> $logfile
	
	nota=`tail -1 $logfile | grep '[0-9]{1,2}\.[0-9]'`
	
	echo "$name: $nota"		
	
	# container_id="`sudo docker ps -a | grep 'grading:$tag' | awk '{ print $1 } '`"
		
	# echo "ID: $container_id"
	
	# sudo docker exec $container_id "/root/${base_repo}/trabalho.sh" 
	
	student_number=$((student_number+1))
	
done < student_repositories.txt

