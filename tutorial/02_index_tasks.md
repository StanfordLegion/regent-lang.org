---
layout: page
title: Index Tasks
sidebar: false
highlight_first: false
permalink: /tutorial/02_index_tasks/index.html
---

Regent provides a number of optimizations to ensure that tasks execute
in parallel and with maximum efficiency. One of the most important of
these is *index task* optimization. An *index task launch*
encapsulates a parallel loop and ensures that the runtime is able to
amortize the cost of analysis of the contained tasks.

## Index Tasks

Loops are a common pattern in parallel codes. Regent optimizes loops
to ensure that they execute efficiently on the Legion runtime. Recall
that tasks execute in parallel only if they do not interfere. Legion
must expend effort analyzing each task to determine non-interference
with respect to surrounding tasks. Index tasks ensure that this
analysis is amortized over a loop of task calls, increasing the
efficiency of the runtime.

Regent generates index task launches on loops containing tasks
calls. For example, the following code calls a task `double_of` in a
loop, and accumulates the results into the variable `total`.

{% highlight regent %}
var total = 0
__demand(__parallel)
for i = 0, num_points do
  total += double_of(i, i + 10)
end
{% endhighlight %}

The line `__demand(__parallel)` marks the loop as an index
launch. This annotation is *not required*, and is shown mostly for
pedagogical purposes. Regent will optimize this loop
regardless.

Generally speaking, annotations are recommended only as a means of
[defensive
programming](https://en.wikipedia.org/wiki/Defensive_programming)
against bugs (in the application or compiler). The `__parallel`
annotation guarantees that the compiler will produce an error if it
is unable to optimize the loop in question. Most often, this happens
because of a loop-carried dependence between the iterations of the
loop. (This is contrast an OpenMP-style `#pragma`, which applies the
optimization even if it is unsound.)

## Final Code

{% highlight regent %}
import "regent"

local c = terralib.includec("stdio.h")

task double_of(i : int, x : int)
  c.printf("Hello world from task %d!\n", i)
  return 2*x
end

task main()
  var num_points = 4

  var total = 0
  __demand(__parallel)
  for i = 0, num_points do
    total += double_of(i, i + 10)
  end
  regentlib.assert(total == 92, "check failed")
end
regentlib.start(main)
{% endhighlight %}
