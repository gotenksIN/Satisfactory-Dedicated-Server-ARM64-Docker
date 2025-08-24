# Use Ubuntu 25.10 as base
FROM ubuntu:25.10

# Install cURL, Python 3, sudo, unbuffer and the package for "add-apt-get-repository"
RUN apt-get update && apt-get install -y --no-install-recommends \
    binfmt-support \
    clang \
    cmake \
    curl \
    expect \
    git \
    libepoxy-dev \
    libncurses-dev \
    libqt5core5a \
    libqt5gui5 \
    libqt5widgets5 \
    libsdl2-dev \
    libssl-dev \
    lld \
    llvm \
    ninja-build \
    pkg-config \
    python3 \
    python3-setuptools \
    qml-module-qtquick-controls2 \
    qml-module-qtquick-window2 \
    qml-module-qtquick2 \
    qt5-qmake \
    qtbase5-dev \
    qtbase5-dev-tools \
    qtchooser \
    qtdeclarative5-dev \
    software-properties-common \
    squashfs-tools \
    squashfuse \
    sudo \
    systemd

# Compiling FEX
RUN add-apt-repository -y ppa:fex-emu/fex
RUN git clone --recurse-submodules https://github.com/FEX-Emu/FEX.git
WORKDIR /FEX
RUN sed -i 's@USE_LEGACY_BINFMTMISC "Uses legacy method of setting up binfmt_misc" FALSE@USE_LEGACY_BINFMTMISC "Uses legacy method of setting up binfmt_misc" TRUE@' ./CMakeLists.txt
RUN mkdir Build
WORKDIR /FEX/Build
RUN CC=clang CXX=clang++ cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DUSE_LINKER=lld -DENABLE_LTO=True -DBUILD_TESTS=False -DENABLE_ASSERTIONS=False -G Ninja ..
RUN ninja
RUN ninja install
RUN ninja binfmt_misc

# Create user steam
RUN groupadd -g 1001 steam
RUN useradd -m -u 1001 -g 1001 steam

# Install FEX root FS
RUN sudo -u steam bash -c "unbuffer FEXRootFSFetcher --distro-name ubuntu --distro-version 24.04 -y -x"

# Change user to steam
USER steam

# Go to /home/steam/Steam
WORKDIR /home/steam/Steam

# Download and extract SteamCMD
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# Copy init-server.sh to container
COPY --chmod=755 --chown=steam:steam ./init-server.sh /home/steam/init-server.sh
RUN chmod +x /home/steam/init-server.sh

# Run it using JSON exec form
ENTRYPOINT ["/home/steam/init-server.sh"]
