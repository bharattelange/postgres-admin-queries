  SELECT relation::regclass, * FROM pg_locks WHERE NOT GRANTED;

