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

  private def get_default_charset(db)
    q = "SELECT default_character_set_name
         FROM information_schema.SCHEMATA
         WHERE SCHEMA_NAME = (?)"
    db.query_one q, @database, as: String
  end

  private def get_default_collation(db)
    q = "SELECT DEFAULT_COLLATION_NAME
         FROM information_schema.SCHEMATA
         WHERE SCHEMA_NAME = (?)"
    db.query_one q, @database, as: String
  end

  private def set_database_defaults(db)
    q = "ALTER DATABASE `#{@database}`
         CHARACTER SET `#{@charset}`
         COLLATE `#{@collation}`"

    # ALTER DATABASE is not supported in prepared statements
    db.unprepared(q).exec
  end

  private def convert_table(db, table)
    q = "ALTER TABLE `#{table}`
         CONVERT TO CHARACTER SET `#{@charset}`
         COLLATE `#{@collation}`"
    db.exec q

    get_columns(db, table).each do |column, type|
      q = "ALTER TABLE `#{table}`
          CHANGE `#{column}` `#{column}` #{type}
          CHARACTER SET #{@charset} COLLATE #{@collation}"
    end
  end

  def connect
    uri = "mysql://"
    uri += "#{@user}#{':' unless @user.empty? || @password.empty?}#{@password}"
    uri += "#{'@' unless @user.empty? }#{@host}:#{@port}/#{@database}"
    db = DB.open uri

    if @charset.empty?
    # Get the default charset configured for the database
      @charset = get_default_charset(db)
    end

    if @collation.empty?
      # Get the default collation configured for the database
      @collation = get_default_collation(db)
    end

    return db
  end
end
