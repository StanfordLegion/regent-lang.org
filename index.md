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
-- Load the Regent language definition.
import "regent"

-- Define a simple struct to be used later.
struct point {
  x : float,
  y : float,
}

-- Tasks are the fundamental unit of parallelism in Regent. Here, we
-- define 4 tasks. Ignore the task bodies for the moment; the behavior
-- of each task is fully described by its declaration. Note that each
-- declaration says what the task will read or write.
task a(points : region(point)) where writes(points) do end
task b(points : region(point)) where reads writes(points.x) do end
task c(points : region(point)) where reads writes(points.y) do end
task d(points : region(point)) where reads(points) do end

-- Execution begins at a main task. Regent code obeys traditional
-- sequential semantics, so read the code top-to-bottom as usual.
task main()
  -- Create a region (like an array) with room for 5 elements.
  var points = region(ispace(ptr, 5), point)
  new(ptr(point, points), 5) -- Allocate the elements.

  -- Partition the region into subregions. Each subregion is a view
  -- onto a subset of the data of the parent.
  var part = partition(equal, points, ispace(int1d, 3))

  -- Launch tasks a, b, c, and d.
  a(points)
  for i = 0, 3 do
    b(part[i])
  end
  c(points)
  for i = 0, 3 do
    d(points)
  end
end

-- Begin execution of main.
regentlib.start(main)
{% endhighlight %}
