FROM amazonlinux:2


ENV TERRAFORM_VERSION "0.14.8"
# CLI utilities
RUN yum install -y gcc git make awscli unzip wget zip

RUN yum install -y python3-devel

ADD requirements.txt /requirements/

# Python 3 code dependencies
RUN pip3 install -r /requirements/requirements.txt

RUN yum install -y awscli

RUN wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && \
    unzip *.zip && \
    chmod +x terraform && \
    mv terraform /usr/local/bin

WORKDIR /Buen-Aire-Backend