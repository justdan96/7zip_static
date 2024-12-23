# 7zip Static Build Dockerfile

[Docker](http://docker.com) container to build [7-Zip](https://www.7-zip.org/) as a static executable.


## Usage

You can build the `7zip_static` Docker container from source, during the container's build it will create the UASM and 7-Zip binaries as statically linked executables. 

In the case of UASM it will compile the executable with Clang as `/usr/local/bin/uasm`. In the case of 7-Zip it will compile the executable with Clang as `/usr/local/bin/7zz` and copy it to `/opt/7zz`.

## Building the 7-zip Binaries

### Getting the Latest Version of 7-Zip
First, view https://www.7-zip.org/history.txt and get 7-zip's latest build number, for example:
```
HISTORY of the 7-Zip
--------------------

23.01          2023-06-20
-------------------------
```
You can see the latest build number is 23.01, so we need to set the variable like so `VERSION=2301`. Importantly we should set it without the decimal point!

### Creating the Binaries
Just run the commands below to build 7-zip as a static executable and copy the binary to the current folder. Make sure to update the `VERSION` variable as appropriate.
```
git clone https://github.com/justdan96/7zip_static.git
cd 7zip_static
docker build --build-arg VERSION=2409 -t 7zip_static . 2>&1 | tee build.log
docker run -it --rm -v $(pwd):/workdir -w="/workdir" 7zip_static sh -c "cp /opt/* /workdir"
```
