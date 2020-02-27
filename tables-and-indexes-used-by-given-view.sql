with recursive view_tree(parent_schema, parent_obj, child_schema, child_obj, ind, ord) as 
(
  select vtu_parent.view_schema, vtu_parent.view_name, 
    vtu_parent.table_schema, vtu_parent.table_name, 
    '', array[row_number() over (order by view_schema, view_name)]
  from information_schema.view_table_usage vtu_parent
  where vtu_parent.view_schema = 'public' and vtu_parent.view_name = 'pg_stat_activity'
  union all
  select vtu_child.view_schema, vtu_child.view_name, 
    vtu_child.table_schema, vtu_child.table_name, 
    vtu_parent.ind || '  ', 
    vtu_parent.ord || (row_number() over (order by view_schema, view_name))
  from view_tree vtu_parent, information_schema.view_table_usage vtu_child
  where vtu_child.view_schema = vtu_parent.child_schema 
  and vtu_child.view_name = vtu_parent.child_obj
) 
select tree.ind || tree.parent_schema || '.' || tree.parent_obj 
  || ' depends on ' || tree.child_schema || '.' || tree.child_obj txt, tree.ord
from view_tree tree
order by ord;
