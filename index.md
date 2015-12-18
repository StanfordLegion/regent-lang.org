---
layout: page
title: Regent
show_title: false
sidebar: true
highlight_first: true
---

**Regent** is an implicit parallel programming language with
sequential semantics.

{% highlight regent %}
import "regent"

-- Define a simple struct type with two fields.
struct point {
  x : float,
  y : float,
}

-- Define 4 tasks. Ignore the task bodies for the moment; the behavior of each
-- task is soundly described by its declaration. Note that each declaration
-- says what the task will read or write.
task a(points : region(point)) where writes(points) do end
task b(points : region(point)) where reads writes(points.x) do end
task c(points : region(point)) where reads writes(points.y) do end
task d(points : region(point)) where reads(points) do end

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
    d(points)
  end
end
regentlib.start(main)
{% endhighlight %}

Execution of a Regent program starts at `main`. Each task executes
sequentially. Whenever a task calls a subtask, Regent uses the
*privileges* declared for each task (`reads`, `writes`, etc.) to
determine what previous subtasks this new subtask depends on. In other
words, Regent dynamically computes a dependence graph over the
subtasks called by each task. After the program above executes, it
will have produced the following dependence graph for
`main`. Operations which are independent will execute in parallel.

![]({{ site.baseurl }}/images/frontpage.svg)

Interested in learning more? [Try out this example and others in your
browser](http://try.regent-lang.org).
