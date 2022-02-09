---
layout: page
title: Privileges
sidebar: false
highlight_first: false
permalink: /tutorial/06_privileges/index.html
---

*Privileges* describe the ways in which tasks interact with their
region arguments. This is one of the key cornerstones of the Regent
programming model: privileges allow Regent to determine what a task
will do (to its region arguments) without actually running the
task. Privileges, in combination with the region arguments used, are
the way that Regent determines what tasks may run in parallel.

## Privileges

Regent supports the following privileges:

  * `reads`
  * `writes`
  * `reduces` with one of the following operators: `+`, `-`, `*`, `/`,
    `min` or `max`

Each privilege corresponds to an operation that a task is permitted to
perform on a region.

The `reads` privilege allows a task to read the contents of a region:

{% highlight regent %}
var _ = r[...]
{% endhighlight %}

The `writes` privilege allows a task to write to a region:

{% highlight regent %}
r[...] = ...
{% endhighlight %}

The `reduces` privilege allows a task to apply the corresponding
reduction operator. For example, `+`:

{% highlight regent %}
r[...] += ...
{% endhighlight %}

Or `min`:

{% highlight regent %}
r[...] min= ...
{% endhighlight %}

Privileges can be combined, so `reads` and `writes` can be used to
provide read-write access to a region. In general, any combination of
`reads` or `writes` with `reduces` is upgraded to `reads writes`, so
this is not really a useful combination. Similarly any two reduction
operators (e.g., `reduces +` and `reduces *`) will be upgraded to
`reads writes`. Reductions are most useful on their own.

## Declaring Privileges in a Task

A task can declare privileges in a `where` clause, following the task
arguments. For example, reading a region `r`:

{% highlight regent %}
task read_task(r : region(...))
where reads(r) do
  ...
end
{% endhighlight %}

Or writing:

{% highlight regent %}
task write_task(r : region(...))
where writes(r) do
  ...
end
{% endhighlight %}

Reading and writing:

{% highlight regent %}
task read_write_task(r : region(...))
where reads writes(r) do
  ...
end
{% endhighlight %}

And reducing:

{% highlight regent %}
task sum_task(r : region(...))
where reduces +(r) do
  ...
end
{% endhighlight %}

## Field-Specific Privileges

Privileges can also be specified on specific fields within a
region. The following task reads field `a` and writes field `b` of the
region `r`.

{% highlight regent %}
task read_a_write_b(r : region(...))
where reads(r.a), writes(r.b) do
  ...
end
{% endhighlight %}

Fields can be grouped with `{...}`. (Nested fields, if any, can be
listed this way as well.) Multiple regions can also be combined under
the same privilege for convenience.

{% highlight regent %}
task another_task(r : region(...), s : region(...))
where reads(r.{a, b, c}, s.x), reads writes(r.d.{e, f}) do
  ...
end
{% endhighlight %}

This task:

  * `reads` the fields `r.a`, `r.b`, `r.c`, and `s.x`
  * `reads` and `writes` the fields `r.d.e` and `r.d.f`

## Interference with Privileges

Privileges describe the effects a task has (including mutations) on
its region arguments. These privileges, in combination with the region
arguments passed to the tasks, are used to determine which tasks may
potentially interfere.

  * A task that `writes` a region will interfere with any other task
    that `reads` or `writes` or `reduces` the same region.
  * A task that `reads` a region will *not* interfere with other
    `reads`, but will interfere with `writes` or `reduces`.
  * A task that `reduces OP` will *not* interfere with other `reduces
    OP` (for the same operator `OP`), but will interfere with a
    different operator `OP2`, or with `reads` or `writes`.

These checks are performed on a field-by-field basis, so a task that
`writes(r.a)` will not interfere with a task that `reads(r.b)`.

One important thing to note is that interference is based on a task's
*declared* privileges, rather than the operations a task actually
performs at runtime. Regent's type system ensures that a task does not
perform any operation not identified in its privileges, but it makes no
attempt to check that the task uses all of the privileges that it has
declared.

## Dependence Analysis with Privileges

Regent uses interference to check which tasks may execute in
parallel. Tasks that interfere are serialized, but (assuming the
parent does not block) this does not prevent other non-interfering
tasks from running at the same time.

In the code below, `task_b` depends on `task_a` (and therefore
`task_b` will not begin execution until `task_a` completes), while
`task_c` can run in parallel to the other two.

{% highlight regent %}
task task_a(r : region(...))
where writes(r) do
  ...
end

task task_b(r : region(...))
where reads(r) do
  ...
end

task task_c(r : region(...))
where writes(r) do
  ...
end

task main()
  var s = region(...)
  var t = region(...)

  task_a(s)
  task_b(s)
  task_c(t)
end
{% endhighlight %}

## DAXPY with Privileges

Privileges enable us to write a version of DAXPY more properly in
Regent. This will still be a sequential implementation (in the sense
that it won't do any data partitioning, and therefore won't achieve
parallelism), but it is getting closer to idiomatic Regent code.

The first step is to set up the tasks. The [previous version of the
code]({{ "tutorial/05_physical_regions#final-code" | relative_url }})
had three loops: an initialization loop, a DAXPY loop, and a
verification loop. These are likely to be the time-consuming parts of
the program (especially if we want to scale this DAXPY
implementation), so these are the important parts to put in tasks.

We'll start with the DAXPY loop. The original version of this loop
looked like:

{% highlight regent %}
for i in is do
  output_lr[i].z = alpha*input_lr[i].x + input_lr[i].y
end
{% endhighlight %}

To extract this into a task, we need to start by writing the task
header. This will need to include, at a minimum, the variables
referenced inside the loop (that is, `is`, `input_lr`, `output_lr`,
and `alpha`). Here's what this looks like:

{% highlight regent %}
task daxpy(is : ispace(int1d),
           input_lr : region(is, input),
           output_lr : region(is, output),
           alpha : double)
end
{% endhighlight %}

If we just copy the loop into the body of this task, we'll get a
compile error. The task has no privileges, so it isn't permitted to
access any of the regions it takes as arguments.

To fix this, we need to add a `where` clause to the task
declaration. The privileges can be determined by reading the body of
the loop itself. The loop reads `input_lr.x` and `input_lr.y`, and
writes `output_lr.z`. This translates into the following privilege
clause:

{% highlight regent %}
where writes(output_lr.z), reads(input_lr.{x, y}) do
{% endhighlight %}

Now we can copy the loop body and get the entire thing to compile. The
final version looks like this:

{% highlight regent %}
task daxpy(is : ispace(int1d),
           input_lr : region(is, input),
           output_lr : region(is, output),
           alpha : double)
where writes(output_lr.z), reads(input_lr.{x, y}) do
  for i in is do
    output_lr[i].z = alpha*input_lr[i].x + input_lr[i].y
  end
end
{% endhighlight %}

The process for the other loops is similar. We'll create two
additional tasks, `init` and `check`, to extract each of the
respective loops. The final code is shown below.

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

task init(is : ispace(int1d),
          input_lr : region(is, input))
where writes(input_lr) do
  for i in is do
    input_lr[i].x = c.drand48()
    input_lr[i].y = c.drand48()
  end
end

task daxpy(is : ispace(int1d),
           input_lr : region(is, input),
           output_lr : region(is, output),
           alpha : double)
where writes(output_lr.z), reads(input_lr.{x, y}) do
  for i in is do
    output_lr[i].z = alpha*input_lr[i].x + input_lr[i].y
  end
end

task check(is : ispace(int1d),
           input_lr : region(is, input),
           output_lr : region(is, output),
           alpha : double)
where reads(input_lr, output_lr) do
  for i in is do
    var expected = alpha*input_lr[i].x + input_lr[i].y
    var received = output_lr[i].z
    regentlib.assert(expected == received, "check failed")
  end
end

task main()
  var num_elements = 1024
  var is = ispace(int1d, num_elements)
  var input_lr = region(is, input)
  var output_lr = region(is, output)

  init(is, input_lr)

  var alpha = c.drand48()
  daxpy(is, input_lr, output_lr, alpha)

  check(is, input_lr, output_lr, alpha)
end
regentlib.start(main)
{% endhighlight %}

## Next Up

Continue to the [next tutorial]({{ "tutorial/07_partitions" |
relative_url }}) to see the parallel version of this code with data
partitioning.
