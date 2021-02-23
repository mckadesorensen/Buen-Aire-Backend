FROM amazonlinux:2

# CLI utilities
RUN yum install -y gcc git make awscli

RUN yum install -y python3-devel

ADD requirements.txt /requirements/

# Python 3 code dependencies
RUN pip3 install -r /requirements/requirements.txt

WORKDIR /Buen-Aire-Backend