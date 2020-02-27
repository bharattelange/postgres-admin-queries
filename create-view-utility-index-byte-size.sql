CREATE VIEW utility.index_byte_sizes AS
SELECT rel.oid AS relid, pg_index.indexrelid, pg_namespace.nspname, rel.relname, idx.relname AS indexrelname,
 pg_index.indisunique AS is_key,
 ((ceil(idx.reltuples
 * ((constants.index_tuple_header_size
 + constants.item_id_data_size
 + CASE WHEN (COALESCE(SUM(CASE WHEN statts.staattnotnull THEN 0 ELSE 1 END), 0::BIGINT)
 + ((SELECT COALESCE(SUM(CASE WHEN atts.attnotnull THEN 0 ELSE 1 END), 0::BIGINT)
 FROM pg_attribute atts
JOIN (SELECT pg_index.indkey[the.i] AS attnum
 FROM generate_series(0, pg_index.indnatts - 1) the(i)) cols
 ON atts.attnum = cols.attnum
 WHERE atts.attrelid = pg_index.indrelid))) > 0
 THEN (SELECT the.null_bitmap_size + constants.max_align
 - CASE WHEN (the.null_bitmap_size % constants.max_align) = 0 THEN constants.max_align
 ELSE the.null_bitmap_size % constants.max_align END
 FROM (VALUES (pg_index.indnatts / 8
 + CASE WHEN (pg_index.indnatts % 8) = 0 THEN 0 ELSE 1 END)) the(null_bitmap_size))
 ELSE 0 END)::DOUBLE PRECISION
 + COALESCE(SUM(statts.stawidth::DOUBLE PRECISION * (1::DOUBLE PRECISION - statts.stanullfrac)), 0::DOUBLE PRECISION)
 + COALESCE((SELECT SUM(atts.stawidth::DOUBLE PRECISION * (1::DOUBLE PRECISION - atts.stanullfrac))
 FROM pg_statistic atts
JOIN (SELECT pg_index.indkey[the.i] AS attnum
 FROM generate_series(0, pg_index.indnatts - 1) the(i)) cols
 ON atts.staattnum = cols.attnum
 WHERE atts.starelid = pg_index.indrelid), 0::DOUBLE PRECISION))
 / (constants.block_size - constants.page_header_data_size::NUMERIC - constants.special_space::NUMERIC)::DOUBLE PRECISION)
 + constants.index_metadata_pages::DOUBLE PRECISION)
 * constants.block_size::DOUBLE PRECISION)::BIGINT AS ideal_idxsize,
 (idx.relpages::NUMERIC * constants.block_size)::BIGINT AS idxsize
 FROM pg_index
 JOIN pg_class idx ON pg_index.indexrelid = idx.oid
 JOIN pg_class rel ON pg_index.indrelid = rel.oid
 JOIN pg_namespace ON idx.relnamespace = pg_namespace.oid
 LEFT JOIN (SELECT pg_statistic.starelid, pg_statistic.staattnum,
 pg_statistic.stanullfrac, pg_statistic.stawidth,
 pg_attribute.attnotnull AS staattnotnull
 FROM pg_statistic
 JOIN pg_attribute ON pg_statistic.starelid = pg_attribute.attrelid
 AND pg_statistic.staattnum = pg_attribute.attnum) statts
 ON statts.starelid = idx.oid
 CROSS JOIN (SELECT current_setting('block_size'::TEXT)::NUMERIC AS block_size,
 CASE WHEN substring(version(), 12, 3) = ANY (ARRAY['8.0'::TEXT, '8.1'::TEXT, '8.2'::TEXT]) THEN 27
 ELSE 23 END AS tuple_header_size,
 CASE WHEN version() ~ 'mingw32'::TEXT THEN 8
 ELSE 4 END AS max_align,
 8 AS index_tuple_header_size,
 4 AS item_id_data_size,
 24 AS page_header_data_size,
 0 AS special_space,
 1 AS index_metadata_pages) constants
 GROUP BY pg_namespace.nspname, rel.relname, rel.oid, idx.relname, idx.reltuples, idx.relpages,
 pg_index.indexrelid, pg_index.indrelid, pg_index.indkey, pg_index.indnatts, pg_index.indisunique,
 constants.block_size, constants.tuple_header_size, constants.max_align, constants.index_tuple_header_size,
 constants.item_id_data_size, constants.page_header_data_size, constants.index_metadata_pages, constants.special_space;
