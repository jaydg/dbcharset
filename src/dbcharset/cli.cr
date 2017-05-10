require "ini"
require "option_parser"

class DBCharset
  MYSQL_CONFIG_FILES = %w(/etc/my.cnf /etc/mysql/my.cnf ~/.my.cnf)

  def get_mysql_config(path="")
    username = ""
    password = ""

    if path.empty?
      files = MYSQL_CONFIG_FILES
    else
      files = [path]
    end

    files.each do |filename|
      filename = File.expand_path(filename)
      next unless File.file?(filename)

      configfile = File.read(filename)
      values = INI.parse(configfile)
      if values.has_key?("client")
        values["client"].each do |k, v|
          username = v if k == "user" && username.empty?
          password = v if k == "password" && password.empty?
        end
      end
    end

    return username, password
  end

  def cli
    @user, @password = get_mysql_config

    parser = OptionParser.parse(@options) do |parser|
      parser.banner = "Usage dbcharset [arguments] DATABASE\n"

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

      parser.on(
        "--defaults-file FILE",
        "alternate MySQL client configuration file"
      ) do |opt_defaults_file|
        u, p = get_mysql_config(opt_defaults_file)
        @user = u unless u.empty?
        @password = p unless p.empty?
      end

      parser.on("--version", "Show version information") do
        puts "dbcharset version #{VERSION}"
        exit 0
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
