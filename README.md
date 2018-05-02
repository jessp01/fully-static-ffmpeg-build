# Abstract

The Dockerfile included in this repo uses an Ubuntu 12.04 base image to build statically linked FFmpeg binaries [ffmpeg and ffprobe].
This was tested using FFmpeg 4.0 [current stable version] but the general process will probably work with future FFmpeg versions.

Note that this repo includes two patches required in order to link against Facebook's [Transform360 library](https://github.com/facebook/transform360):
- Makefile.transform360.patch
- allfilters.c.transform360.patch

If you use a newer FFmpeg version, you may need to modify these.

## When should one use this build process?
If you do not **absolutely have to** produce FFmpeg binaries with no external deps, you should NOT be using this build process.
While static linkage has its advantages, it also has several shortcomings, namely:
- Every time new versions of the libraries/components your project depends on are released [this is not only important due to bugfixes and added features but also from a security perspective], you must build a new version 
- It results in much bigger binaries

In my case, I had to build FFmpeg this way because the resulting binaries had to run on both Ubuntu 12.04 and Ubuntu 16.04 and updating libstdc++ on the 12.04 instance was not feasible whereas the build process [due to several mandatory deps] required a g++ version that fully supports the c11 standard, which, the g++ provided in the official Ubuntu repos [version 4.6] did not.
This is also why Ubuntu 12.04 is used as the base image. 

The same process should work on other Debian and Debian based distros.
 
Depending on your distro of choice, you may not need to compile some of these deps yourself but rather, install the deb packages from the official repo.

## What will this build produce?
`ffmpeg` and `ffprobe` binaries that weigh a ton but have ZERO external deps. Yup, zero.
FFmpeg is built with the following codecs/filters/options:
- x264
- x265
- FDK
- LAME
- Ogg
- Vorbis
- Speex
- Theora
- OpenCore AMR [Adaptive Multi Rate Narrowband and Wideband]
- OpenJPEG
- VPX
- OpenCV
- VAMF
- Facebook Transform360

The versions for these deps are set as ENV vars in the beginning of the Dockerfile so fetching, building and linking against different versions should be relatively painless [unless it fails, of course:)].

## Important note about distributing the resulting binaries
Legally, you are NOT, and therefore, should NOT, distribute the resulting binaries.
The FFmpeg configure command in the Dockerfile includes the `--enable-gpl` and `--enable-nonfree` configuration options and FFmpeg binaries whose build process required these flags cannot be re-distributed.
For more info, see [FFmpeg License and Legal Considerations](https://ffmpeg.org/legal.html).

## Building
The process is the same as with any other Dockerfile.
Build the container with:
```
# docker build -t static-ffmpeg /path/to/fully-static-ffmpeg-build/
```
The resulting binaries will be installed under `/opt/kaltura/ffmpeg-$FFMPEG_VER` inside the container.
Of course, you're free to change the prefix or anything else to suit your particular needs.

