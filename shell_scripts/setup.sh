# Variables
ZIG_VERSION="0.13.0"
ZIG_ARCHIVE="zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
ZIG_DIR="${HOME}/zig-linux-x86_64-${ZIG_VERSION}"
REPOS_DIR="${HOME}/code/repos"

# Download and untar
if [ -e ${HOME}/Downloads/${ZIG_ARCHIVE} ]; then rm ${HOME}/Downloads/${ZIG_ARCHIVE}; fi
if [ -e ${HOME}/${ZIG_DIR} ]; then rm -r ${HOME}/${ZIG_DIR}; fi
cd ${HOME}/Downloads/
wget https://ziglang.org/download/${ZIG_VERSION}/${ZIG_ARCHIVE}
ls ${HOME}/Downloads/${ZIG_ARCHIVE}
tar xfv ${HOME}/Downloads/${ZIG_ARCHIVE}
mv ${ZIG_DIR} ${HOME}

# Install zig executable
cd /usr/local/bin
sudo ln -s ${HOME}/${ZIG_DIR}/zig
cd ${HOME}

# Clone zig language server repo
cd ${REPOS_DIR}
if [ -e zls/ ]; then rm -rf zls/; fi
git clone https://github.com/zigtools/zls.git
cd zls/
git checkout 0.13.0
ls

# Build zls executable
zig build -Doptimize=ReleaseSafe
cd ${HOME}/code/repos/zls/
cp zig-out/bin/zls ${ZIG_DIR}/

# Install zls executable
cd /usr/local/bin
sudo ln -s ${ZIG_DIR}/zls
cd ${HOME}
