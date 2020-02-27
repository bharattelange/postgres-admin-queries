-- table index usage rates (should not be less than 0.99)
-- SELECT relname, 100 * idx_scan / (seq_scan + idx_scan) percent_of_times_index_used, n_live_tup rows_in_table
-- FROM pg_stat_user_tables 
-- ORDER BY n_live_tup DESC;

-- table index usage rates (should not be less than 0.99)
SELECT relname,
  CASE WHEN (seq_scan + idx_scan) != 0
    THEN 100.0 * idx_scan / (seq_scan + idx_scan)
    ELSE 0
  END AS percent_of_times_index_used,
  n_live_tup AS rows_in_table
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;
