# code-server: https://github.com/cdr/code-server
# docker-code-server: https://github.com/linuxserver/docker-code-server

# 30-08-2021: VS Code 1.57.1 (latest version is 1.59.0)
FROM ghcr.io/linuxserver/code-server:latest

# Do not start as a service
RUN rm -r /etc/services.d/code-server

# First install needed tools
RUN apt-get update && \
    apt-get -y install lsb-release \
                       software-properties-common \
                       cmake \
                       curl \
                       git \
                       sudo \
                       wget

# Setup c++ development

## # USE ONLY clang++
## # gcc-11
## # From https://launchpad.net/~ubuntu-toolchain-r/+archive/ubuntu/test
## RUN add-apt-repository ppa:ubuntu-toolchain-r/test
## RUN apt-get update
## RUN apt-get install -y gcc-11 g++-11

# clang-13
# From https://apt.llvm.org
RUN bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"

# Other tools and libs
RUN apt-get install -y gdb \
                       googletest \
                       libboost-dev

# Package libtbb-dev is too old for parallel C++ algorithms
RUN wget -O /tmp/oneapi-tbb.tgz https://github.com/oneapi-src/oneTBB/releases/download/v2021.3.0/oneapi-tbb-2021.3.0-lin.tgz
RUN tar zxf /tmp/oneapi-tbb.tgz --directory=/opt
RUN rm /tmp/oneapi-tbb.tgz
RUN mv /opt/oneapi-tbb-2021.3.0 /opt/tbb

# Install VSCode extensions
RUN code-server --extensions-dir /config/extensions --install-extension ms-vscode.cpptools
# 30-08-2021: 1.6.0 needs VS Code 1.58.0 or later
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

# Default c++20

## # USE ONLY clang++
## # /usr/bin/g++ is a direct link to /usr/bin/g++-7
## RUN rm /usr/bin/g++
## RUN update-alternatives \
##   --install /usr/bin/gcc                 gcc                  /usr/bin/gcc-11     10 \
##   --slave   /usr/bin/g++                 g++                  /usr/bin/g++-11
## RUN update-alternatives \
##   --install /usr/bin/gcc                 gcc                  /usr/bin/gcc-7       5 \
##   --slave   /usr/bin/g++                 g++                  /usr/bin/g++-7

RUN update-alternatives \
  --install /usr/bin/c++                   c++                    /usr/bin/clang++-13   100

RUN update-alternatives \
  --install /usr/bin/clang                 clang                  /usr/bin/clang-13     100 \
  --slave   /usr/bin/clang++               clang++                /usr/bin/clang++-13 \
  --slave   /usr/bin/lld                   lld                    /usr/bin/lld-13 \
  --slave   /usr/bin/clang-format          clang-format           /usr/bin/clang-format-13  \
  --slave   /usr/bin/clang-tidy            clang-tidy             /usr/bin/clang-tidy-13 \
  --slave   /usr/bin/clang-tools           clang-tools            /usr/bin/clang-tools-13 \
  --slave   /usr/bin/lldb                  lldb                   /usr/bin/lldb-13 \
  --slave   /usr/bin/clangd                clangd                 /usr/bin/clangd-13

# build googletest
RUN mkdir -p /tmp/gtest
WORKDIR /tmp/gtest
RUN cmake /usr/src/googletest/googletest
RUN make install
WORKDIR /
RUN rm -r /tmp/gtest

## # USE ONLY clang++
## RUN echo alias g++=\"g++ -std=c++20\"         >>/config/.zshrc
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
