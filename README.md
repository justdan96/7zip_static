# 7zip Static Build Dockerfile

[Docker](http://docker.com) container to build [7-Zip](https://www.7-zip.org/) as a static executable.


## Usage

### Install

You can build the `7zip_static` Docker container from source, during the container's build it will create the UASM and 7-Zip binaries as statically linked executables. 

In the case of UASM it will compile the executable with Clang as `/usr/local/bin/uasm`. In the case of 7-Zip it will compile the executable with Clang as `/usr/local/bin/7zz_clang` and it will also compile the executable with GCC as `/usr/local/bin/7zz_gcc`.

To create the Docker container from scratch and copy the binaries to the current working directory, run the commands below:
```
git clone https://github.com/justdan96/7zip_static.git
cd 7zip_static
docker build -t 7zip_static . 2>&1 | tee build.log
docker run -it --rm -v $(pwd):/workdir -w="/workdir" 7zip_static sh -c "cp /usr/local/bin/* /workdir"
```
