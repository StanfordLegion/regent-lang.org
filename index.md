---
layout: page
title: "Regent: a Language for Implicit Dataflow Parallelism"
show_title: false
sidebar: true
highlight_first: true
---

**Regent** is a language for implicit dataflow parallelism.

Regent discovers dataflow parallelism in sequential code by computing
a dependence graph over tasks, like the one below. Tasks execute as
soon as all dependencies are satisfied, and can be distributed
automatically over a cluster of (possibly heterogeneous) machines.

<img src="{{ site.baseurl }}/images/frontpage.svg" class="center-block">

Because execution follows the original sequential semantics of the
code, Regent programs are easy to read and understand. Just read the
code top-to-bottom, as if it were written in a traditional sequential
language. The dependence graph above is produced when the task `main`
executes below.

{% highlight regent %}
import "regent"

struct point { x : float, y : float } -- A simple struct with two fields.

-- Define 4 tasks. Ignore the task bodies for the moment; the behavior of each
-- task is soundly described by its declaration. Note that each declaration
-- says what the task will read or write.
task a(points : region(point)) where writes(points) do --[[ ... ]] end
task b(points : region(point)) where reads writes(points.x) do --[[ ... ]] end
task c(points : region(point)) where reads writes(points.y) do --[[ ... ]] end
task d(points : region(point)) where reads(points) do --[[ ... ]] end

-- Execution begins at main. Read the code top-down (like a sequential program).
task main()
  -- Create a region (like an array) with room for 5 elements.
  var points = region(ispace(ptr, 5), point)
  new(ptr(point, points), 5) -- Allocate the elements.

  -- Partition the region into 3 subregions. Each subregion is a view onto a
  -- subset of the data of the parent.
  var part = partition(equal, points, ispace(int1d, 3))

  -- Launch subtasks a, b, c, and d.
  a(points)
  for i = 0, 3 do
    b(part[i])
  end
  c(points)
  for i = 0, 3 do
    d(part[i])
  end
end
regentlib.start(main)
{% endhighlight %}

<!--
<p class="lead">Interested in learning more? <a href="http://try.regent-lang.org/spawn">Try out this example and others in your browser</a>.</p>
-->

<p class="lead">Interested in learning more? <a href="install">Install Regent</a> and checkout the <a href="tutorial">tutorials</a>.</p>
