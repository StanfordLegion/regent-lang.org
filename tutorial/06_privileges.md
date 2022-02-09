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
peform any operation not identified in its privileges, but it makes no
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

Privileges describe how a task interacts with region-typed arguments. For example, `reads` is required in order to read from a region argument, and `writes` is required to modify a region.

{% highlight regent %}
task daxpy(is : ispace(int1d),
           input_lr : region(is, input),
           output_lr : region(is, output),
           alpha : double)
-- Multiple privileges may be specified at once. Privileges may also
-- apply to specific fields. (Multiple fields can be named with braces.)
where reads writes(output_lr.z), reads(input_lr.{x, y}) do
  for i in is do
    output_lr[i].z = alpha*input_lr[i].x + input_lr[i].y
  end
end
{% endhighlight %}

Privileges are enforced by the type system, and a compile error will be issued if the declared privileges are violated.

Beyond `reads` and `writes`, reductions (`+`, `*`, `-`, `/`, `min`, `max`) allow the application of certain commutative operators to the elements of regions.

{% highlight regent %}
task sum_output(is : ispace(int1d),
                input_lr : region(is, input),
                output_lr : region(is, output),
                alpha : double)
where reduces +(output_lr.z), reads(input_lr.{x, y}) do
  for i in is do
    output_lr[i].z += alpha*input_lr[i].x + input_lr[i].y
  end
end

task max_output(is : ispace(int1d),
           input_lr : region(is, input),
           output_lr : region(is, output),
           alpha : double)
where reduces max(output_lr.z), reads(input_lr.{x, y}) do
  for i in is do
    output_lr[i].z max= alpha*input_lr[i].x
  end
end
{% endhighlight %}

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
where reads writes(output_lr.z), reads(input_lr.{x, y}) do
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
