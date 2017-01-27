CREATE OR REPLACE FUNCTION bin_equal_width(
  source_table TEXT,  -- input table name
  target_column TEXT, -- input table column name
  output_table TEXT,  -- output table name
  num_bins INTEGER    -- width of each bin interval
) RETURNS TEXT AS $func$
DECLARE
  commandString TEXT;
  newColumnName TEXT;
  min NUMERIC;
  max NUMERIC;
  binWidth NUMERIC;
  currentBin NUMRANGE;
  mviews RECORD;
  numRows INTEGER;
BEGIN
  -- Create output_table if it does not exist
  newColumnName := 'ew_binned_' || quote_ident(target_column);
  commandString := 'CREATE TABLE IF NOT EXISTS ' || quote_ident(output_table)
    || ' (LIKE ' || quote_ident(source_table) || ' INCLUDING ALL)';
  EXECUTE commandString;

  -- Drop the binned column if it exists
  commandString := 'ALTER TABLE ' || quote_ident(output_table)
    || ' DROP COLUMN IF EXISTS ' || newColumnName;
  EXECUTE commandString;

  -- Add the binned column to the output_table
  commandString := 'ALTER TABLE ' || quote_ident(output_table)
    || ' ADD COLUMN ' || newColumnName || ' NUMRANGE';
  EXECUTE commandString;

  -- get the min and max of the target_column to compute the binWidth
  commandString := 'SELECT min(' || quote_ident(source_table) || '.' || quote_ident(target_column) || '),'
    || 'max(' || quote_ident(source_table) || '.' || quote_ident(target_column) || ')'
    || 'INTO min, max'
    || 'FROM source_table';
  EXECUTE commandString;
  binWidth := (max - min) / num_bins;

  -- iterate through the rows in source_table to append bin column and insert into output_table
  numRows := 0;
  commandString := 'SELECT * FROM ' || quote_ident(source_table);
  FOR mviews IN EXECUTE commandString LOOP
    numRows := numRows + 1;
    currentBin := numrange(min, min + bin_width, '[)');
    WHILE mviews.target_column <= lower(currentBin) LOOP
      -- the current bin does not yet capture the current target_column value, increment to next bin
      currentBin := numrange(upper(currentBin), upper(currentBin) + bin_width, '[)');
    END LOOP;
    
    commandString := 'INSERT INTO ' || output_table
      || ' (SELECT * FROM mview'
      || ' JOIN currentBin)';
    EXECUTE commandString;
  END LOOP;
  RETURN 'Successfully binned ' || numRows || ' rows into ' || num_bins || ' bins!';
END;
$func$ LANGUAGE plpgsql;

SELECT bin_equal_width('flight', 'distance', 'test_flight', 10);