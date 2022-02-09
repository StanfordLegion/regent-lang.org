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
nodes in a distributed machine, in different heterogeneous memories
(CPU memory, GPU memory, etc.), or may even be stored in different
memory layouts (struct-of-arrays vs array-of-structs, etc.).

For the most part, users of Regent need not be aware of the precise
mapping from logical to physical instances, as this is managed by
Regent on behalf of the use. In fact, we already saw physical regions
in use in the previous tutorial. Any time a task accesses the contents
of a region (via `@`, `.` or `r[...]`), Regent ensures that a physical
region is available on the local processor to support the
access. While this is mostly seamless in Regent, it has performance
implications that can be important.

In this example, we will consider *when* regions need to be mapped to
instances (i.e., what parts of a program require a region to be
mapped), and largely ignore the question of *where* (i.e., to what
memories) regions are mapped. The latter is the domain of *mapping* in
Regent, and will be the subject of a future tutorial.

## Regions are not Initially Mapped

With one caveat, regions need not be initially mapped at all. That is,
the following code will not cause the program to fail with an out of
memory error, even if `size_of_the_universe` is very large.

{% highlight regent %}
var r = region(ispace(int1d, size_of_the_universe), int)
{% endhighlight %}

This property is very important, because it is common and desirable to
use Regent on distributed machines where no single memory may be large
enough to fit all of the data in the program.

This example also demonstrates a core principle of idiomatic Regent
programming: generally speaking, even if the data will eventually be
distributed (and may even be too large to fit in any single memory),
it is still best to create a single region that contains all of
it. Such a region can then be partitioned into smaller pieces that
will be directly used in the program. Partitioning, as mentioned
previously, is the subject of a future tutorial.

There is, however, a caveat: Regent allocates a region in memory if it
believes it may be accessed within a task. That means that if the code
above is followed by something like:

{% highlight regent %}
r[0] = 123
{% endhighlight %}

Then Regent will attempt to allocate the region, causing an out of
memory failure (since it does not actually fit in memory).

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
