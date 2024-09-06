#!/bin/bash

debug=1

student_number=0

logfile=grade.log

mkdir -p works

cp Dockerfile works/Dockerfile_base

if [[ $debug -eq 1 ]]; then
	echo "[DEBUG] Creating test file..."
	
	echo "NOME COMPLETO; REPOSITORIO" > test_repositories.txt
	
	echo "PROF; https://github.com/bptfreitas/TINF_NF_Template-UsuariosGruposPermissoes" \
		>> test_repositories.txt
		
	echo "ALUNO; https://github.com/bptfreitas/TINF_NF_Aluno_ArquivosRedirecionamentos.git" \
		>> test_repositories.txt
		
	mv test_repositories.txt works/student_repositories.txt

else

	echo "Copying student repositories ..."

	cp student_repositories.txt works/.

fi

cd works

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
	
		# first line is the base assignment repository
	
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
	
	sed "s/@BASE_REPOSITORY@/${base_repo//\//\\\/}/" Dockerfile_base > Dockerfile_base.1
	
	sed "s/@STUDENT_REPOSITORY@/${student_repo//\//\\\/}/" Dockerfile_base.1 > Dockerfile_base.2
	
	mv Dockerfile_base.2 Dockerfile
	
	# Running container
	
	sudo docker rm grading
	
	sudo docker build -t grading .
	
	container_id=`sudo docker run -d grading:latest`
	
	echo "ID: $container_id"
	
	sudo docker exec $container_id "/root/${base_repo}/trabalho.sh" 
	
	student_number=$((student_number+1))
	
done < student_repositories.txt

