select state as "State",count(*) as "Connections" from pg_stat_activity group by state union select 'Total', count(*) from pg_stat_activity ;


