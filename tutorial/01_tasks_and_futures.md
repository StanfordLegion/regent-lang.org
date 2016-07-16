---
layout: page
title: Tasks and Futures
sidebar: false
highlight_first: false
permalink: /tutorial/01_tasks_and_futures/index.html
---

This example introduces task launches and futures in Regent with a
naive (but parallel) implementation of the Fibonacci numbers. This is
not the fastest way to compute Fibonacci numbers, but demonstrates the
functional nature of Regent tasks. The complete code for this example
follows at the bottom of the page and can also be found in the [GitHub
repository](https://github.com/StanfordLegion/legion/tree/master/tutorial).

## Tasks

*Tasks* are the fundamental unit of execution in Regent. Tasks are
like functions in traditional languages. In fact, tasks execute
sequentially. This means you can read the body of task from
top-to-bottom, just like a normal sequential language.

*Parallelism* occurs only among child tasks. (The terms *child tasks*
and *subtasks* simply refer to the set of tasks called by a given
task.) Though the two calls to `fibonacci` below appear to execute in
sequence, they will actually run in parallel with each other.

{% highlight regent %}
var f1 = fibonacci(n - 1)
var f2 = fibonacci(n - 2)
{% endhighlight %}

Two tasks can execute in parallel only if they do not interfere. For
the two calls above, this is trivial: the parameters to the tasks
above are passed by-value, and there are no mutable global variables
in Regent. Thus there is no way for them to modify state used in the
other task (and thus no possibility of interference).

Regent does support mutable state, however. We'll consider this (and
how it results in potential interference) in later tutorials.

## Futures

The `fibonacci` task itself is declared to take two `int` arguments,
and returns an `int`. (The return type can be inferred in general and
is shown below for pedagogical purposes only.) The body of the task
stores the results of the two recursive calls in variables `f1` and
`f2` and returns the sum of their values.

{% highlight regent %}
task fibonacci(n : int) : int
  if n == 0 then return 0 end
  if n == 1 then return 1 end

  var f1 = fibonacci(n - 1)
  var f2 = fibonacci(n - 2)

  return f1 + f2
end
{% endhighlight %}

In order to maximize parallelism, it's important to avoid blocking the
execution of a task as it calls subtasks. Regent has a number of
optimizations that help ensure this. For example, the `fibonacci` task
above returns a *future*, rather than a direct value. This means that
the execution continues past the line `var f1 = fibonacci(n - 1)` to
the second `fibonacci` call, even though the result of the call may
not be ready yet. The `+` operator is also lifted to operate on
futures. Thus, the task only blocks at the final `return` statement,
after all parallel operations have been issued.

It is important to note that futures are *not* an a part of the Regent
programming model. They are purely an optimization, inserted
automatically by the compiler where appropriate. However, there are a
number of ways to defeat the optimization---for example, a call to a C
function cannot be issued in parallel, and thus must block execution
if one of the arguments is a future.

The main task calls `fibonacci` in a loop. In order to avoid blocking
on the call to `c.printf`, the call is extracted into a task and
called on the result of each `fibonacci` call.

{% highlight regent %}
task print_result(n : int, result : int)
  c.printf("Fibonacci(%d) = %d\n", n, result)
end

task main()
  var num_fibonacci = 7
  for i = 0, num_fibonacci do
    print_result(i, fibonacci(i))
  end
end
{% endhighlight %}

## Final Code

{% highlight regent %}
import "regent"

local c = terralib.includec("stdio.h")

task fibonacci(n : int) : int
  if n == 0 then return 0 end
  if n == 1 then return 1 end

  var f1 = fibonacci(n - 1)
  var f2 = fibonacci(n - 2)

  return f1 + f2
end

task print_result(n : int, result : int)
  c.printf("Fibonacci(%d) = %d\n", n, result)
end

task main()
  var num_fibonacci = 7
  for i = 0, num_fibonacci do
    print_result(i, fibonacci(i))
  end
end
regentlib.start(main)
{% endhighlight %}
