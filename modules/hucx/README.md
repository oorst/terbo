# HUCX DATA

Hucx data represents elements and the blocks that make up the elements.
Composition of elements also involves product information.  So the HUCX schema
has the product Schema as a dependency.

## Elements

Elements are the highest level units in a building's composition. Elements are
composed of Blocks and Products.  Blocks and Products may in turn have their
own lower levels of composition.

## Blocks

Blocks are the main composition units of elements.  Blocks are composed of
Parts and Products.

A Block's definition is shown here in JSON5 format:

```JSON5
{
  guid: xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx,
  finishedHeight: 2400,
  finishedWidth: 1100,
  type: 'wall' | 'floor' | 'roof',
}
```

#### Parts

Parts are the individual pieces that are manufactured and made into a block.
