---
layout: page
title: Global Variables
sidebar: false
highlight_first: false
permalink: /tutorial/03_global_vars/index.html
---

Regent has no global variables. C-style pointers are allowed, but must
be used with caution. Mechanisms within the language for achieving
mutable state are discussed in later tutorials.

## Lua Variables

Regent has no concept of a global variable. Technically, Lua variables
are global, but from Regent's perspective they are fixed at compile
time. For example, the code below is equivalent to attempting the
assignment `2 = 3`, and fails with a compile error.

{% highlight regent %}
local x = 2
task set_x()
  x = 3 -- ERROR: expected an lvalue but got int32
end
{% endhighlight %}

## Pointers

Regent allows calls to C functions, and permits the use of C
pointers. However, these features must be used carefully in order to
comply with the Legion programming model. Consider, for example, that
a subtask may execute on a different processor than its parent---so a
pointer passed from parent to child might not be valid, and could
result in a crash.

Similarly, pointers to C functions may vary between processors and
should not be relied upon to be stable.

The restrictions of the Legion programming model are discussed in the
[C++ tutorial](http://legion.stanford.edu/tutorial/hybrid.html).

## Final Code

{% highlight regent %}
import "regent"

local c = terralib.includec("stdio.h")

local global_constant = 4

task main()
  c.printf("The value of global_constant %d will always be the same\n", global_constant)
  c.printf("The function pointer to printf %p may be different on different processors\n", c.printf)
end
regentlib.start(main)
{% endhighlight %}
