#FROM python:3.11-slim
FROM python:3.13-slim

MAINTAINER Michel Raabe <raabe@b1-systems.de>

LABEL builder="B1 Systems GmbH"
LABEL quay.expires-after="1y"

ENV DEBIAN_FRONTEND="noninteractive"

RUN apt-get update && \
    apt-get install --yes sudo vim git-core build-essential && \
    apt clean && \
    python3 -m pip --no-cache-dir install --upgrade pip setuptools

RUN useradd -m rally && \
    usermod -aG sudo rally && \
    echo "rally ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/00-rally-user

RUN mkdir -p /etc/rally && \
    echo "[database]" > /etc/rally/rally.conf && \
    echo "connection=sqlite:////home/rally/.rally/rally.db" >> /etc/rally/rally.conf

USER rally
ENV HOME /home/rally
ENV PATH="$PATH:/home/rally/.local/bin"

WORKDIR /home/rally

RUN git clone -b 5.0.1 https://github.com/openstack/rally.git source && \
    git clone -b 4.1.0 https://github.com/openstack/rally-openstack.git source-openstack

WORKDIR /home/rally/source
RUN pip install . --no-cache-dir && \
    pip install pymysql psycopg2-binary fixtures

WORKDIR /home/rally/source-openstack
RUN pip install . --no-cache-dir

COPY --chown=rally:rally rally-openstack-tests /home/rally/
COPY --chown=rally:rally entrypoint.sh /home/rally/entrypoint.sh

WORKDIR /home/rally/
RUN mkdir .rally && \
    chmod +x entrypoint.sh

# DB and environment are not created at build time, since the image is
# meant to be generic and reused against different target clouds. Instead
# entrypoint.sh creates them on first start against whatever envfile is
# mounted into the container at runtime.
ENTRYPOINT ["/home/rally/entrypoint.sh"]
