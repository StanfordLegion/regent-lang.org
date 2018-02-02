---
layout: page
title: Logical Regions
sidebar: false
highlight_first: false
permalink: /tutorial/04_logical_regions/index.html
---

(The text for this tutorial has not been written yet.)

{% highlight regent %}
import "regent"

local c = terralib.includec("stdio.h")

-- A field space (fspace) is a collection of fields, similar to a
-- C struct.
fspace fs {
  a : double,
  {b, c, d} : int, -- Multiple fields may be declared with a single type.
}

task main()
  -- An index space (ispace) is a collection in index points. Regent
  -- has two kinds of index spaces: structured and unstructured.

  -- An unstructured ispace is a collection of opaque points, useful
  -- for pointer data structures such as graphs, trees, linked lists,
  -- and unstructured meshes. The following line creates an ispace
  -- with 1024 elements.
  var unstructured_is = ispace(ptr, 1024)

  -- A structured ispace is (multi-dimensional) rectangle of
  -- points. The space below includes the 1-dimensional ints from 0 to 1023.
  var structured_is = ispace(int1d, 1024, 0)

  -- A region is the cross product between an ispace and an fspace.
  var unstructured_lr = region(unstructured_is, fs)
  var structured_lr = region(structured_is, fs)

  -- Note that you can create multiple regions with the same ispace
  -- and fspace. This is a **NEW** region, distint from structured_lr
  -- above.
  var no_clone_lr = region(structured_is, fs)
end
regentlib.start(main)
{% endhighlight %}
