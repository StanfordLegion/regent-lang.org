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

Privileges are enforced by the type system, which will throw an exception when detecting an invalid access.

Beyond `reads` and `writes`, reductions (+, *, -, /, min, max) allow the application of certain commutative operators to regions.

{% highlight regent %}
task sum_output(is : ispace(int1d),
           input_lr : region(is, input),
           output_lr : region(is, output),
           alpha : double)
where reads reduces +(output_lr.z), reads(input_lr.{x, y}) do
  for i in is do
    output_lr[i].z += alpha*input_lr[i].x + input_lr[i].y
  end
end

task max_output(is : ispace(int1d),
           input_lr : region(is, input),
           output_lr : region(is, output),
           alpha : double)
where reads reduces max(output_lr.z), reads(input_lr.{x, y}) do
  for i in is do
    output_lr[i].z max = max(alpha*input_lr[i].x, output_lr[i].z)
  end
end
{% endhighlight %}
