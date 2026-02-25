ARCH_TYPE="arm64"
if [ "$ARCH_TYPE" = "x64" ]; then
    NVIM_TAR="nvim-linux-x86_64.tar.gz"
elif [ "$ARCH_TYPE" = "arm64" ]; then
    NVIM_TAR="nvim-linux-arm64.tar.gz"
else
    NVIM_TAR=""
fi
echo $NVIM_TAR
