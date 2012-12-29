require 'date'

RE = {}
RE[:gid] = %r`<\s*a\s+href\s*=\s*"\s*/nba/boxscore\?gameId=(\d+)\s*"[^>]*>\s*[Bb]ox\s*&nbsp\s*;\s*[Ss]core\s*<\s*/\s*a\s*>`
RE[:player] = %r`<\s*a\s+href\s*=\s*"([^"]+)"\s*>\s*([^<]+)<[^>]+>\s*,\s*([^<]+)<[^<]+((<\s*td[^>]*>[^<]+<\s*/\s*td\s*>\s*)+)`
RE[:headers] = %r`<\s*th[^>]*>\s*STARTERS\s*<\s*/\s*th\s*>((\s*<\s*th[^>]*>\s*[^<]+<\s*/\s*th\s*>)+)`

def scoreboardURI ( date )
  raise ArgumentError, "'date' argument is not a Date object" if date.class != Date
  log(:debug, __method__, "date = #{date}")
  return "http://scores.espn.go.com/nba/scoreboard?date=#{date.strftime('%Y%m%d')}"
end

def boxscoreURI ( gid_espn )
  raise ArgumentError, "'gid_espn' argument is not a Fixnum object" if gid_espn.class != Fixnum
  log(:debug, __method__, "gid_espn = #{gid_espn}")
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

def log ( lvl, src, msg='' )
  raise ArgumentError, "'lvl' argument is not a Symbol object" if lvl.class != Symbol
  raise ArgumentError, "'src' argument is not a Symbol object" if src.class != Symbol
  raise ArgumentError, "'msg' argument is not a String object" if msg.class != String

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
