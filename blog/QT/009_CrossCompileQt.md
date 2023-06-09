# 交叉编译 Qt5.12

[TOC]

## 前言

之前我说了一句，就算板子性能再弱，编译需要的时间也不会比我配置交叉编译的时间久，这不，报应就来了，手上有一个性能弱到爆的Arm32机器，根本不可能在上面编译啊！！！所以不得不走上交叉编译的道路，这个版本是带 QtWebEngine 的



## 准备 sysroot

### 基础镜像

sysroot 基于 ubuntu 使用 qemu 搭建，根据[《QEMU 模拟器定制根文件系统》](../Linux/009_QEMUBuildRootfs.md)一步一步来，先不要退出 qemu 环境

### 安装需要的依赖库

根据自己实际情况安装需要的支持库，当然全部装也只是大了那么一丢丢

```bash
# 交叉编译qt需要的库
apt install libssl-dev libnss3-dev libdbus-1-dev libfontconfig1-dev libfreetype6-dev
# opengles2
apt install libgles2-mesa-dev
# eglfs支持
apt install libgbm-dev libdrm-dev
# alsa开发库及其工具
apt install libasound2-dev alsa-utils
# pulseaudio开发库及服务
apt install libpulse-dev pulseaudio
# tslib
apt install libts-dev
# 键盘支持
apt install libxkbcommon-dev
# jpeg
apt install libjpeg-dev
```

### 安装自己要用的工具

根据自己需要的安装，也可以不装

```bash
# 平常需要用的工具
apt install unzip nmon rsync 
# killall工具
apt install psmisc
# hexdump insmod
apt install bsdmainutils kmod
# 编译工具
apt install build-essential cmake gdb gdbserver
```

### 创建 pkgconfig 软链接

不做这个的话，编译的时候 pkgconfig 找不到需要的库，也不知道有没有更好的解决方案

如果 `/usr/lib/pkgconfig` 目录不是空的，将里面的文件复制放到 `/usr/lib/aarch64-linux-gnu/pkgconfig` 

`/usr/lib/pkgconfig -> /usr/lib/aarch64-linux-gnu/pkgconfig`

```bash
cd /usr/lib/
rm -r pkgconfig
ln -s aarch64-linux-gnu/pkgconfig pkgconfig
```

### 退出 qemu 环境

退出

```bash
exit
```

取消挂载

```bash
/m.sh -u ubuntu20/
```

### 处理软链接

系统里面有很多软链接写的是绝对路径，编译的时候找到的是主机的东西，那可不行哦

```bash
./c.py ubuntu20/
```



## 主机安装编译工具

### 交叉编译工具链

**linaro 工具链**

好像最新版本就只到7.5

<https://releases.linaro.org/components/toolchain/binaries/>

**arm 工具链**

这边就可以下载很新的版本

从 [linaro下载页](https://www.linaro.org/downloads/) 可以看到，现在交叉编译工具链由Arm官方提供：[ARM下载页](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-a/downloads)



### 安装编译需要的环境

这些主要是 webengine 模块需要，具体根据 configure 输出，缺啥装啥就行

```bash
sudo apt install gperf bison flex python2
```

如果是 Arm32 的话，还需要安装以下的东西

```bash
sudo apt install gcc-multilib g++-multilib
```



## 编译Qt

这里以 aarch64 为例，arm 同理

### 配置 mkspecs

```bash
vim qtbase/mkspecs/linux-aarch64-gnu-g++/qmake.conf
```

根据自己的交叉编译工具链实际地址修改，最终我的版本如下，写的全路径

```ini
#
# qmake configuration for building with aarch64-linux-gnu-g++
#

MAKEFILE_GENERATOR      = UNIX
CONFIG                 += incremental
QMAKE_INCREMENTAL_STYLE = sublib

include(../common/linux.conf)
include(../common/gcc-base-unix.conf)
include(../common/g++-unix.conf)

# modifications to g++.conf
QMAKE_CC          = /opt/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-gcc
QMAKE_CXX         = /opt/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-g++
QMAKE_LINK        = /opt/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-g++
QMAKE_LINK_SHLIB  = /opt/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-g++

# modifications to linux.conf
QMAKE_AR          = /opt/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-ar cqs
QMAKE_OBJCOPY     = /opt/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-objcopy
QMAKE_NM          = /opt/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-nm -P
QMAKE_STRIP       = /opt/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-strip
load(qt_config)

```

### configure

```bash
# -sysroot 指定sysroot，需要全路径
# -xplatform 指定交叉编译使用的mkspecs
./configure -prefix /opt/qt-5.12.10 -sysroot /home/kylin/Documents/aarch64/ubuntu20\
    -xplatform linux-aarch64-gnu-g++ -opensource -confirm-license -fontconfig -system-freetype\
    -no-xcb -no-glib -opengl es2 -egl -eglfs -linuxfb -nomake tests -nomake examples
```

### make

```bash
make -j$(nproc)
```

### make install

```bash
sudo make install -j$(nproc)
```

### WebEngine

有些时候上述操作并没有编译 webengine 模块，手动搞他

```bash
cd qtwebengine
../qtbase/bin/qmake
make -j$(nproc)
sudo make install -j$(nproc)
```

### 去掉qt库交叉编译信息

如果需要在目标板上编译qt程序，就进行这一步，不然就完全不需要看这一节的内容哈

```bash
cd opt/qt-5.12.10
./convert2target.sh
```



## 目前遇到的问题

### eglfs

**Could not open egl display**

确保编译的时候 `EGLFS details` 下面有yes

```cpp
EGLFS .................................. yes
EGLFS details:
  EGLFS OpenWFD ........................ no
  EGLFS i.Mx6 .......................... no
  EGLFS i.Mx6 Wayland .................. no
  EGLFS RCAR ........................... no
  EGLFS EGLDevice ...................... no
  EGLFS GBM ............................ yes
  EGLFS VSP2 ........................... no
  EGLFS Mali ........................... no
  EGLFS Raspberry Pi ................... no
  EGL on X11 ........................... no
```

**Could not queue DRM page flip on screen xxx**

```bash
export QT_QPA_EGLFS_ALWAYS_SET_MODE=1
```

### qmake

qmake 编译时架构是宿主机的，不能直接在板子上运行，现在我的解决方案就是在板子上编一遍，然后 install 之后就会有 qmake 这些工具了，也不知道有没有更好的解决方案

```bash
cd ${BUILD_DIR}
${QT_SRC_DIR}/configure ...
make -C ${BUILD_DIR}/qtbase/src sub-bootstrap qmake sub-moc sub-rcc sub-uic
```



## 附件

### 附件1 c.py 脚本

```python
#!/usr/bin/env python
import sys
import os

# Take a sysroot directory and turn all the abolute symlinks and turn them into
# relative ones such that the sysroot is usable within another system.

if len(sys.argv) != 2:
    print("Usage is " + sys.argv[0] + "<directory>")
    sys.exit(1)

topdir = sys.argv[1]
topdir = os.path.abspath(topdir)

def handlelink(filep, subdir):
    link = os.readlink(filep)
    if link[0] != "/":
        return
    if link.startswith(topdir):
        return
    #print("Replacing %s with %s for %s" % (link, topdir+link, filep))
    print("Replacing %s with %s for %s" % (link, os.path.relpath(topdir+link, subdir), filep))
    os.unlink(filep)
    os.symlink(os.path.relpath(topdir+link, subdir), filep)

for subdir, dirs, files in os.walk(topdir):
    for f in files:
        filep = os.path.join(subdir, f)
        if os.path.islink(filep):
            #print("Considering %s" % filep)
            handlelink(filep, subdir)

```

### 附件2 convert2target.sh 脚本

```bash
#!/bin/bash

function convert() {
    for file in $1; do
        sed -i "s%/home/kylin/Documents/aarch64/ubuntu20%%g" "$file"
    done
}

files=$(ls mkspecs/*.pri)
convert "$files"

files=$(ls mkspecs/modules/*.pri)
convert "$files"

files=$(ls lib/*.prl)
convert "$files"

files=$(ls lib/*.la)
convert "$files"

files=$(ls lib/cmake/*/*.cmake)
convert "$files"

files=$(ls lib/pkgconfig/*.pc)
convert "$files"
```



