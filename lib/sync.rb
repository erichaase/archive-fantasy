require 'common'
require 'json'

module Sync

  RE = {
    :gid  => %r`<\s*a[^h]+href\s*=\s*"\s*/nba/boxscore\?gameId=(\d+)[^"]*"[^>]*>\s*[Bb][Oo][Xx]\s*&nbsp\s*;\s*[Ss][Cc][Oo][Rr][Ee]\s*<\s*/\s*a\s*>`,
    :date => %r`scoreboard\?date=(\d+)`
  }

################################################################################

  class Scoreboard

    SB_URI  = "http://scores.espn.go.com/nba/scoreboard?date=%s"

    def initialize ( opts = {} )
      log(:debug, __method__, opts)
      verify_hash(:args => opts, :optional => {:date => Date})

      if opts.has_key?(:date)
        @date = opts[:date]
        sb_html = readurl(SB_URI % @date.strftime('%Y%m%d'))
        @gids = sb_html.scan(Sync::RE[:gid]).collect { |gid| gid[0].strip.to_i }
      else
        @date = Date.today + 1
        @gids = []
        while @gids.empty?
          @date -= 1
          sb_html = readurl(SB_URI % @date.strftime('%Y%m%d'))
          @gids = sb_html.scan(Sync::RE[:gid]).collect { |gid| gid[0].strip.to_i }
        end
      end

      log(:warn, __method__, "'gids' is empty, date = #{@date}") if @gids.empty?
      log(:info, __method__, :date => @date, :gids => @gids)

      @boxscores = []
      @gids.each { |gid| @boxscores << Sync::Boxscore.new(gid) }
    end

    def save
      log(:debug, __method__)
      @boxscores.each { |bs| bs.save }
    end

  end

#-------------------------------------------------------------------------------

  class Boxscore

    BSJ_URI = "http://scores.espn.go.com/nba/gamecast12/master?xhr=1&gameId=%s&lang=en&init=true&setType=true&confId=null"
    BSH_URI = "http://scores.espn.go.com/nba/boxscore?gameId=%s"

    def initialize ( gid )
      log(:debug, __method__, :gid => gid)
      verify_var(gid, Fixnum)

      @gid = gid
      @bs = BoxScore.where(:gid_espn => @gid).first

      # don't process final box scores
      if skip?
        log(:info, __method__, "skipping final box score #{@gid}")
        return
      end

      # verify json data

      # get json data
      json = JSON.parse(readurl(BSJ_URI % @gid.to_s).force_encoding("ISO8859-1"))

      # setup bs data
      @status, @team_home, @team_away = parse_game(json['gamecast']['current'])

      # setup bse data
      @bses_home = []
      @bses_away = []
      json['gamecast']['stats']['player']['home'][0...-1].each { |p| @bses_home << parse_player(p) }
      json['gamecast']['stats']['player']['away'][0...-1].each { |p| @bses_away << parse_player(p) }
    end

    def skip?
      log(:debug, __method__, :bs => @bs)

      if @bs and @bs.final? and not ENV.has_key?("FORCE")
        return true
      else
        return false
      end
    end

    def parse_game ( c )
      log(:debug, __method__, :c => c)
      verify_var(c, Hash)

      # gameState =~ final|live
      # status1   =~ Final|2nd OT|4th|3rd|Halftime
      # status2   =~ ''|15.0|9:26|6:48|4:05|3:30|4:26
      ['gameState', 'status1', 'status2'].each { |x| c[x].strip!; c[x].downcase! }
      status = "#{c['gameState']},#{c['status1']},#{c['status2']}"

      team_home = c['home']['abbrev'].strip.downcase
      team_away = c['away']['abbrev'].strip.downcase

      log(:debug, __method__, :status => status, :team_home => team_home, :team_away => team_away)
      return status, team_home, team_away
    end

    def parse_player ( p )
      log(:debug, __method__, :p => p)
      verify_var(p, Hash)

      # verify json data

      p.each_pair { |k, v| p[k] = v.strip.downcase if p[k].class == String }

      bse = {}
      bse[:pid_espn] = p['id']             # 2439
      bse[:fname]    = p['firstName']      # 'Jameer'
      bse[:lname]    = p['lastName']       # 'Nelson'
      #                p['positionAbbrev'] # 'PG'
      #                p['jersey'].to_i    # '14'
      #                p['active']         # 'true|false'
      #                p['isStarter']      # 'true|false'

      bse[:fname] = "null" if bse[:fname].empty?
      bse[:lname] = "null" if bse[:lname].empty?

      if p['minutes'][/^-$|^0$/]
        bse[:status] = 'dnp'
        log(:debug, __method__, :bse => bse)
        return bse
      end

      bse[:status]    = 'play'
      bse[:min]       = p['minutes'].to_i         # '32|-'
      bse[:fgm]       = p['fg'][/^\d+/].to_i      # '5/9|-'
      bse[:fga]       = p['fg'][/\d+$/].to_i      # '5/9|-'
      bse[:tpm]       = p['threept'][/^\d+/].to_i # '2/5|-'
      bse[:tpa]       = p['threept'][/\d+$/].to_i # '2/5|-'
      bse[:ftm]       = p['ft'][/^\d+/].to_i      # '0/0|-'
      bse[:fta]       = p['ft'][/\d+$/].to_i      # '0/0|-'
      bse[:reb]       = p['rebounds'].to_i        # '3|-'
      bse[:ast]       = p['assists'].to_i         # '2|-'
      bse[:stl]       = p['steals'].to_i          # '1|-'
      bse[:blk]       = p['blocks'].to_i          # '0|-'
      bse[:to]        = p['turnovers'].to_i       # '1|-'
      bse[:pf]        = p['fouls'].to_i           # '2|-'
      bse[:plusminus] = p['plusMinus'].to_i       # '-3|-'
      bse[:pts]       = p['points'].to_i          # '12|-'
      bse[:oreb]      = 0

      log(:debug, __method__, :bse => bse)
      return bse
    end

    def save
      log(:debug, __method__)

      return if skip?

      begin
        if @bs
          verify_var(@bs, BoxScore)
          @bs.status = @status
          @bs.save!
        else
          # get date
          bs_html = readurl(BSH_URI % @gid.to_s)
          d = bs_html.scan(Sync::RE[:date])[0][0]
          date = Date.new(d[0,4].to_i, d[4,2].to_i, d[6,2].to_i)

          @bs = BoxScore.create! do |bs|
            bs.gid_espn = @gid
            bs.status   = @status
            bs.date     = date
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        log(:error, __method__, :message => e.message, :gid => @gid, :status => @status, :bs => @bs)
        # send email?
        return
      end

      log(:info, __method__, @bs.to_s)

      (@bses_home + @bses_away).each do |a|
        bse = @bs.box_score_entries.where(:pid_espn => a[:pid_espn]).first
        begin
          if bse
            bse.update_attributes!(a)
          else
            bse = @bs.box_score_entries.create!(a)
          end
        rescue ActiveRecord::RecordInvalid => e
          log(:error, __method__, :message => e.message, :a => a, :bse => bse)
          # send email?
          next
        end

        log(:info, __method__, bse.to_s)
      end

    end

  end

################################################################################

end
