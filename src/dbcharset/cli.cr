require "option_parser"

class DBCharset
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
end
