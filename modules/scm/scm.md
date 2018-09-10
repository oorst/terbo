## Supply Chain Management

#### Prerequisites

- Product
- Logistics

## Items

All items must be associated with a Product.

#### Parts

## Routing

Routing is a way to describe the path that an item takes through it's
manufacturing process.

A route is made up of tasks and other routes. Sub routes are a way to group
similar tasks in a complex route or to allow for work that might be
outsourced to another manufacturer.

#### Routes

A route is an ordered collection of tasks or sub-routes.

#### Tasks

All *Tasks* must be associated with a *Product*. Whilst not strictly
necessary, the *Product* that a *Task* is associated with should have the type
`service`, so that the Bill of Quantities can accurately list work and
materials.

#### Sub-routes

Sub routes are normal routes that are part of another route.  In this way
they are a stand in for a task.
