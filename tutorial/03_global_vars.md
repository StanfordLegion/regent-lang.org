---
layout: page
title: Global Variables
sidebar: false
highlight_first: false
permalink: /tutorial/03_global_vars/index.html
---

This example covers some features that are *not* supported by
Regent. In particular, any use of mutable state must be carefully
controlled, because it may be a hazard for parallel and distributed
execution. Regent has features specifically to allow mutable state
(that are safe within the language); these will be considered in a
later tutorial.

## Global Variables

Regent has no mutable global variables.

Lua variables (introduced with `local` outside of a task) are global,
but from Regent's perspective they are fixed at compile time. Remember
that Lua cannot call Regent directly, so the execution of the Lua
portion of a program completes before `regentlib.start` is called. Any
references to Lua variables in Regent are replaced, as if the user had
written directly the value of the variable in the Regent task itself.

So for example, the following program is ok and prints the value `2`:

{% highlight regent %}
local x = 2
task print_x()
  c.printf("value of x is %d\n", x) -- ok, x is replaced by 2 at compile time
end
{% endhighlight %}

On the other hand, it makes no sense to attempt to modify a Lua
variable inside Regent. In the code below, `x` is replaced by `2`,
resulting in the nonsensical assignment `2 = 3`. This fails with a
compile error.

{% highlight regent %}
local x = 2
task set_x()
  x = 3 -- ERROR: expected an lvalue but got int32
end
{% endhighlight %}

## Pointers

Regent allows calls to C functions, and permits the use of C
pointers. However, these features must be used carefully. Consider,
for example, that a subtask may execute on a processor in a different
address space (on a different node in a distributed machine) than its
parent---so a pointer passed from parent to child might not be valid,
and could result in a crash. In most cases it is not safe to pass C
pointers to Regent tasks, and Regent will issue a warning if this is
attempted.

For further reading on restrictions to the use of pointers, see the
discussion in the [Legion
tutorial](http://legion.stanford.edu/tutorial/hybrid.html).

## Final Code

{% highlight regent %}
import "regent"

local c = regentlib.c

local global_constant = 4

task main()
  c.printf("The value of global_constant %d will always be the same\n", global_constant)
  c.printf("The function pointer to printf %p may be different on different processors\n", c.printf)
end
regentlib.start(main)
{% endhighlight %}
