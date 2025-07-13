FROM centos:6

RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Base.repo && \
    sed -i 's|#baseurl=http://mirror.centos.org/centos/$releasever|baseurl=http://vault.centos.org/6.10|g' /etc/yum.repos.d/CentOS-Base.repo

RUN yum update -y && \
    yum groupinstall -y "Development Tools" && \
    yum install -y wget tar bzip2 zlib-devel openssl-devel readline-devel sqlite-devel && \
    yum clean all

RUN gcc --version && g++ --version

RUN wget https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz && \
    tar -xzf Python-2.7.18.tgz && \
    cd Python-2.7.18 && \
    ./configure --prefix=/usr/local/python2.7 --enable-shared && \
    make && \
    make install && \
    cd / && \
    rm -rf Python-2.7.18.tgz Python-2.7.18

RUN echo "/usr/local/python2.7/lib" > /etc/ld.so.conf.d/python2.7.conf && \
    ldconfig

ENV PATH="/usr/local/python2.7/bin:${PATH}"
ENV PYTHONPATH="/usr/local/python2.7/lib/python2.7/site-packages:${PYTHONPATH}"
ENV LD_LIBRARY_PATH="/usr/local/python2.7/lib:${LD_LIBRARY_PATH}"

RUN python -c "print('Python works!')"

RUN yum install -y perl && \
    yum clean all
RUN perl --version

RUN yum update -y && \
    yum groupinstall -y "Development Tools" && \
    yum install -y wget tar bzip2 zlib-devel openssl-devel readline-devel sqlite-devel swig && \
    yum clean all
