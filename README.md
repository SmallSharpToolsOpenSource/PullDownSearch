# Pull Down Search

Placing a search field at the top of a collection view which is
initially pushed out of view is common in may iOS apps including
apps made by Apple. This sample project shows how it can be
accomplished with a collection view.

### The Problem

The problem to solve when placing a search text field in a
collection view arises when the data is reloaded and all cells
and supplementary views are refreshed and the text field is
removed and stops being the first responder and the keyboard
is dismissed. When the user is typing in their search terms
reloading the collection view will cause the first responder
for the text field to be resigned, interrupting their 
interaction with the text field.

### Solution

One solution is to not reload all sections in the collection
view and instead just reload the affected sections. If the
collection is showing many items and is displaying an index
to each section it will be hard to know which sections need
to be reloaded. But if the index is not shown while the search
is active it is possible to instead collapse all items to a
single section making it very easy to reload just a single
section. That is how this solution works.

### Notes

One difference between table views and collection views is the
use of supplemetary views instead of just header and footer 
views. An important detail is that for a section showing a
supplementary view there does not have to be any regular cells
for that section. Therefore it was not necessary to create
cells to add to the top section used for search of the last
section used for the footer.

The supplementary views still want to show for every section,
so to hide them the size of `CGSizeZero` is returned when they
are not meant to show. It would be preferrable to return nil
for a section which should not display a view but doing so
results in an exception. The docs for this delegate method
state that nil should not be returned. The way this works
seems to be extra work.

Alternatively the supplemetary view for the search field could
be implemented as a regular cell.

### License

MIT

---
Brennan Stehling - 2016
 