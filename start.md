---
layout: page
title: Getting Started
sidebar: false
highlight_first: false
permalink: /start
---

# Installing Regent

Regent depends on Clang and LLVM **with headers**. LLVM 3.5 is
recommended, though 3.6 should also work. The binary packages on
[LLVM.org](http://llvm.org/releases/download.html#3.5.2) appear to
work well.

The Regent repository includes a self-installer which downloads and
compiles all other dependencies. Run:

{% highlight bash %}
git clone https://github.com/StanfordLegion/legion.git
cd legion/language
./install.py --debug
{% endhighlight %}

For more detailed instructions, see the [project
README](https://github.com/StanfordLegion/legion/tree/master/language).

# Running Regent

Regent includes a frontend interpreter which can be run with:

{% highlight bash %}
./regent.py <script.rg>
{% endhighlight %}

(Note: The Regent frontend can also be run without arguments to obtain
a [Terra](http://terralang.org)/[LuaJIT](http://luajit.org/)
shell. However, this mode is not very useful because of the way that
Terra language extensions works. Also, the Legion runtime is not
currently reentrant, making interactive use difficult.)