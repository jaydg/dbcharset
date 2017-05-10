class DBCharset
  private def get_tables(db)
    tables = [] of String
    q = "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES
          WHERE TABLE_SCHEMA=(?)
            AND TABLE_TYPE='BASE TABLE'"

    db.query q, @database do |result|
      result.each do
        tables << result.read(String)
      end
    end
    return tables
  end

  private def get_columns(db, table)
    columns = {} of String => String
    q = "SELECT COLUMN_NAME, COLUMN_TYPE
          FROM INFORMATION_SCHEMA.COLUMNS
          WHERE COLLATION_NAME is not null
            AND TABLE_SCHEMA=(?)
            AND TABLE_NAME=(?)
            AND (CHARACTER_SET_NAME != (?)
              OR COLLATION_NAME != (?))"

    db.query q, @database, table, @charset, @collation do |result|
      result.each do
        columns[result.read(String)] = result.read(String)
      end
    end
    return columns
  end

  def connect
    uri = "mysql://"
    uri += "#{@user}#{':' unless @user.empty? || @password.empty?}#{@password}"
    uri += "#{'@' unless @user.empty? }#{@host}:#{@port}/#{@database}"
    db = DB.open uri

    if @charset.empty?
      # Get the default charset configured for the database
      q = "SELECT default_character_set_name
           FROM information_schema.SCHEMATA
           WHERE SCHEMA_NAME = (?)"
      @charset = db.query_one q, @database, as: String
    end

    if @collation.empty?
      # Get the default collation configured for the database
      q = "SELECT DEFAULT_COLLATION_NAME
           FROM information_schema.SCHEMATA
           WHERE SCHEMA_NAME = (?)"
      @collation = db.query_one q, @database, as: String
    end

    return db
  end
end
