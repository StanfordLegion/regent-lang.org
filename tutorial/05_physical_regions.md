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
the following code will *not* cause the program to fail with an out of
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

As noted above, accessing the contents of a region causes it to be
mapped. For the most part, this happens automatically and users don't
need to be concerned with when and how it happens. There, however,
some performance consequences to be considered.

If a region is accessed *anywhere* in a task, Regent needs it to be
available *everywhere* in the task. This means, in the example below,
the region `r` is mapped at the point where it is created, even though
it will not be used until later on in the task.

{% highlight regent %}
some_task()
var r = region(...) -- region is mapped here ...
other_task()
r[0] = 123          -- even though the access happens here
{% endhighlight %}

Mapping a region is a blocking operation. That means `some_task` and
`other_task` in the code example may *not* run in parallel, despite
the fact that neither one refers to `r`, because the creation of `r`
blocks until the mapping is completed.

## Mapping for Tasks

When Regent launches a task, all regions are mapped prior to the
beginning of the execution of the task. This ensures that the task
will not waste processor cycles waiting on the mapping to be complete,
because mapping is performed prior to starting the task execution.

There is one exception: if the task accesses no regions at all, the
task can be considered an *inner* task. This is most commonly used in
tasks that launch other tasks (e.g., as is often true of
`main`). Because Regent knows the task will never access any region
data, none of the regions need to be mapped, either prior to the start
of the task, or when regions are created by the task itself.

Reusing the code example from above, if this were run in an inner
task, `some_task` and `other_task` would be able to run in parallel,
because the region creation no longer blocks on the inline mapping.

{% highlight regent %}
some_task()
var r = region(...) -- no mapping is performed because it's an inner task
other_task()
-- r[0] = 123       -- ERROR: this is now illegal to do in an inner task
{% endhighlight %}

Regent identifies inner tasks automatically. As with index launches,
users who wish to confirm that tasks are being marked as inner can do
so with the annotation `__demand(__inner)`.

{% highlight regent %}
__demand(__inner)
task main()
  ...
end
{% endhighlight %}

This is often considered a best practice with the main task, where in
most cases it is desirable to ensure that `main` doesn't accidentally
access any regions (and therefore cause out of memory errors when
scaling the code).

## Blocking on Mapping

As noted above, mapping a region forces the task to block until the
memory allocation is completed. Blocking is also required whenever a
subtask modifies a region which the parent task is going to
access. For example:

{% highlight regent %}
some_task(r) -- writes to r

-- program blocks here to ensure that r is available for the loop below
for i in r do
  format.println("r[{}] = {}", i, r[i])
end
{% endhighlight %}

This is usually considered bad style in Regent. It would be better to
move the `println` loop into a task, so that the parent doesn't need
to block between `some_task` and the code that reads the region. Of
course, the reading task will still be blocked on the completion of
`some_task`, but at least no unrelated tasks need to be blocked in
this case.

This can also be mitigated by maintaining `__demand(__inner)` on the
main task (and any other tasks that call subtasks).

## DAXPY Example

From this point onward, we're going to be taking a look at a DAXPY
example code. This builds on features described in the last couple of
tutorials, so we won't spend much more time considering the code in
detail. The full code is listed below.

For the first version, we'll write this code without the use of
tasks. Tasks that take regions---and actually access them---require
privileges, the subject of the next tutorial. Until then, we just
write the loops directly into the main task. The accesses to regions
use the `r[...]` syntax described earlier.

The only additional feature to note here is that Regent can call
arbitrary C functions. Here, we're calling `drand48` from the C header
`stdlib.h`. These libc headers are so commonly used in Regent that
`regentlib.c` is provided to offer them by default. Additional headers
can be included into the code by calling
`terralib.includec("header_name.h")` (not shown).

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

  for i in is do
    input_lr[i].x = c.drand48()
    input_lr[i].y = c.drand48()
  end

  var alpha = c.drand48()

  for i : int1d(is) in is do
    output_lr[i].z = alpha*input_lr[i].x + input_lr[i].y
  end

  for i in is do
    var expected = alpha*input_lr[i].x + input_lr[i].y
    var received = output_lr[i].z
    regentlib.assert(expected == received, "check failed")
  end
end
regentlib.start(main)
{% endhighlight %}

## Next Up

Continue to the [next tutorial]({{ "tutorial/06_privileges" |
relative_url }}) to see how privileges are used to provide access to
regions inside of tasks.
