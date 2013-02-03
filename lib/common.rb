require 'open-uri'
require 'date'
require 'yaml'

##################################### ARGS #####################################

def verify_var ( arg, type )
  raise ArgumentError, %Q`'#{arg}' argument isn't a #{type}: #{arg.class}` unless arg.class == type
end

def verify_hash ( args )
  verify_var(args, Hash)
  raise ArgumentError, %Q`required 'args' argument is missing from 'args'` unless args.has_key?(:args)
  verify_var(args[:args], Hash)

  # verify required arguments
  if args.has_key?(:required)
    required = args[:required]
    verify_var(required, Hash)

    required.each_pair do |k, v|
      verify_var(k, Symbol)
      verify_var(v, Class)
      raise ArgumentError, %Q`required '#{k}' argument is missing from 'args'` unless args[:args].has_key?(k)
      verify_var(args[:args][k], v)
    end
  end

  # verify optional arguments
  if args.has_key?(:optional)
    optional = args[:optional]
    verify_var(optional, Hash)

    optional.each_pair do |k, v|
      verify_var(k, Symbol)
      verify_var(v, Class)
      if args[:args].has_key?(k)
        verify_var(args[:args][k], v)
      end
    end
  end
end

################################### LOGGING ###################################

def colorize ( text, color_code ); "#{color_code}#{text}\033[0m";  end
def purple   ( text );             colorize(text,"\033[0;35;40m"); end
def teal     ( text );             colorize(text,"\033[0;36;40m"); end
def green    ( text );             colorize(text,"\033[0;32;40m"); end
def yellow   ( text );             colorize(text,"\033[0;33;40m"); end
def red      ( text );             colorize(text,"\033[0;31;40m"); end
def bred     ( text );             colorize(text,"\033[1;31;40m"); end

LOG_LEVELS = { :debug => 0, :info  => 1, :warn  => 2, :error => 3, :fatal => 4 }

def log ( lvl, src, data='' )
  verify_var(lvl, Symbol)
  verify_var(src, Symbol)

  # get and set default levels
  log_lvl = ENV.has_key?("LOG_LVL") ? ENV["LOG_LVL"].to_sym : :info
  log_lvl = :info unless LOG_LEVELS.keys.include?(log_lvl)
  lvl     = :info unless LOG_LEVELS.keys.include?(lvl)

  # only log if lvl >= log_lvl
  return if LOG_LEVELS[lvl] < LOG_LEVELS[log_lvl]

  # build msg string based on 'data' argument
  case data
  when String
    msg = data
  when Hash
    msg = "#{data}"
    #msg = "#{data.to_yaml}" if ENV.has_key?("DEBUG") && ENV["DEBUG"] == "yaml"
  else
    raise ArgumentError, %Q`'data' argument isn't a String or Hash: #{data.class}`
  end

  msg.insert(0, ": ") unless msg.empty?
  msg.insert(0, "#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}: fantasy: #{lvl}: #{src}")

  case lvl
  when :debug
    msg = teal(msg)
  when :info
    msg = green(msg)
  when :warn
    msg = yellow(msg)
  when :error
    msg = red(msg)
  when :fatal
    msg = bred(msg)
  end

  puts msg
end

##################################### MISC #####################################

def readurl ( url )
  log(:debug, __method__, :url => url)
  verify_var(url, String)
  data = open(url).read
  sleep 1
  # store_s3("sb/date-timestamp.html", sb_html)
  # store_s3("bs/gid-timestamp.json", json)
  # store_s3("bs/gid-timestamp.html", bs_html)
  return data
end

=begin
send email:
body = {:gid => gid}.to_yaml
Notifier.error(:subject => "sync_game completed!", :body => body).deliver
=end
