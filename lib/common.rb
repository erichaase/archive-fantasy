require 'date'
require 'open-uri'
require 'yaml'

RE = {}
RE[:gid]     = %r`<\s*a\s+href\s*=\s*"\s*/nba/boxscore\?gameId=(\d+)\s*"[^>]*>\s*[Bb]ox\s*&nbsp\s*;\s*[Ss]core\s*<\s*/\s*a\s*>`
RE[:date]    = %r`scoreboard\?date=(\d+)`
RE[:headers] = %r`<\s*th[^>]*>\s*STARTERS\s*<\s*/\s*th\s*>((\s*<\s*th[^>]*>\s*[^<]+<\s*/\s*th\s*>)+)`
RE[:player]  = %r`<\s*a\s+href\s*=\s*"([^"]+)"\s*>\s*([^<]+)<[^>]+>\s*,\s*([^<]+)<[^<]+((<\s*td[^>]*>[^<]+<\s*/\s*td\s*>\s*)+)`

def scoreboardURI ( date )
  raise ArgumentError, %q`'date' argument is not a Date object` unless date.class == Date
  return "http://scores.espn.go.com/nba/scoreboard?date=#{date.strftime('%Y%m%d')}"
end

def boxscoreURI ( gid_espn )
  raise ArgumentError, %q`'gid_espn' argument is not a Fixnum object` unless gid_espn.class == Fixnum
  return "http://scores.espn.go.com/nba/boxscore?gameId=#{gid_espn}"
end

################################################################################

def colorize ( text, color_code ); "#{color_code}#{text}\033[0m";  end
def purple   ( text );             colorize(text,"\033[0;35;40m"); end
def teal     ( text );             colorize(text,"\033[0;36;40m"); end
def green    ( text );             colorize(text,"\033[0;32;40m"); end
def yellow   ( text );             colorize(text,"\033[0;33;40m"); end
def red      ( text );             colorize(text,"\033[0;31;40m"); end
def bred     ( text );             colorize(text,"\033[1;31;40m"); end

def log ( lvl, src, data='' )
  raise ArgumentError, %q`'lvl' argument is not a Symbol object` unless lvl.class == Symbol
  raise ArgumentError, %q`'src' argument is not a Symbol object` unless src.class == Symbol

  return if ((lvl == :debug) && (not ENV.has_key?("DEBUG")))

  # build msg string based on 'data' argument
  case data
  when String
    msg = data
  when Hash
    if ENV.has_key?("DEBUG")
      msg = "yaml = \n#{data.to_yaml}"
    else
      msg = "#{data}"
    end
  else
    raise ArgumentError, %q`'data' argument is not a String or Hash object`
  end

  msg.insert(0, ": ") unless msg.empty?
  msg.insert(0, "fantasy: #{DateTime.now.strftime('%Y-%m-%d|%H:%M:%S')}: #{lvl}: #{src}")

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
