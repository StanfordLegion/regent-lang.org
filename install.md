---
layout: page
title: Install
sidebar: false
highlight_first: false
permalink: /install/index.html
---

  * [Quickstart](#quickstart)
      * [Ubuntu](#ubuntu)
      * [macOS](#macos)
      * [Other Systems](#other-systems)
  * [Prerequisites](#prerequisites)
  * [Building](#building)
  * [Running](#running)
  * [Development Environment](#development-environment)
  * [Docker](#docker)

# Quickstart

## Ubuntu

If you use Ubuntu, you can install Regent by running:

{% highlight bash %}
# install dependencies
sudo apt-get install build-essential cmake git llvm-6.0-dev libclang-6.0-dev clang-6.0 libedit-dev libncurses5-dev zlib1g-dev

# download and build Regent
git clone -b master https://github.com/StanfordLegion/legion.git
cd legion/language
./install.py --debug --rdir=auto

# run Regent example
./regent.py examples/circuit_sparse.rg
{% endhighlight %}

(These instructions have been tested on Ubuntu 18.04 and 20.04.)

## macOS

If you use macOS, you can install Regent by running:

{% highlight bash %}
# install XCode command-line tools
sudo xcode-select --install

# download CMake
curl -L -O https://github.com/Kitware/CMake/releases/download/v3.22.2/cmake-3.22.2-macos-universal.tar.gz
tar xfz cmake-3.22.2-macos-universal.tar.gz
export PATH="$PATH:cmake-3.22.2-macos-universal/CMake.app/Contents/bin"

# download LLVM
curl -L -O https://github.com/llvm/llvm-project/releases/download/llvmorg-9.0.1/clang+llvm-9.0.1-x86_64-apple-darwin.tar.xz
tar xfJ clang+llvm-9.0.1-x86_64-apple-darwin.tar.xz

# environment variables needed to build/run Regent
export CMAKE_PREFIX_PATH="$CMAKE_PREFIX_PATH:$PWD/clang+llvm-9.0.1-x86_64-apple-darwin"
export INCLUDE_PATH="$(xcrun --sdk macosx --show-sdk-path)/usr/include"
export CXXFLAGS="-std=c++11"

# download and build Regent
git clone -b master https://github.com/StanfordLegion/legion.git
cd legion/language
./install.py --debug --rdir=auto

# run Regent example
./regent.py examples/circuit_sparse.rg
{% endhighlight %}

(These instructions have been tested on macOS 11.6 on an x86 Mac.)

## Other Systems

Complete instructions for installation follow below.

Regent is also available as a Docker container. See [the bottom of
this page](#docker) for instructions.

# Prerequisites

Regent requires:

  * Linux, macOS, or another Unix
  * A C++ 11 (or newer) compiler (GCC, Clang, Intel, or PGI) and GNU Make
  * Python 3.5 or newer
  * LLVM and Clang **with headers**:
      * LLVM 6.0 is recommended
      * See the [version support table](https://github.com/terralang/terra#supported-llvm-versions) for more details
  * *Optional (but recommended)*: CMake 3.5 or newer

There are also a number of optional dependencies. For most users, we
recommend skipping these initially and installing them later on an
as-needed basis.

  * *Optional*: CUDA 7.0 or newer (for NVIDIA GPUs)
  * *Optional*: [GASNet](https://gasnet.lbl.gov/) (for networking, see
     [installation instructions](http://legion.stanford.edu/gasnet/))
  * *Optional*: HDF5 (for file I/O)

# Building

Regent includes a self-installer which downloads
[Terra](http://terralang.org/) and builds the Regent compiler. Run:

{% highlight bash %}
git clone -b master https://github.com/StanfordLegion/legion.git
cd legion/language
./install.py --debug
{% endhighlight %}

For other installation options (including multi-node and GPU
configurations), see the
[README](https://github.com/StanfordLegion/legion/blob/master/language/README.md).

# Running

Regent includes a frontend interpreter which can be run with:

{% highlight bash %}
./regent.py <script>
{% endhighlight %}

For example:

{% highlight bash %}
./regent.py examples/circuit.rg
{% endhighlight %}

(Note: The Regent frontend can also be run without arguments to obtain
a [Terra](http://terralang.org)/[LuaJIT](http://luajit.org/)
shell. However, this mode is not very useful because of the way that
Terra language extensions works. Also, the Legion runtime is not
currently reentrant, making interactive use difficult.)

# Development Environment

Regent syntax highlighting modes are available for the following
editors:

  * [Emacs](https://github.com/StanfordLegion/regent-mode)
  * [Vim](https://github.com/StanfordLegion/regent.vim)

# Docker

If you have [Docker](https://www.docker.com/), Regent is also
available as a container:

{% highlight bash %}
docker run -ti stanfordlegion/regent
{% endhighlight %}

This will start a bash shell from which you can run Regent. Regent is
installed under `/usr/local/legion`. So for example, to run the
circuit example:

{% highlight bash %}
regent /usr/local/legion/language/examples/circuit.rg
{% endhighlight %}

Because Docker containers have no access to the host file system, some
additional options are required if you want to run Docker on your own
Regent files. The command below mounts the current directory in the
host as `/examples` in the container and then runs Regent on it.

{% highlight bash %}
docker run -ti -v $PWD:/examples stanfordlegion/regent regent /examples/circuit.rg
{% endhighlight %}
