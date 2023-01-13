FROM ubuntu:20.04

RUN set -e

WORKDIR /tmp
ENV DEBIAN_FRONTEND=noninteractive

# Install packages
RUN apt-get -y update  &&\
    apt-get install -y\
        cargo\
        cmake\
        python3\
        python3-pip\
        g++\
        gcc\
        git\
        gnupg\
        lsb-release\
        make\
        openjdk-17-jdk\
        software-properties-common\
        time\
        valgrind\
        wget

# Install LLVM 14
RUN wget https://apt.llvm.org/llvm.sh && chmod +x llvm.sh && ./llvm.sh 14 &&\
    ln -s /usr/bin/clang-14 /usr/bin/clang &&\
    ln -s /usr/bin/clang++-14 /usr/bin/clang++ &&\
    ln -s /usr/bin/llvm-link-14 /usr/bin/llvm-link &&\
    ln -s /usr/bin/llvm-config-14 /usr/bin/llvm-config &&\
    ln -s /usr/bin/opt-14 /usr/bin/opt

# clone VAMOS
WORKDIR /opt
RUN git clone https://github.com/ista-vamos/vamos -b main
WORKDIR /opt/vamos

# compile DynamoRIO and then VAMOS
RUN make sources-init && make -j4 -C vamos-sources/ext dynamorio BUILD_TYPE=RelWithDebInfo
RUN make -j4

# copy the experiments
COPY . /opt/vamos/fase23-experiments
RUN make fase23-experiments
WORKDIR /opt/vamos/fase23-experiments

# Packages for generating plots
RUN pip install -r plots/scripts/requirements.txt && mkdir /opt/results

# for some reason we cannot install TSan normally
RUN mkdir -p /usr/lib/llvm-14/lib/clang/14.0.6/lib/linux/ &&\
    cp dataraces/libclang_rt.tsan-x86_64.a /usr/lib/llvm-14/lib/clang/14.0.6/lib/linux/libclang_rt.tsan-x86_64.a

