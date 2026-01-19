# Start with CUDA 11.8 on Ubuntu 22.04 (Jammy)
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=humble

# 1. Install Python, Pip, and TensorRT dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnupg2 \
    lsb-release \
    ca-certificates \
    python3-pip \
    python3-dev \
    wget \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip after installing python3-pip
RUN python3 -m pip install --upgrade pip

# 2. Install TensorRT 8.x + Headers + Eigen
RUN apt-get update && apt-get install -y \
    libeigen3-dev \
    libnvinfer8=8.5.3-1+cuda11.8 \
    libnvinfer-dev=8.5.3-1+cuda11.8 \
    libnvonnxparsers8=8.5.3-1+cuda11.8 \
    libnvonnxparsers-dev=8.5.3-1+cuda11.8 \
    libnvparsers8=8.5.3-1+cuda11.8 \
    libnvparsers-dev=8.5.3-1+cuda11.8 \
    libnvinfer-plugin8=8.5.3-1+cuda11.8 \
    libnvinfer-plugin-dev=8.5.3-1+cuda11.8 \
    python3-libnvinfer=8.5.3-1+cuda11.8 \
    && rm -rf /var/lib/apt/lists/*

# 3. Install ROS2 Humble
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

# 4. Install ROS2 packages and development tools
RUN apt-get update && apt-get install -y \
    ros-humble-ros-base \
    ros-humble-pcl-conversions \
    ros-humble-sensor-msgs \
    python3-colcon-common-extensions \
    python3-rosdep \
    git build-essential \
    && rm -rf /var/lib/apt/lists/*

# 5. Initialize workspace
WORKDIR /ws_centerpoint
RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc