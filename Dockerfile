FROM ros:melodic-perception

ENV CATKIN_WS=/root/catkin_ws

RUN   if [ "x$(nproc)" = "x1" ] ; then export USE_PROC=1 ; \
    else export USE_PROC=$(($(nproc)/2)) ; fi && \
    apt-get update && apt-get install -y \
    cmake \
    wget \
    python-catkin-tools python-vcstool \
    libglew-dev libopencv-dev libyaml-cpp-dev  \
    libblas-dev liblapack-dev libsuitesparse-dev \
    libatlas-base-dev \
    libgoogle-glog-dev \
    ros-${ROS_DISTRO}-cv-bridge \
    ros-${ROS_DISTRO}-image-transport \
    ros-${ROS_DISTRO}-message-filters \
    ros-${ROS_DISTRO}-tf \
    ros-${ROS_DISTRO}-tf-conversions \
    ros-${ROS_DISTRO}-rqt ros-${ROS_DISTRO}-rqt-common-plugins && \
    rm -rf /var/lib/apt/lists/*
#
# Upgrade CMake: https://cmake.org/install/
#
ARG CMAKE_VERSION=3.21.4
RUN mkdir cd -p $HOME/src && cd $HOME/src && \
    wget https://github.com/Kitware/CMake/releases/download/v3.21.4/cmake-${CMAKE_VERSION}.tar.gz && \
    tar -xzf cmake-${CMAKE_VERSION}.tar.gz && \
    rm -rf cmake-${CMAKE_VERSION}.tar.gz && \
    cd cmake-${CMAKE_VERSION} && \
    cmake -DCMAKE_BUILD_TYPE:STRING=Release . && \
    make -j4 && make install

WORKDIR $CATKIN_WS
RUN catkin config --init --mkdirs \
    --extend /opt/ros/${ROS_DISTRO} \
    --cmake-args -DCMAKE_BUILD_TYPE=Release -DEIGEN3_INCLUDE_DIR=/usr/include/eigen3

RUN cd src && \
    git clone https://github.com/hellovuong/rpg_svo_pro_open.git && \
    vcs-import < ./rpg_svo_pro_open/dependencies.yaml && \
    touch minkindr/minkindr_python/CATKIN_IGNORE && \
    cd rpg_svo_pro_open/svo_online_loopclosing/vocabularies && \
    wget http://rpg.ifi.uzh.ch/svo2/vocabularies.tar.gz -O - | tar -xz &&\
    cd $HOME/catkin_ws/src/ &&\
    rm rpg_svo_pro_open/svo_global_map/CATKIN_IGNORE

COPY ./patches/dbow2_catkin/CMakeLists.txt /root/catkin_ws/src/dbow2_catkin/

RUN cd src && git clone --branch 4.0.3 https://github.com/borglab/gtsam.git
COPY ./patches/gtsam/CMakeLists.txt /root/catkin_ws/src/gtsam/ 
RUN cd $CATKIN_WS && \ 
    catkin build -j2 gtsam 

RUN catkin build -j2

RUN echo 'source /opt/ros/${ROS_DISTRO}/setup.bash' >> /root/.bashrc
RUN echo 'source /root/catkin_ws/devel/setup.bash' >> /root/.bashrc




