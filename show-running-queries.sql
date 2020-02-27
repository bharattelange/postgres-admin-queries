SELECT pid, age(clock_timestamp(), query_start), usename, query, state
FROM pg_stat_activity
WHERE state not like 'idle%' AND query NOT ILIKE '%pg_stat_activity%'
ORDER BY query_start desc;
