---
layout: page
title: Privileges
sidebar: false
highlight_first: false
permalink: /tutorial/06_privileges/index.html
---

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

local c = terralib.includec("stdlib.h")

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
