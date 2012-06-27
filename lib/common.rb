require 'open-uri'
require 'date'

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

def activeToday
  log(:debug, __method__)
  now = DateTime.now
  day = Date.new(now.year, now.mon, now.mday)
  day -= 1 while gids(day).empty?
  return day
end

def gids ( date )
  raise ArgumentError, "'date' argument is not a Date object" if date.class != Date
  log(:debug, __method__, "date = #{date}")

  ids = []
  re_gid = %r`<\s*a\s+href\s*=\s*"\s*/nba/boxscore\?gameId=(\d+)\s*"[^>]*>\s*[Bb]ox\s*&nbsp\s*;\s*[Ss]core\s*<\s*/\s*a\s*>`
  open(scoreboardURI(date)).read.scan(re_gid) do |gid| ids << gid[0].strip.to_i end
  return ids
end

################################################################################

def colorize ( text, color_code ); "#{color_code}#{text}\033[0m";  end
def green    ( text );             colorize(text,"\033[0;32;40m"); end
def bgreen   ( text );             colorize(text,"\033[1;32;40m"); end
def yellow   ( text );             colorize(text,"\033[0;33;40m"); end
def red      ( text );             colorize(text,"\033[0;31;40m"); end
def bred     ( text );             colorize(text,"\033[1;31;40m"); end

def log ( lvl, src, msg='' )
  raise ArgumentError, "'lvl' argument is not a Symbol object" if lvl.class != Symbol
  raise ArgumentError, "'src' argument is not a Symbol object" if src.class != Symbol
  raise ArgumentError, "'msg' argument is not a String object" if msg.class != String

  msg.insert(0, ": ") if not msg.empty?
  msg.insert(0, "  #{DateTime.now.strftime('%Y-%m-%d|%H:%M:%S')}: #{lvl}: #{src}")

  case lvl
  when :debug, :info
    msg = green(msg)
  when :warn
    msg = yellow(msg)
  when :error
    msg = red(msg)
  when :fatal
    msg = bred(msg)
  end

  Rails.logger.send(lvl,msg)
end
