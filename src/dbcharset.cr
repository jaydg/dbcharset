require "mysql"
require "option_parser"
require "progress"

class DBCharset
  def initialize(@options : Array(String))
    @database = ""
    @host = "localhost"
    @port = 3306
    @user = ""
    @password = ""
    @charset = ""
    @collation = ""
  end

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

  def convert(db, tables)
    bar = ProgressBar.new
    bar.width = 60
    bar.total = tables.size
    db.exec "SET foreign_key_checks = 0"
    tables.each do |table|
      bar.inc
      q = "ALTER TABLE `#{table}`
           CONVERT TO CHARACTER SET `#{@charset}`
           COLLATE `#{@collation}`"

      db.exec q, table

      get_columns(db, table).each do |column, type|
        q = "ALTER TABLE `#{table}`
            CHANGE `#{column}` `#{column}` #{type}
            CHARACTER SET #{@charset} COLLATE #{@collation}"
      end

    end
    db.exec "SET foreign_key_checks = 1"
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

  def cli
    parser = OptionParser.parse(@options) do |parser|
      parser.banner = "Usage dbconvert [arguments] DATABASE"

      parser.on(
        "-c CHARSET", "--charset CHARSET",
        "Target charset (default charset is determined from database)"
      ) do |opt_charset|
        @charset = opt_charset
      end

      parser.on(
        "-C COLLATION", "--collation COLLATION",
        "Target collation (default collation is determined from database)"
      ) do |opt_collation|
        @collation = opt_collation
      end

      parser.on(
        "-h HOST", "--host HOST",
        "MySQL host name (default: #{@host})"
      ) do |opt_host|
        @host = opt_host
      end

      parser.on(
        "-P PORT",
        "--port PORT", "MySQL port (default: #{@port})"
      ) do |opt_port|
        @port = opt_port.to_i
      end

      parser.on(
        "-u USER",
        "--user USER", "MySQL user name"
      ) do |opt_user|
        @user = opt_user
      end

      parser.on(
        "-p PASSWORD", "--password PASSWORD",
        "MySQL password"
      ) do |opt_pass|
        @password = opt_pass
      end

      parser.on("--help", "Show this help") do
        puts parser
        exit 0
      end
    end

    unless @options.size == 1
      puts "Please specify a database to convert!"
      puts
      puts parser
      exit 1
    end

    @database = @options.first
  end

  def run
    self.cli

    begin
      db = self.connect

      puts "Converting all tables and columns in database #{@database}:\n
        character set: #{@charset}
        collation:     #{@collation}.\n\n"

      convert(db, get_tables(db))
    rescue ex
      puts "#{ex}"
      exit 1
    ensure
      db.close unless db.nil?
    end
  end

  def self.run(options = ARGV)
    new(options).run
  end
end


DBCharset.run