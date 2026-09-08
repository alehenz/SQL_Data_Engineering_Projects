-- UNION returns all rows from A and B. Duplicates eliminated.
SELECT UNNEST([1, 1, 1, 2])
UNION
SELECT UNNEST([1, 1, 3]);
/*
┌─────────────────────────────────────┐
│ unnest(main.list_value(1, 1, 1, 2)) │
│                int32                │
├─────────────────────────────────────┤
│                                   3 │
│                                   2 │
│                                   1 │
└─────────────────────────────────────┘
*/
-- UNION ALL returns all rows from A and B. Duplicates preserved.
SELECT UNNEST([1, 1, 1, 2])
UNION ALL
SELECT UNNEST([1, 1, 3]);
/*
┌─────────────────────────────────────┐
│ unnest(main.list_value(1, 1, 1, 2)) │
│                int32                │
├─────────────────────────────────────┤
│                                   1 │
│                                   1 │
│                                   1 │
│                                   2 │
│                                   1 │
│                                   1 │
│                                   3 │
└─────────────────────────────────────┘
*/

-- INTERSECT returns only rows common to A and B. Duplicates removed.
SELECT UNNEST([1, 1, 1, 2])
INTERSECT
SELECT UNNEST([1, 1, 3]);
/*
┌─────────────────────────────────────┐
│ unnest(main.list_value(1, 1, 1, 2)) │
│                int32                │
├─────────────────────────────────────┤
│                                   1 │
└─────────────────────────────────────┘
*/

-- INTERSECT ALL returns only rows common to A and B. Duplicates preserved. Note that this performs a row by row revision of duplicity.
-- In the following example, the result gives only 2 1's instead of 3, since that is the corresponding intersection.
SELECT UNNEST([1, 1, 1, 2])
INTERSECT ALL
SELECT UNNEST([1, 1, 3]);
/*
┌─────────────────────────────────────┐
│ unnest(main.list_value(1, 1, 1, 2)) │
│                int32                │
├─────────────────────────────────────┤
│                                   1 │
│                                   1 │
└─────────────────────────────────────┘
*/

-- EXCEPT returns rows in A but not in B. Duplicates removed. This results in all the values that are only in table A (hence, not in B)
SELECT UNNEST([1, 1, 1, 2])
EXCEPT
SELECT UNNEST([1, 1, 3]);
/*
┌─────────────────────────────────────┐
│ unnest(main.list_value(1, 1, 1, 2)) │
│                int32                │
├─────────────────────────────────────┤
│                                   2 │
└─────────────────────────────────────┘
*/
-- EXCEPT ALL returns rows in A minus rows in B. Duplicates removed one-for-one.
SELECT UNNEST([1, 1, 1, 2])
EXCEPT ALL
SELECT UNNEST([1, 1, 3]);
/*
┌─────────────────────────────────────┐
│ unnest(main.list_value(1, 1, 1, 2)) │
│                int32                │
├─────────────────────────────────────┤
│                                   2 │
│                                   1 │
└─────────────────────────────────────┘
*/