FROM jammy
SHELL ["/bin/bash", "-c"]

# install cmake
ENV CMAKE_HOME=/opt/cmake/3.29.2
RUN mkdir -p ${CMAKE_HOME}
RUN wget -q https://github.com/Kitware/CMake/releases/download/v3.29.2/cmake-3.29.2-linux-x86_64.tar.gz -O /tmp/cmake.tar.gz \
    && tar -xvf /tmp/cmake.tar.gz --strip-components=1 -C /opt/cmake/3.29.2 \
    && rm /tmp/cmake.tar.gz
RUN echo "CMAKE_HOME=${CMAKE_HOME}" >> /etc/environment
RUN sed -i "/^PATH=/c\\PATH=${CMAKE_HOME}/bin:$PATH" /etc/environment