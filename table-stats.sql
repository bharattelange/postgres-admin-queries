select relname, n_dead_tup, last_vacuum, last_autovacuum from 
pg_catalog.pg_stat_all_tables
where n_dead_tup > 0 and relname =  'table1' order by n_dead_tup desc;
