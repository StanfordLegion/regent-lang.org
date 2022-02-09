---
layout: page
title: Hello World
sidebar: false
highlight_first: false
permalink: /tutorial/00_hello_world/index.html
---

No tutorial would be complete without a Hello World example. Below is
the source code for Hello World in Regent, with descriptions of the
various portions of the program following. The source for this and
other tutorials can also be found in the [GitHub
repository](https://github.com/StanfordLegion/legion/tree/master/tutorial).

{% highlight regent %}
import "regent"

local format = require("std/format")

task hello_world()
  format.println("Hello World!")
end

task main()
  hello_world()
end
regentlib.start(main)
{% endhighlight %}

## Preamble

Regent is an embedded language. The outermost level of the source code
is a [Lua script](https://www.lua.org/). By default, everything you
see in a Regent program is written in Lua. The program switches into
Regent when certain keywords (e.g., `task`) are used. This allows
Regent and Lua code to be used side-by-side in the same program.

In order to register Regent's keywords with the Lua interpreter, every
Regent program starts with the following line:

{% highlight regent %}
import "regent"
{% endhighlight %}

(If you forget this line, you will typically see a parser error, as
Lua attempts to interpret Regent keywords as Lua variable names.)

## Lua Code

Execution of a script begins in Lua. The code runs top-to-bottom, like
a standard scripting language. Unlike a conventional language, Regent
constructs can *also* be embedded in the program.

Important: in most cases, Lua code cannot directly call Regent
tasks. (The exception, `regentlib.start`, is shown below.) This means
that it is best to think of Lua running "at compile time" from the
perspective of Regent. Exactly what this means, and how to use it,
will be explored in a future tutorial.

As an example, the line below loads the `std/format` module from the
Regent standard library, which provides utilities for formatted
printing.

{% highlight regent %}
local format = require("std/format")
{% endhighlight %}

The module here is actually a Lua value. It is stored in a Lua
variable (via `local`) under the name `format`. As we'll see below,
Regent code can access Lua variables. This means that once we load the
module in Lua, we can make use of it in our Regent code.

## Hello World Task

Next we define a Regent task. This is done with the `task`
keyword. Note that, once we reach the `task` keyword, subsequent code
is in Regent (until the matching `end`). After `end` we return to Lua
to continue execution.

Regent tasks are covered in a future tutorial, but for now it is
sufficient to say that they behave like functions.

{% highlight regent %}
task hello_world()
  format.println("Hello World!")
end
{% endhighlight %}

## Main Task

After this, we define the main task. The main task, like `main` in
many languages, takes no arguments and produces no result. (Unlike
many languages, the name `main` is just a convention in Regent. It
could be anything.)

Here, our main task invokes `hello_world` to produce the output message.

{% highlight regent %}
task main()
  hello_world()
end
{% endhighlight %}

## Starting Execution

Finally, at the end of the file, we start the program (beginning with
`main`). Note that, as described earlier, this is the only place where
Lua is permitted to call into Regent. After this call, execution
begins at `main` and proceeds through the Regent program.

In our example, `main` calls `hello_world`, which calls
`format.println`, which prints a line to the standard output of the
program.

The `start` call *does not return*. Furthermore, the Lua execution
environment used to compile the Regent program is also unavailable
after this function is called. So complete any Lua programming prior
to calling this function.

{% highlight regent %}
regentlib.start(main)
{% endhighlight %}

## Next Up

Continue to the [next tutorial]({{ "tutorial/01_tasks_and_futures" |
relative_url }}) to see how to use tasks to achieve parallel
execution.
