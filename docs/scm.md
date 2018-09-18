## SCM

### Orders

The *SCM* module expands the *Sales* module by replacing several views and
functions that allow *Items* to appear in *Orders*.

*Items* are added as prototypes. This means that any changes made to the *Item*
will show on any *Orders* that list that *Item*.  To make the *Item* specific to
a particular *Order*, the *Item* must be unlinked.  Unlinking an *Item* will
make a copy of the *Item* in question and allow any changes made to be specific
to the *Order*.

You can add a blank *Item* to an order.  This allows the *Item* to be specified
from scratch for the *Order*.  However, it is much more convenient to use a
previously defined *Item*.
