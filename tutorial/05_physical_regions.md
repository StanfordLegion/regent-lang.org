---
layout: page
title: Physical Regions
sidebar: false
highlight_first: false
permalink: /tutorial/05_physical_regions/index.html
---

As discussed in previous tutorials, *logical* regions (often just
called regions) are unlike arrays in a language like C, in that they
are not mapped to a fixed memory location over their entire
lifetime. Instead they are mapped to zero or more *physical regions*
(often called *instances*), and may move between these instances over
the duration of the program. Instances may be located on different
nodes in a distributed machine, on different heterogeneous processors
(CPUs, GPUs, etc.), or may even be stored in different memory layouts
(struct-of-arrays vs array-of-structs, etc.).

For the most part, users of Regent need not be aware of the precise
mapping from logical to physical instances, as this is managed by
Regent on behalf of the use. In fact, we already saw physical regions
in use in the previous tutorial. Any time a task accesses the contents
of a region (via `@`, `.` or `r[...]`), Regent ensures that a physical
region is available on the local processor to support the
access. While this is mostly seamless, it has performance implications
which we will explore in this example.

## Regions are not Initially Mapped

## Inline Mapping

## Mapping for Tasks

## Blocking on Mapping

## Final Code

{% highlight regent %}
import "regent"

local c = regentlib.c

fspace input {
  x : double,
  y : double,
}

fspace output {
  z : double,
}

task main()
  var num_elements = 1024
  var is = ispace(int1d, num_elements)
  var input_lr = region(is, input)
  var output_lr = region(is, output)

  for input_ptr : int1d(input, input_lr) in input_lr do
    (@input_ptr).x = c.drand48()
    input_ptr.y = c.drand48() -- The dereference operator is also optional.
  end

  var alpha = c.drand48()

  for i : int1d(is) in is do
    output_lr[i].z = alpha*input_lr[i].x + input_lr[i].y
  end

  -- Again, with type inference.
  for i in is do
    var expected = alpha*input_lr[i].x + input_lr[i].y
    var received = output_lr[i].z
    regentlib.assert(expected == received, "check failed")
  end
end
regentlib.start(main)
{% endhighlight %}
