## code-server: https://github.com/cdr/code-server
## docker-code-server: https://github.com/linuxserver/docker-code-server

## 17-09-2021: code-server 3.12.0 - VS Code 1.60 : unable to launch C++ debugger
#FROM ghcr.io/linuxserver/code-server:version-v3.12.0
# VS Code 1.57.1
FROM ghcr.io/linuxserver/code-server:version-v3.11.1

## Do not start as a service
RUN rm -r /etc/services.d/code-server

## We need add-apt-repository
RUN apt-get update && \
    apt-get -y install software-properties-common

# Setup c++ development

## gcc-11
## From https://launchpad.net/~ubuntu-toolchain-r/+archive/ubuntu/test
RUN add-apt-repository ppa:ubuntu-toolchain-r/test
RUN apt-get update
RUN apt-get install -y gcc-11 g++-11

RUN update-alternatives \
  --install /usr/bin/gcc                 gcc                  /usr/bin/gcc-11     100 \
  --slave   /usr/bin/g++                 g++                  /usr/bin/g++-11

RUN update-alternatives \
  --install /usr/bin/c++                 c++                  /usr/bin/g++        100

## Will install gcc-7
# RUN apt-get install -y cmake
RUN curl -L -o /tmp/cmake-3.21.2-linux-x86_64.tar.gz https://github.com/Kitware/CMake/releases/download/v3.21.2/cmake-3.21.2-linux-x86_64.tar.gz
RUN tar --directory=/usr --strip-components=1 -xzf /tmp/cmake-3.21.2-linux-x86_64.tar.gz
RUN rm /tmp/cmake-3.21.2-linux-x86_64.tar.gz

## USE ONLY g++
# clang-13
# From https://apt.llvm.org
#RUN bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"

## USE ONLY g++
# llvm 12.0.1 https://github.com/llvm/llvm-project/releases
# it includes libc++ (apt.llvm.org does not)
# RUN wget https://github.com/llvm/llvm-project/releases/download/llvmorg-12.0.1/clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu-16.04.tar.xz
# RUN tar --directory=/usr/local --strip-components=1 -xJf clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu-16.04.tar.xz
# RUN rm clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu-16.04.tar.xz

## Other tools and libs
RUN apt-get install -y gdb \
                       googletest \
                       libboost-dev \
                       make \
                       wget

## Build googletest with installed compiler
RUN mkdir -p /tmp/gtest
WORKDIR /tmp/gtest
RUN cmake /usr/src/googletest/googletest
RUN make install
WORKDIR /
RUN rm -r /tmp/gtest

# Package libtbb-dev is too old for parallel C++ algorithms
RUN wget -O /tmp/oneapi-tbb.tgz https://github.com/oneapi-src/oneTBB/releases/download/v2021.3.0/oneapi-tbb-2021.3.0-lin.tgz
RUN tar zxf /tmp/oneapi-tbb.tgz --directory=/opt
RUN rm /tmp/oneapi-tbb.tgz
RUN mv /opt/oneapi-tbb-2021.3.0 /opt/tbb

# Install VSCode extensions
RUN code-server --extensions-dir /config/extensions --install-extension ms-vscode.cpptools
## 1.6.0 for VS Code 1.58.0 or later
#RUN curl -L -o /tmp/cpptools-linux.vsix https://github.com/microsoft/vscode-cpptools/releases/download/1.6.0/cpptools-linux.vsix
## 1.5.1 for VS Code 1.53.0 or later
RUN curl -L -o /tmp/cpptools-linux.vsix https://github.com/microsoft/vscode-cpptools/releases/download/1.5.1/cpptools-linux.vsix
RUN code-server --extensions-dir /config/extensions --install-extension /tmp/cpptools-linux.vsix
RUN rm /tmp/cpptools-linux.vsix

# Update to zsh shell
RUN sudo apt-get install -y zsh
RUN sudo sed -i -e "s#bin/bash#bin/zsh#" /etc/passwd

# Install on-my-zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
RUN git clone --branch master --single-branch --depth 1 \
        "git://github.com/zsh-users/zsh-autosuggestions" \
        /config/.oh-my-zsh/plugins/zsh-autosuggestions
RUN echo "source /config/.oh-my-zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" \ 
        >> /config/.zshrc
RUN git clone --branch master --single-branch --depth 1 \
        "git://github.com/zsh-users/zsh-syntax-highlighting.git" \
        /config/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
RUN sed -i 's/plugins=(.*/plugins=(git vscode)/' /config/.zshrc

RUN echo source /opt/tbb/env/vars.sh          >>/config/.zshrc
RUN mkdir -p /config/workspace/.vscode
COPY c_cpp_properties.json /config/workspace/.vscode/
COPY            tasks.json /config/workspace/.vscode/
COPY           launch.json /config/workspace/.vscode/
RUN mkdir -p /config/data/User/state/
COPY         settings.json /config/data/User/
COPY         global.json /config/data/User/state/

# /config will be a docker volume, initially empty
# wrapper_script will do the copy
RUN mv /config /init-config
# But it must exist at startup (TODO: is it true ?)
RUN mkdir /config

# Will be entry point
COPY wrapper_script.sh /usr/local/lib/wrapper_script.sh

# launch
ENTRYPOINT ["/bin/bash", "/usr/local/lib/wrapper_script.sh"]
