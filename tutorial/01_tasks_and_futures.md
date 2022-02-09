---
layout: page
title: Tasks and Futures
sidebar: false
highlight_first: false
permalink: /tutorial/01_tasks_and_futures/index.html
---

This example introduces task launches and futures in Regent with a
naive (but parallel) implementation of the Fibonacci numbers. This is
not the fastest way to compute Fibonacci numbers, nor is it idiomatic
Regent code, but it demonstrates some of the basic properties of
Regent tasks. The complete code for this example follows at the bottom
of the page and can also be found in the [GitHub
repository](https://github.com/StanfordLegion/legion/tree/master/tutorial).

## Tasks and Parallelism

*Tasks* are the basic unit of execution in Regent, like functions in
traditional languages. In fact, the bodies of tasks literally execute
sequentially. This means you can read the code for a task from top to
bottom, as in a conventional programming language.

In Regent, when a task calls another task (called a *child task* or
*subtask*), that task may execute in parallel. (The caller in this
context is also known as a *parent task*.) Regent always ensures that
the program behaves as if it were executing sequentially. Thus, when
reading a program to understand what it does, it is sufficient to
imagine that the tasks are simply running in order, one after another.

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

## Futures and Blocking Execution

Here is the complete code for the `fibonacci` task. It takes one `int`
argument, and returns an `int`. (The return type is inferred and thus
need not be stated explicitly.) The body of the task stores the
results of the two recursive calls in variables `f1` and `f2` and
returns the sum of their values.

{% highlight regent %}
task fibonacci(n : int)
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
(`fibonacci(n - 2)`). Each task call is issued asynchronously. That
is, execution proceeds in parallel to the parent task (assuming Regent
can determine that this is safe to do). Thus the two substasks execute
in parallel, despite the parent issuing the two calls in sequential
order.

However, there are situations that can prevent parallel execution from
occurring. In particular, because the parent executes the calls to
substasks sequentially (even if the subtasks themselves may execute in
parallel), if the parent task code blocks for any reason, Regent is
unable to analyze any task calls subsequent to the point where it
blocks. (At least, until the parent task is unblocked. But by that
point the opportunity for parallelism has already passed.)

A concrete example of something that might block execution would be
printing the value of `f1`:

{% highlight regent %}
var f1 = fibonacci(n - 1)
format.println("value of first fibonacci is {}", f1) -- blocks!
var f2 = fibonacci(n - 2)
{% endhighlight %}

The second line in this snippet blocks, because it prints the result
`f1` of the first task. In general, anything outside of Regent's
control (I/O, or anything written in C or another language) may
inhibit parallelism. An easy way to work around this is to wrap the
call to `println` in a task, as shown at the bottom of this
section. Using the task "hides" the I/O from Regent, essentially
giving Regent permission to reorder it with other tasks.

## Why the Code Blocks

To understand more about why this code blocks, we need to describe an
optimization performed by the Regent compiler. To be clear, this is
*not* part of the Regent language, and in most cases, users need not
think about it at all. But because it influences parallelism, it can
be important to understand what Regent is doing to the code.

Behind the scenes, Regent maximizes parallelism by making each task
return a *future*. Futures represent the results of tasks yet to be
completed. In most cases, users don't need to be concerned with
futures: as noted above, as long as the program avoids passing any
futures into I/O (or C functions), Regent will handle the parallelism
automatically. Most Regent operations (tasks, arithmetic, even
conditionals like `if` and `while`) can accept futures directly. The
main exception is when the code invokes I/O or something written in a
different language (like C). This happened above at the point where we
passed `f1` into `format.println`.

Because this is an optimization by the Regent compiler, it can
sometimes be hard to tell where a program will block. To help make
this visible to the user, Regent provides a mode (enabled by the flag
`-fpretty 1`) where the code for each task is printed back out, after
applying all of Regent's optimizations. This can be a helpful way to
determine what optimizations are occurring and where potential
serialization hazards may be in the code. If we run the above example
with `-fpretty 1`, it produces something like:

{% highlight regent %}
var f1 : future(int) = fibonacci(n - 1)
format.println("value of first fibonacci is {}", __future_get_result(f1))
var f2 : future(int) = fibonacci(n - 2)
{% endhighlight %}

Two things become obvious when we look at this code. First, Regent has
changed both variables into futures. (Note that the `future` type is
*not* one that users can write directly in Regent. It is purely an
optimization of the compiler.) And second, Regent inserts a blocking
call (`__future_get_result`) at the point where the value is about to
be printed. This helps us pinpoint exactly where the code is going to
block.

## Putting it All Together

Returning to our original example, `main` calls `fibonacci` in a
loop. In order to avoid blocking on the call to `println`, the call is
extracted into a task and called on the result of each `fibonacci`
call. Thus the entire body of `main` will execute in parallel, with
each `print_result` waiting on its corresponding `fibonacci`, but not
otherwise blocking the execution of other `fibonacci` or
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

## On (Not) Writing Idiomatic Code in Regent

One last note before we move on: while this code is functionally
correct and will even execute in parallel, it is *not* idiomatic
Regent code.

First, the code above is very short. The `fibonacci` task essentially
executes one `+` operation before returning. This means that, in
addition to the algorithm itself being inefficient, this code is
likely to experience very high overhead.

Recall that Regent automatically discovers parallelism between
subtasks. This is a *dynamic* analysis, which means that it happens at
runtime, while the parent task is executing. While Regent is heavily
optimized to reduce the overhead of executing tasks, there will always
be a certain amount of overhead that is inevitable. Thus, as a general
rule, it is a good idea to construct larger tasks that perform more
work at once, to counteract this overhead.

Second, the code uses scalar data types. There is nothing wrong with
this per se. But most Regent programs operate on aggregate data
structures. We will consider how to define bulk data in a future
tutorial.

Third, the code uses recursion. While recursion may seem like a natural
way to express nested parallelism, it is not the most idiomatic, or
most efficient, way to express parallelism in Regent. Why? Because (as
noted above) every task call has an overhead, recursion essentially
delays the point at which Regent can discover the parallelism in a
task. Thus it is normally better to write tasks in a loop-based style,
so that a single parent task can enumerate all of the
subtasks. Shallow levels of nesting are fine (say, at most two or
three levels), but arbitrary recursion is usually a source of
bottlenecks and thus best avoided in idiomatic Regent code.

We will return to the topic of writing idiomatic Regent code in future
tutorials, after we discuss some additional features of the language.

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

## Next Up

Continue to the [next tutorial]({{ "tutorial/02_index_tasks" |
relative_url }}) to see how to use index launches optimize loops of
parallel tasks.
