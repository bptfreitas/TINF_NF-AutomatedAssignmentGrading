FROM ubuntu:latest

RUN apt update

RUN apt install -y git sudo gcc make

WORKDIR /

COPY @BASE_REPOSITORY@/ /root/@BASE_REPOSITORY@/

WORKDIR /root/@BASE_REPOSITORY@/

ENV PATH="$PATH:/usr/games"

COPY ./grade_student.sh /root/@BASE_REPOSITORY@/grade_student.sh

COPY @STUDENT_REPOSITORY@/trabalho.sh /root/@BASE_REPOSITORY@/trabalho.sh

RUN chmod +x ./grade_student.sh

RUN chmod +x ./corretor

RUN chmod +x ./trabalho.sh

# EXPOSE 80

CMD [ "./grade_student.sh" ]

# CMD [ "ls" ]
