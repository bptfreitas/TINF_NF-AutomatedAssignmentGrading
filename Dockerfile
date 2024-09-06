FROM httpd:2.4-bullseye AS build

WORKDIR /

FROM httpd:2.4-bullseye

RUN apt update

RUN apt install -y git sudo gcc make

WORKDIR /

COPY @BASE_REPOSITORY@ /root/.

COPY @STUDENT_REPOSITORY@/trabalho.sh /root/@BASE_REPOSITORY@/trabalho.sh

RUN chmod +x /root/@BASE_REPOSITORY@/trabalho.sh

# EXPOSE 80

# CMD [ "/usr/sbin/apache2ctl" , "start" ]
