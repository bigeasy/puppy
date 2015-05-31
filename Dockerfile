FROM ubuntu

MAINTAINER Alan Gutierrez, alan@prettyrobots.com

RUN apt-get update && apt-get -y upgrade && apt-get -y autoremove

COPY ./ /usr/local/share/puppy/
