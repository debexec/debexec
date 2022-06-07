GLX_DIRS="\
    /usr/lib/i386-linux-gnu \
    /usr/lib/x86_64-linux-gnu \
"
GLX_LIBS="\
    libGLX_nvidia.so.0 \
    libnvidia-glvkspirv.so.* \
"
FILES="\
    /usr/share/vulkan/icd.d/nvidia_icd.json \
    /usr/share/vulkan/implicit_layer.d/nvidia_layers.json \
"
for GLX_DIR  in ${GLX_DIRS}; do
    for GLX_LIB in ${GLX_LIBS}; do
        DEPS=$(ldd "${GLX_DIR}"/${GLX_LIB} | sed -n 's|.* => \(.*libnvidia.*\) (.*)|\1|p')
        FILES="${FILES} $(ls "${GLX_DIR}"/${GLX_LIB}) ${DEPS}"
    done
done
echo "${FILES}"
