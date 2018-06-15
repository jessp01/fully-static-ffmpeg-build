[![Build Status](https://travis-ci.org/jessp01/fully-static-ffmpeg-build.svg?branch=master)](https://travis-ci.org/jessp01/fully-static-ffmpeg-build)

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

The same general process should work on other Debian and Debian based distros, though minor adjustments may be required.
 
Depending on your distro of choice, you may not have to build some of these deps yourself [like Cmake and nasm] but rather, install the deb packages from the official repo.

## What will this build produce?
`ffmpeg` and `ffprobe` binaries that weigh a ton but have ZERO external deps. Yup, zero.

FFmpeg is built with the following codecs/filters/options:

- [x264](https://www.videolan.org/developers/x264.html)
- [x265](x265.org)
- [FDK-AAC](https://github.com/mstorsjo/fdk-aac)
- [LAME](lame.sourceforge.net)
- [Ogg](https://xiph.org/ogg)
- [Vorbis](https://xiph.org/vorbis)
- [Speex](https://speex.org)
- [Theora](https://xiph.org/theora)
- [OpenCore AMR - Adaptive Multi Rate Narrowband and Wideband](http://sourceforge.net/projects/opencore-amr)
- [OpenJPEG](www.openjpeg.org)
- [VPX](https://github.com/webmproject/libvpx)
- [GSM](http://www.quut.com/gsm)
- [ASS](http://code.google.com/p/libass/)
- [FreeType](http://www.freetype.org)
- [OpenCV](https://opencv.org)
- [VMAF](https://github.com/Netflix/vmaf)
- [Facebook Transform360](https://github.com/facebook/transform360)
- [libRTMP/RTMPDump](https://rtmpdump.mplayerhq.hu)


The versions for these deps are set as ENV vars in `env.rc` so fetching, building and linking against different versions should be relatively painless [unless it fails, of course:)].

## Building
The process is the same as with any other Dockerfile.
Build the container with:
```sh
# docker build -t static-ffmpeg /path/to/fully-static-ffmpeg-build/
```
The resulting binaries will be installed under `/opt/kaltura/ffmpeg-$FFMPEG_VER` inside the container.

> NOTE: If you don't wish to build inside a Docker container, the `build.sh` script can also be invoked independently on any suitable machine. 
The process was tested with Ubuntu 12.04 but may work out of the box [or with minor changes] on other Debian based distros

> If you wish to run build.sh outside a Docker container, make sure you copy `Makefile.transform360.patch` and `allfilters.c.transform360.patch` to wherever the `BUILD_DIR` ENV var is set to [default is /tmp/build].

After running a few very basic tests, the FFmpeg basedir is also archived under /tmp/build/ffmpeg-$FFMPEG_VER.tar.gz.

Of course, you're free to change the prefix or anything else to suit your particular needs.

### Note about VMAF
VMAF requires the PKL model files in order to run. These are deployed to /usr/local/share/model by default and are packaged into the `$BUILD_DIR/ffmpeg-${FFMPEG_VER}-bins.tar.gz` archive. 

If you wish to deploy them onto a different path, you will need to pass the `model_path` parameter when running your `ffmpeg` command. For instance, if you deployed the model dir to /home/jess/share/model, your ffmpeg command should include **-lavfi libvmaf="model_path=/home/jess/share/model/vmaf_v0.6.1.pkl"**. 

See below example:

```sh
$ ffmpeg -i /path/to/first/mp4 -i /path/to/second/mp4 -lavfi \
libvmaf="model_path=/home/jess/share/model/vmaf_v0.6.1.pkl" -f null -t 3 -
```

For more FFmpeg VMAF options, see https://ffmpeg.org/ffmpeg-filters.html#toc-libvmaf.libvmaf

## Important note about distributing the resulting binaries
Legally, you are **NOT allowed to and therefore, should NOT, distribute the resulting binaries.**
The FFmpeg configure command in the build.sh includes the `--enable-gpl` and `--enable-nonfree` configuration options and FFmpeg binaries whose build process required these flags cannot be re-distributed.

For more info, see [FFmpeg License and Legal Considerations](https://ffmpeg.org/legal.html).


