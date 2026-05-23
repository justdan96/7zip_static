# 7zip Static Build Dockerfile

[Docker](http://docker.com) container to build [7-Zip](https://www.7-zip.org/) as a static executable.


## Usage

You can build the `7zip_static` Docker container from source, during the container's build it will create the 7-Zip binary as statically linked executables. 

It will compile the executable with Clang and asmc as `/usr/local/bin/7zz` and copy it to `/opt/7zz`.

## Building the 7-zip Binaries

### Updating Versions

Simply run `bump update`.

### Creating the Binaries

Just run the commands below to build 7-zip as a static executable and copy the binary to the current folder.
```
git clone https://github.com/justdan96/7zip_static.git
cd 7zip_static
docker build -t 7zip_static . 2>&1 | tee build.log
docker run -it --rm -v $(pwd):/workdir -w="/workdir" 7zip_static sh -c "cp /opt/7zz /workdir/7zz"
```
