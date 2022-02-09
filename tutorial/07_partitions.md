---
layout: page
title: Partitions
sidebar: false
highlight_first: false
permalink: /tutorial/07_partitions/index.html
---

In theory, tasks and regions are enough to induce a parallel
execution. If you create `N` regions, and `N` tasks, those will all be
able to run in parallel. But it's a lot more pleasant---and more
efficient too---to use data partitioning. Partitioning also opens the
door to much more powerful tools down the road, like using multiple
partitions to implement ghost cell exchanges.

For now, we're going to look at what can be achieved with a single
partition of the data.

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

The `equal` operator is always guarranteed to produce subregions that
satisfy certain relationships. In particular:

  * The subregions `p[i]` and `p[j]` are guarranteed to be *disjoint*
    (that is, they do not contain any common elements), for all `i !=
    j`.

  * The subregions of `p`, taken as a whole, are guarranteed to be
    *complete*. That is, the union of `p[i]` for all `i` is equal to
    the original parent region.

These properties are *not* guarranted to hold for all possible
partitions. There are partitions in Regent that are *aliased* (`p[i]`
overlaps `p[j]` for some `i != j`), and ones that are *incomplete*
(the union of subregions does not cover the parent region). In fact,
these are some of the most interesting and useful partitions. But for
now, we'll stick with the `equal` operator and its disjoint and
complete partitions.

## Subregions are Views

## Partitioning Operators

## Passing Partitions to Tasks

## DAXPY with Partitions

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
