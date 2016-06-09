#
# Apache Spark + Jupyter Dockerfile 
#

# Pull base image
FROM java:8

ENV SCALA_VERSION 2.11.8
ENV SBT_VERSION 0.13.11

# Install Scala
## Piping curl directly in tar
RUN \
  curl -fsL http://downloads.typesafe.com/scala/$SCALA_VERSION/scala-$SCALA_VERSION.tgz | tar xfz - -C /root/ && \
  echo >> /root/.bashrc && \
  echo 'export PATH=~/scala-$SCALA_VERSION/bin:$PATH' >> /root/.bashrc

# Install sbt
RUN \
  curl -L -o sbt-$SBT_VERSION.deb http://dl.bintray.com/sbt/debian/sbt-$SBT_VERSION.deb && \
  dpkg -i sbt-$SBT_VERSION.deb && \
  rm sbt-$SBT_VERSION.deb && \
  apt-get update && \
  apt-get install sbt && \
  sbt sbtVersion

# Install Anaconda 
RUN apt-get update --fix-missing && apt-get install -y wget bzip2 ca-certificates \
    libglib2.0-0 libxext6 libsm6 libxrender1 \
    git mercurial subversion

RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.continuum.io/archive/Anaconda3-4.0.0-Linux-x86_64.sh && \
    /bin/bash /Anaconda3-4.0.0-Linux-x86_64.sh -b -p /opt/conda && \
    rm /Anaconda3-4.0.0-Linux-x86_64.sh

#RUN apt-get install -y curl grep sed dpkg && \
#    TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
#    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
#    dpkg -i tini.deb && \
#    rm tini.deb && \
#    apt-get clean

RUN apt-get update && apt-get install -y supervisor

RUN mkdir -p /var/run/jupyter /var/log/supervisor

# Install Scala Juypter kernel 
RUN curl -L -o jupyter-scala https://git.io/vrHhi && chmod +x jupyter-scala && ./jupyter-scala && rm -f jupyter-scala

# Compile Spark Jupyter support
RUN git clone https://github.com/zackangelo/ammonium.git && \
		cd ammonium && \
		git reset --hard fbba2d9e819304f0917195f29db9bcca33712cf0 && \
		sbt -Dsbt.version=$SBT_VERSION publishLocal < /dev/null

RUN curl -fsL http://d3kbcqa49mib13.cloudfront.net/spark-2.0.0-preview.tgz | tar xfz - -C /root/ && \ 
		cd /root/spark-2.0.0-preview \ 
		sbt -Dsbt.version=$SBT_VERSION package 

COPY SparkTest.ipynb /root/SparkTest.ipynb

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ENV PATH /opt/conda/bin:$PATH

ENV LANG C.UTF-8

# Define working directory
WORKDIR /root

EXPOSE 8888

CMD ["/usr/bin/supervisord"]