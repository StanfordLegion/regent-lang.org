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

Privileges can also be specified on specific fields within a region.

## Dependence Analysis

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
