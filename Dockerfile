FROM ubuntu:latest

RUN apt update

RUN apt install -y git sudo gcc make

WORKDIR /

COPY @BASE_REPOSITORY@ /root/.

COPY @STUDENT_REPOSITORY@/trabalho.sh /root/@BASE_REPOSITORY@/trabalho.sh

COPY ./grade_student.sh /root/@BASE_REPOSITORY@/grade_student.sh

RUN chmod +x /root/@BASE_REPOSITORY@/trabalho.sh

RUN chmod +x /root/@BASE_REPOSITORY@/grade_student.sh

# EXPOSE 80

CMD [ "/root/@BASE_REPOSITORY@/grade_student.sh" ]
