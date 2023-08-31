# Container image that runs your code
FROM alpine:3.14.2

COPY entrypoint.sh /entrypoint.sh
COPY resultParser.py /resultParser.py

ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache python3 && ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools
RUN apk add --no-cache --virtual .pynacl_deps build-base python3-dev libffi-dev
RUN pip3 install click==8.0.1 requests==2.25.1 click-option-group==0.5.3 zipp==3.4.1 prettytable==2.1.0 py7zr==0.20.2 pyyaml==6.0.1 gzinfo==1.0.2 cryptography==38.0.3
RUN pip3 install Qualys-IaC-Security --no-deps
RUN apk add git

RUN ["chmod", "+x", "/entrypoint.sh"]

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["sh","/entrypoint.sh"]
