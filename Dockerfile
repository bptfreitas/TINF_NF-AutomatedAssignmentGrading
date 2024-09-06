FROM httpd:2.4-bullseye AS build

WORKDIR /

FROM httpd:2.4-bullseye

RUN apt update

RUN apt install -y git sudo

WORKDIR /

RUN rm /var/www/html/index.html

COPY @BASE_REPOSITORY@ /root/.

COPY @STUDENT_REPOSITORY@/trabalho.sh /root/@BASE_REPOSITORY@/trabalho.sh

# EXPOSE 80

CMD [ "/usr/sbin/apache2ctl" , "start" ]
