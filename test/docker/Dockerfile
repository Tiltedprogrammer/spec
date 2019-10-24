FROM nvidia/cuda:10.0-devel-ubuntu18.04

RUN apt update && \
    apt install -y wget nano python3 unzip  git cmake python3-pip build-essential


RUN apt-get install subversion -y


RUN cd home && git clone https://github.com/AnyDSL/anydsl.git


ADD config.sh /home/anydsl

ENV LD_LIBRARY_PATH=/usr/local/cuda/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

RUN cd home/anydsl && ./setup.sh

WORKDIR /home



