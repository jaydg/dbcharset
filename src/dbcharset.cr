require "mysql"
require "progress"

require "./dbcharset/*"

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

  def run
    self.cli

    begin
      db = self.connect

      puts "Converting all tables and columns in database #{@database}:\n
        character set: #{@charset}
        collation:     #{@collation}\n\n"

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
