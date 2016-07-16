---
layout: page
title: Hello World
sidebar: false
highlight_first: false
permalink: /tutorial/00_hello_world/index.html
---

No tutorial would be complete without a Hello World example. Below is
the source code for Hello World in Regent. The source for this and
other tutorials can also be found in the [GitHub
repository](https://github.com/StanfordLegion/legion/tree/master/tutorial).

{% highlight regent %}
import "regent"

local c = terralib.includec("stdio.h")

task hello_world()
  c.printf("Hello World!\n")
end

task main()
  hello_world()
end
regentlib.start(main)
{% endhighlight %}

## Preamble

Regent is an embedded language. The outermost level of the source code
is a [Lua script](https://www.lua.org/). *Two* languages are embedded
inside this context: [Terra](http://terralang.org/) and Regent
itself. Each language provides special keywords (e.g. `task`) which
trigger execution of the compiler. First, though, Regent needs to
register its language definition so that these keywords available to
the program.

In order to load this language definition, every Regent program starts
with the following line.

{% highlight regent %}
import "regent"
{% endhighlight %}

(If you forget this line, you will typically see some obscure parser
errors, as Lua attempts to interpret Regent keywords as Lua variable
names.)

## Lua Code

The script executes top-to-bottom in Lua. From the perspective of
Regent, this is happening at compile time, similar to the execution of
templates in C++. However, Lua is a full-featured programming
language, making powerful metaprogramming possible.

For example, the line below parses the C header file `stdio.h` and
stores the result into a Lua variable. (So `printf` can be accessed as
`c.printf`.) This makes it easy to interact with arbitrary C code.

{% highlight regent %}
local c = terralib.includec("stdio.h")
{% endhighlight %}

## Hello World Task

Next execution hits the definition of the hello world task
itself. Conceptually, execution of the task definition functions to
invoke the Regent compiler on the source code of the task. That is,
after the following code executes, there will be a new Lua global
variable `hello_world` which points to a task object (corresponding to
the source code below).

The task itself won't run until we star the Legion runtime. Remember:
the script executes *at compile time*. But this feature makes it
possible to perform powerful
[metaprogramming]({{site.baseurl}}/reference#metaprogramming) on Regent code.

{% highlight regent %}
task hello_world()
  c.printf("Hello World!\n")
end
{% endhighlight %}

## Main Task

After this, we define the main task. The main task, like `main` in
many languages, takes no arguments and produces no result. (Unlike
many languages, the name `main` is just a convention in Regent.)

The main task will invoke `hello_world` to produce the output message.

{% highlight regent %}
task main()
  hello_world()
end
{% endhighlight %}

## Starting the Runtime

Finally, at the end of the file, we invoke the Legion runtime. This
kicks off execution of the main task (and subsequent execution of the
rest of the program).

The `start` call *does not return*. Furthermore, the Lua execution
environment used to compile the Regent program is also unavailable
after this function is called. So complete any Lua programming prior
to calling this function.

{% highlight regent %}
regentlib.start(main)
{% endhighlight %}
