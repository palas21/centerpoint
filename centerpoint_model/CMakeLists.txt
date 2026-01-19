cmake_minimum_required(VERSION 3.5)
project(centerpoint_model)

# Default to C++14
if(NOT CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD 14)
endif()

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# find dependencies
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(tf2_ros REQUIRED)
find_package(rcl_interfaces REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(CUDA REQUIRED)
find_package(tf2_geometry_msgs REQUIRED)
find_package(tf2_eigen REQUIRED)
find_package(pcl_conversions REQUIRED)
find_package(PCL REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(centerpoint_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(yaml-cpp REQUIRED)

if(${CMAKE_HOST_SYSTEM_PROCESSOR} STREQUAL  "aarch64")
  set(CMAKE_C_COMPILER /usr/bin/aarch64-linux-gnu-gcc)
  set(CMAKE_CXX_COMPILER /usr/bin/aarch64-linux-gnu-g++)
  set(CUDA_INSTALL_TARGET_DIR targets/aarch64-linux)
elseif(${CMAKE_HOST_SYSTEM_PROCESSOR} STREQUAL "x86_64")
  set(CMAKE_C_COMPILER /usr/bin/gcc)
  set(CMAKE_CXX_COMPILER /usr/bin/g++)
  set(CUDA_INSTALL_TARGET_DIR targets/x86_64-linux)
endif()

set(CUDA_TOOLKIT_ROOT_DIR /usr/local/cuda)
set(CUDA_INCLUDE_DIRS ${CUDA_TOOLKIT_ROOT_DIR}/include)

# Add CUDA library search paths
if(EXISTS ${CUDA_TOOLKIT_ROOT_DIR}/lib64)
  link_directories(${CUDA_TOOLKIT_ROOT_DIR}/lib64)
endif()
if(EXISTS ${CUDA_TOOLKIT_ROOT_DIR}/${CUDA_INSTALL_TARGET_DIR}/lib)
  link_directories(${CUDA_TOOLKIT_ROOT_DIR}/${CUDA_INSTALL_TARGET_DIR}/lib)
endif()

set(CMAKE_BUILD_TYPE "Release")
set(CMAKE_CXX_FLAGS_RELEASE "-Wno-deprecated-declarations -O2")
add_compile_options(-W)

set( SMS 30 32 35 37 50 52 53 60 61 62 70 72 75 87)
foreach(sm ${SMS})
	set(GENCODE ${GENCODE} -gencode arch=compute_${sm},code=sm_${sm})
endforeach()
set(HIGHEST_SM 87)
set(GENCODE ${GENCODE} -gencode arch=compute_${HIGHEST_SM},code=compute_${HIGHEST_SM})

set(CUDA_NVCC_FLAGS ${CUDA_NVCC_FLAGS}
  -ccbin ${CMAKE_CXX_COMPILER}
  -Xcompiler -DWIN_INTERFACE_CUSTOM
  -Xcompiler -I/usr/aarch64-linux-gnu/include/
  -Xlinker -lsocket
  -Xlinker -rpath=/usr/lib/aarch64-linux-gnu/
  -Xlinker -rpath=/usr/aarch64-linux-gnu/lib/
  -Xlinker -L/usr/lib/aarch64-linux-gnu/
  -Xlinker -L/usr/aarch64-linux-gnu/lib/
)

if(${CMAKE_BUILD_TYPE} STREQUAL "Debug")
  message("Using Debug Mode")
  set(CUDA_NVCC_FLAGS ${CUDA_NVCC_FLAGS} -g -G --ptxas-options=-v)
endif()

set(TENSORRT_INCLUDE_DIRS /usr/include/x86_64-linux-gnu)
set(TENSORRT_LIBRARY_DIRS /usr/lib/x86_64-linux-gnu)

include_directories(
  include
  ${PROJECT_SOURCE_DIR}/include
  ${pcl_conversions_INCLUDE_DIRS}
  ${PCL_INCLUDE_DIRS}
  ${CUDA_INCLUDE_DIRS}
  ${TENSORRT_INCLUDE_DIRS}
  ${YAML_CPP_INCLUDE_DIRS}
  ${centerpoint_msgs_INCLUDE_DIRS}
  /usr/include/eigen3         # Added Eigen explicitly
  /usr/include/pcl-1.12       # Added PCL explicitly
)

link_directories(
	${TENSORRT_LIBRARY_DIRS}
	/usr/lib/x86_64-linux-gnu
)

file(GLOB_RECURSE SOURCE_FILES
  src/*.cu
  src/plugin/*.cu
  src/*.cpp
  src/plugin/*.cpp
)

cuda_add_library(${PROJECT_NAME} SHARED ${SOURCE_FILES})
target_include_directories(${PROJECT_NAME}
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
    ${PROJECT_SOURCE_DIR}/include
)
ament_target_dependencies(${PROJECT_NAME}
  rclcpp
  rcl_interfaces
  sensor_msgs
  tf2_geometry_msgs
  tf2_eigen
  pcl_conversions
  visualization_msgs
  centerpoint_msgs
  geometry_msgs
  std_msgs
  tf2_ros
  CUDA
  yaml-cpp
)

# Link TensorRT + cudart into the library (exports to the node)
target_link_libraries(${PROJECT_NAME}
  nvinfer
  nvonnxparser
  nvparsers
  nvinfer_plugin
  ${CUDA_CUDART_LIBRARY}  # use the resolved cudart from FindCUDA
  yaml-cpp
)

add_executable(${PROJECT_NAME}_node src/app/detection.cpp src/app/main.cpp)
target_include_directories(${PROJECT_NAME}_node
  PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${PROJECT_SOURCE_DIR}/include
)

 target_link_libraries(${PROJECT_NAME}_node
    ${PROJECT_NAME}
    ${PCL_LIBRARIES}
    yaml-cpp
  )

ament_target_dependencies(${PROJECT_NAME}_node
  rclcpp 
  sensor_msgs  
  std_msgs
  tf2_geometry_msgs
  tf2_eigen
  rcl_interfaces
  pcl_conversions
  visualization_msgs
  PCL
  geometry_msgs
  tf2_ros
  centerpoint_msgs 
  CUDA
  yaml-cpp
  ) 

install(TARGETS
  ${PROJECT_NAME}
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)

install(TARGETS
  ${PROJECT_NAME}_node
  DESTINATION lib/${PROJECT_NAME}
)

# Install launch files.
install(DIRECTORY
  DESTINATION share/${PROJECT_NAME}
)

SET(CMAKE_BUILD_TYPE Debug) 

ament_package()