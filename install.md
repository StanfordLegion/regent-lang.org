---
layout: page
title: Install
sidebar: false
highlight_first: false
permalink: /install/index.html
---

## Quickstart

### Ubuntu

If you use Ubuntu, you can install Regent by running:

{% highlight bash %}
sudo apt-get install clang-3.5 libclang-3.5-dev llvm-3.5-dev
git clone -b master https://github.com/StanfordLegion/legion.git
cd legion/language
./install.py --debug
{% endhighlight %}

Complete instructions for installation follow below.

Regent is also available as a Docker container. See [the bottom of
this page](#docker) for instructions.

## Prerequisites

Regent requires:

  * Linux, macOS, or another Unix
  * A C++ 98 (or newer) compiler (GCC, Clang, Intel, or PGI) and GNU Make
  * Python 2.7 (or 3.x)
  * LLVM and Clang 3.5 **with headers**
      * Versions 3.6 and 3.8 also work, but are missing debug symbols in generated code

There are also a number of optional dependencies. For most users, we
recommend skipping these initially and installing them later on an
as-needed basis.

  * *Optional*: CUDA 5.0 or newer (for NVIDIA GPUs)
  * *Optional*: [GASNet](https://gasnet.lbl.gov/) (for networking, see
     [installation instructions](http://legion.stanford.edu/gasnet/))
  * *Optional*: HDF5 (for file I/O)

## Building

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

## Running

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

## Docker

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
