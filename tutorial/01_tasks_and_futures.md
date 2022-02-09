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
basic properties of Regent tasks. The complete code for this example
follows at the bottom of the page and can also be found in the [GitHub
repository](https://github.com/StanfordLegion/legion/tree/master/tutorial).

## Tasks

*Tasks* are the basic unit of execution in Regent, like functions in
traditional languages. In fact, the bodies of tasks literally execute
sequentially. This means you can read the code for a task from top to
bottom, as in a conventional programming language.

In Regent, when a task calls other tasks (called *child tasks* or
*subtasks*), those tasks may execute in parallel. However, Regent
always ensures that the program as a whole behaves as if it were
executing sequentially. Thus, when reading a program to understand
what it does, it is sufficient to imagine that the tasks are simply
running in order, one after another.

Behind the scenes, Regent analyzes the sequence of task calls to
determine what is safe to execute in parallel. In the example below,
the two calls to `fibonacci` below run in parallel because they do not
*interfere* (i.e., there is no way for one task to influence the
result of the other).

{% highlight regent %}
var f1 = fibonacci(n - 1)
var f2 = fibonacci(n - 2)
{% endhighlight %}

For the `fibonacci` tasks above, checking for interference is trivial:
the parameters to the tasks are passed by-value, and Regent programs
never contain mutable global variables. Thus there is no way for
either task to modify state used in the other task (and thus no
possibility of interference).

Regent does support mutable state, however. We'll consider this (and
how it results in potential interference) in later tutorials.

## Futures

The `fibonacci` task takes one `int` argument, and returns an
`int`. (The return type can be inferred in general and is shown below
for pedagogical purposes only.) The body of the task stores the
results of the two recursive calls in variables `f1` and `f2` and
returns the sum of their values.

{% highlight regent %}
task fibonacci(n : int) : int
  if n == 0 then return 0 end
  if n == 1 then return 1 end

  var f1 = fibonacci(n - 1)
  var f2 = fibonacci(n - 2)

  return f1 + f2
end
{% endhighlight %}

As noted above, the body of a Regent task literally executes
sequentially. In the example above, that means the first call (to
`fibonacci(n - 1)`) will be considered prior to the second call
(`fibonacci(n - 2)`). Each task call is issued asynchronously. That is,
execution proceeds in parallel to the parent task (assuming Regent can
determine that this is safe to do). This is important, because if the
parent blocks prior to the second call, Regent is unable to analyze it
for parallelism.

An example of something that might block execution would be printing
the value of `f1`:

{% highlight regent %}
var f1 = fibonacci(n - 1)
format.println("value of first fibonnaci is %d\n", f1) -- blocks!
var f2 = fibonacci(n - 2)
{% endhighlight %}

The second line in this snippet blocks, because it invokes I/O. In
general, anything outside of Regent's control (I/O, or anything
written in C or another language) may inhibit parallelism. An easy way
to work around this is to wrap the call to `println` in a task, as
shown at the bottom of this section. Using the task "hides" the I/O
from Regent, essentially giving Regent permission to reorder it with
other tasks.

Behind the scenes, Regent maximizes parallelism by making each task
return a *future*. Futures represent the results of tasks yet to be
completed. In most cases, users don't need to be concerned with
futures: as noted above, as long as the program avoids passing any
futures into I/O (or C functions), Regent will handle the parallelism
automatically. Tasks accept futures directly, so passing a future to a
task does not block. Operators like `+` can also be optimized by
Regent to work on futures, so they do not block either. Similarly,
Regent can optimize most conditional statements (such as `if` and
`while`) that are predicated on futures, as long as those conditionals
do not control the execution of I/O (or C functions). The few
remaining statements that block on futures (e.g., `return`) are
usually not a problem for parallelism.

Returning to our original example, `main` calls `fibonacci` in a
loop. In order to avoid blocking on the call to `println`, the call is
extracted into a task and called on the result of each `fibonacci`
call. Thus the entire body of `main` will execute in parallel, with
each `print_result` waiting on its corresponding `fibonnaci`, but not
otherwise blocking the execution of other `fibonnaci` or
`print_result` calls.

{% highlight regent %}
task print_result(n : int, result : int)
  format.println("Fibonacci({}) = {}", n, result)
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

local format = require("std/format")

task fibonacci(n : int) : int
  if n == 0 then return 0 end
  if n == 1 then return 1 end

  var f1 = fibonacci(n - 1)
  var f2 = fibonacci(n - 2)

  return f1 + f2
end

task print_result(n : int, result : int)
  format.println("Fibonacci({}) = {}", n, result)
end

task main()
  var num_fibonacci = 7
  for i = 0, num_fibonacci do
    print_result(i, fibonacci(i))
  end
end
regentlib.start(main)
{% endhighlight %}
