---
layout: page
title: Partitions
sidebar: false
highlight_first: false
permalink: /tutorial/07_partitions/index.html
---

In theory, tasks and regions are sufficient for parallel execution. If
you create `N` regions, and `N` tasks, those will all be able to run
in parallel. But it's more pleasant---and more efficient too---to use
data partitioning. Partitioning provides a way to describe the subsets
of a region's elements needed for a given task, without needing to
grab the entire thing. This enables parallelism (tasks using different
subsets can run in parallel) and also opens the door to more advanced
techniques that we'll see in future tutorials.

## Partitions

*Partitions* divide regions into a number of subregions. There are
many partitioning operators, but the most basic is `equal`. The
`equal` operator creates a specified number of roughly equal-sized
subregions. (The subregions are only *roughly* equal-sized because the
number of subregions created may not evenly divide the region being
divided.)

The following code divides `r` into `N` subregions:

{% highlight regent %}
var p = partition(equal, r, ispace(int1d, N))
{% endhighlight %}

Having partitioned `r` as `p`, we can then access the `i`th subregion
as `p[i]`. This enables us to write, for example, a loop of tasks over
the subregions of a partition.

{% highlight regent %}
for i = 0, N do
  some_task(p[i])
end
{% endhighlight %}

The `equal` operator is always guaranteed to produce subregions that
satisfy certain relationships. In particular:

  * The subregions `p[i]` and `p[j]` are guaranteed to be *disjoint*
    (that is, they do not contain any common elements), for all `i !=
    j`.

  * The subregions of `p`, taken as a whole, are guaranteed to be
    *complete*. That is, the union of `p[i]` for all `i` is equal to
    the original parent region.

These properties are *not* guaranteed to hold for all possible
partitions. There are partitions in Regent that are *aliased* (`p[i]`
overlaps `p[j]` for some `i != j`), and ones that are *incomplete*
(the union of subregions does not cover the parent region). We'll see
more of these partitions in future tutorials. But for now, we'll stick
with the `equal` operator and its disjoint and complete partitions.

## Subregions are Views

One of the most important properties of subregions is that they are
*views* onto their parent regions. That is, they do not copy their
elements from the parent, but refer to the parent's data
directly. This means that changes in the subregion are visible in the
parent, and vice versa. (While we haven't seen any aliased partitions
yet, it also means that when two subregions overlap, changes in one
are visible in the other.)

This is easiest to see if we create a simple program with one
partition:

{% highlight regent %}
var r = region(ispace(int1d, 10), int)
var p = partition(equal, r, ispace(int1d, 2))
var s = p[0]
{% endhighlight %}

Here, `s` is the first subregion of `r` via `p`. The parent region `r`
contains elements `0` through `9`, while `s` contains elements `0`
through `4`.

If we write to `s`, we'll see that those changes can be seen in `r` as
well:

{% highlight regent %}
s[0] = 123
format.println("the value of s[0] is {}", s[0]) -- prints 123
format.println("the value of r[0] is {}", r[0]) -- prints 123
{% endhighlight %}

Similarly, we can go the other direction:

{% highlight regent %}
r[4] = 456
format.println("the value of r[4] is {}", r[4]) -- prints 456
format.println("the value of s[4] is {}", s[4]) -- prints 456
{% endhighlight %}

We'll get back to this in the next tutorial, and how it interacts with
multiple partitions of a region. For now, remember that subregions are
views and refer directly to their parent's elements.

## Passing Partitions to Tasks

Partitions can be passed to tasks and returned from tasks. One thing
to keep in mind is the type of a partition includes the parent region
it is derived from. Therefore, when passing a partition to a task, it
is necessary to pass the parent region as well.

This task:

{% highlight regent %}
task takes_partition(t : region(ispace(int1d), int),
                     q : partition(disjoint, t, ispace(int1d)))
{% endhighlight %}

Can be called as:

{% highlight regent %}
var r = region(ispace(int1d, 10), int)
var p = partition(equal, r, ispace(int1d, 2))
takes_partition(r, p)
{% endhighlight %}

Partitions, unlike regions, cannot take privileges. If you need
privileges on the subregions of a partition, specify them on the
corresponding parent region.

## DAXPY with Partitions

We can now use partitions to build a data-parallel version of
DAXPY. Fortunately, we've already done most of the work in the
[previous version of the code]({{ "tutorial/06_privileges#final-code"
| relative_url }}). The tasks, in particular, do not need to be
modified at all. While originally intended to operate on the entire
input and output regions defined in the program, they'll work fine on
subsets of the data as well. Thus, all we need to do is change `main`
to set up the partitions, and create new loops to launch the tasks.

(It is not always the case that tasks written without partitioning in
mind will work seamlessly with partitioning, but it is true to a
surprising degree.)

Recall, from before, that we have two regions we need to be concerned
with: `input_lr` and `output_lr`. The code for these regions is
reproduced below.

{% highlight regent %}
var num_elements = 1024
var is = ispace(int1d, num_elements)
var input_lr = region(is, input)
var output_lr = region(is, output)
{% endhighlight %}

To introduce data parallelism, we need to partition these
regions. We'll create a basic four-way partition to start. (In
practice, one would normally want this to be configurable so that it
can easily scale with the machine, but we'll leave it fixed for now.)
The `equal` operator makes it easy to set these partitions up.

{% highlight regent %}
var num_subregions = 4
var ps = ispace(int1d, num_subregions)
var input_lp = partition(equal, input_lr, ps)
var output_lp = partition(equal, output_lr, ps)
{% endhighlight %}

At this point, we also want to change the task launches to use the
partitions. For example, where we used to have one call to `daxpy` on
the entire `input_lr` and `output_lr`, we'll now have four calls with
each of the pieces of `input_lp` and `output_lp`.

{% highlight regent %}
__demand(__index_launch)
for i in ps do
  daxpy(input_lp[i], output_lp[i], alpha)
end
{% endhighlight %}

We also took the opportunity to mark the loop as
`__demand(__index_launch)`. This instructs the compiler to verify that
the loop is eligible to be executed in parallel.

In fact, because each of the partitions is disjoint, the tasks do
indeed run in parallel. This gives us the parallel implementation of
DAXPY.

The final code (shown below) is now written in a form that is parallel
and would run distributed if we had an appropriate machine to run
on. For DAXPY, there's not much more to do. However, many applications
involve data access patterns that are more complicated than DAXPY (for
example, halo or ghost cell exchanges). We'll consider those
applications in a future tutorial.

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

task init(input_lr : region(ispace(int1d), input))
where writes(input_lr.{x, y}) do
  for i in input_lr do
    input_lr[i].x = c.drand48()
    input_lr[i].y = c.drand48()
  end
end

task daxpy(input_lr : region(ispace(int1d), input),
           output_lr : region(ispace(int1d), output),
           alpha : double)
where writes(output_lr.z), reads(input_lr.{x, y}) do
  for i in input_lr do
    output_lr[i].z = alpha*input_lr[i].x + input_lr[i].y
  end
end

task check(input_lr : region(ispace(int1d), input),
           output_lr : region(ispace(int1d), output),
           alpha : double)
where reads(input_lr, output_lr) do
  for i in input_lr do
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

  var num_subregions = 4
  var ps = ispace(int1d, num_subregions)
  var input_lp = partition(equal, input_lr, ps)
  var output_lp = partition(equal, output_lr, ps)

  __demand(__index_launch)
  for i in ps do
    init(input_lp[i])
  end

  var alpha = c.drand48()
  __demand(__index_launch)
  for i in ps do
    daxpy(input_lp[i], output_lp[i], alpha)
  end

  __demand(__index_launch)
  for i in ps do
    check(input_lp[i], output_lp[i], alpha)
  end
end
regentlib.start(main)
{% endhighlight %}
