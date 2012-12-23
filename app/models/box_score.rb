require 'common'
require 'open-uri'
require 'yaml'

class BoxScore < ActiveRecord::Base
  attr_accessible :date, :gid_espn, :status

  has_many :box_score_entries, :dependent => :destroy

  validates :gid_espn, :status, :date, :presence => true
  validates :gid_espn, :uniqueness => true
  validates :gid_espn, :numericality => { :only_integer => true }
  validates :status, :format => { :with => /^[^,]*,[^,]*,[^,]*$/,
                                  :message => "must be in the following format: status,quarter,time" }

  before_save do |bs|
    bs.status.strip!
  end

  after_save do |bs|
    log(:debug,  __method__, "saved bs: #{bs}")
  end

  def final?
    if status =~ /^final/
      return true
    else
      return false
    end
  end

=begin
examples:

boxscores:
<ul class="game-info">
  <li id="320218012-statusLine1" style="text-indent: 5px;">Final/OT</li>
  <li style="text-indent: 5px; padding-top: 7px;">
    <span id="320218012-statusLine2Left">&nbsp;</span>
    <span id="320218012-statusLine2Right" class="time-remaining">&nbsp;</span>
  </li>
</ul>
...
<a href="/nba/boxscore?gameId=320218012">Box&nbsp;Score</a>

boxscore entries:
<tr align="right" class="even player-46-609"><td style="text-align:left;" nowrap><a href="http://espn.go.com/nba/player/_/id/609/dirk-nowitzki">Dirk Nowitzki</a>, PF</td><td>38</td><td>11-20</td><td>4-5</td><td>8-9</td><td>1</td><td>4</td><td>5</td><td>3</td><td>2</td><td>0</td><td>4</td><td>2</td><td>+10</td><td>34</td></tr>
<tr align="right" class="odd player-46-1000"><td style="text-align:left;" nowrap><a href="http://espn.go.com/nba/player/_/id/1000/brendan-haywood">Brendan Haywood</a>, C</td><td>27</td><td>4-6</td><td>0-0</td><td>1-3</td><td>2</td><td>4</td><td>6</td><td>1</td><td>0</td><td>2</td><td>0</td><td>3</td><td>+20</td><td>9</td></tr>
=end

  def self.syncDay ( date=nil )
    # setup date, gids and sb_html
    gids = []
    sb_html = nil
    if date
      raise ArgumentError, "'date' argument is not a Date object" unless date.class == Date
      sb_html = open(scoreboardURI(date)).read
      sb_html.scan(RE[:gid]) do |gid| gids << gid[0].strip.to_i end
    else
      now = DateTime.now
      date = Date.new(now.year, now.mon, now.mday) + 1
      while gids.empty?
        date -= 1
        sb_html = open(scoreboardURI(date)).read
        sb_html.scan(RE[:gid]) do |gid| gids << gid[0].strip.to_i end
      end
    end

    log(:debug, __method__, "date = #{date}, gids = #{gids}")

    gids.each do |gid| BoxScore.syncGame(:gid => gid, :date => date, :sb_html => sb_html) end
  end


  def self.syncGame ( args )
    raise ArgumentError, %q`'args' argument is not a Hash object`  unless args.class == Hash
    raise ArgumentError, %q`'gid' argument not passed`             unless args.has_key?(:gid)
    raise ArgumentError, %q`'gid' argument is not a Fixnum object` unless args[:gid].class == Fixnum
    raise ArgumentError, %q`'date' argument not passed`            unless args.has_key?(:date)
    raise ArgumentError, %q`'date' argument is not a Date object`  unless args[:date].class == Date

    gid  = args[:gid]
    date = args[:date]

    if args.has_key?(:sb_html)
      raise ArgumentError, %q`'sb_html' argument is not a String object` unless args[:sb_html].class == String
      sb_html = args[:sb_html]
    else
      sb_html = open(scoreboardURI(date)).read
    end

    force = args.has_key?(:force) && args[:force] ? true : false
    debug = args.has_key?(:debug) && args[:debug] ? true : false

    log(:debug, __method__, "gid = #{gid}, date = #{date}, force = #{force}, debug = #{debug}, sb_html.size = #{sb_html.size}")
    log(:debug, __method__, "sb_yaml = \n#{{:gid => gid, :date => date, :sb_html => sb_html}.to_yaml}") if debug

    bs = BoxScore.where(:gid_espn => gid).first
    if bs and bs.final?
      log(:debug, __method__, "#{gid} box score is final, skipping")
      return unless force
    end

    re_status = %r`\sid\s*=\s*"\s*#{gid}-statusLine1\s*"[^>]*>\s*([^<]+)`
    sb_html.scan(re_status) do |status|
      status = status[0]
      quarter, time = '', ''

# scan for statusLine2
#sb_html.scan(re_status) do |status, quarter, time|
#RE[:open] = '\s*<\s*[^>]+>\s*'
#RE[:close] = '\s*<\s*/\s*[^>]+>\s*'
#%r`#{RE[:close]}#{RE[:close]}<\s*div\s+id\s*=\s*"\s*#{gid}-statusLine2\s*"[^>]*>(#{RE[:open]})([^<]+)`

      [status, quarter, time].each do |x| x.strip!; x.downcase! end

      begin
        if bs
          bs.status = "#{status},#{quarter},#{time}"
          bs.save!
        else
          bs = BoxScore.create! do |bs|
            bs.gid_espn = gid
            bs.status   = "#{status},#{quarter},#{time}"
            bs.date     = date
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        log(:error,  __method__, "#{e.message}: #{bs.inspect}")
        next
      end

      bs_html = open(boxscoreURI(bs.gid_espn)).read

      log(:debug, __method__, "bs_yaml = \n#{{:gid => gid, :date => date, :bs_html => bs_html}.to_yaml}") if debug

      headers = ''
      bs_html.scan(RE[:headers]) do |full, single|
        headers = full.split(%r`\s*<\s*/\s*th\s*>\s*<\s*th[^>]+>\s*`)
        if headers.size > 1
          headers[0].sub!(%r`^\s*<\s*th[^>]*>\s*`,'')
          headers[-1].sub!(%r`\s*<\s*/\s*th\s*>\s*$`,'')
        end
        headers.each do |x| x.strip!; x.downcase! end
        break
      end

      log(:debug, __method__, "headers: size = #{headers.size}, headers = #{headers}")

      bs_html.scan(RE[:player]) do | href, name, pos, rest |
        stats = rest.split(%r`\s*<\s*/\s*td\s*>\s*<\s*td[^>]*>\s*`)
        if stats.size > 1
          stats[0].sub!(%r`^\s*<\s*td[^>]*>\s*`,'')
          stats[-1].sub!(%r`\s*<\s*/\s*td\s*>\s*$`,'')
        end

        log(:debug, __method__, "stats: name = #{name}, size = #{stats.size}, stats = #{stats}")

        log(:debug, __method__, "bs_yaml = \n#{{:gid => gid, :date => date, :rest => rest}.to_yaml}") if headers.size != stats.size and stats.size > 1

        [href, name, pos].concat(stats).each do |x| x.strip!; x.downcase! end

        bse_attrs     = {}
        p_attrs       = {}
        p_attrs[:pos] = pos
        bse_attrs[:pid_espn] = href.scan(%r`/id/(\d+)/`)[0][0].to_i
        bse_attrs[:fname]    = name[/^\S+/]
        bse_attrs[:lname]    = name[/\S+$/]

        case stats.size
        when 1
          # "dnp coach's decision"
          # "dnp personal reasons"
          # "dnp sore left elbow"
          # "dnp [reason]"
          # "has not entered game"
          bse_attrs[:status] = stats[0]
        when 13..14
          bse_attrs[:status]   = 'play'
          bse_attrs[:min]      = stats[0].to_i
          bse_attrs[:fgm]      = stats[1][/^\d+/].to_i
          bse_attrs[:fga]      = stats[1][/\d+$/].to_i
          bse_attrs[:tpm]      = stats[2][/^\d+/].to_i
          bse_attrs[:tpa]      = stats[2][/\d+$/].to_i
          bse_attrs[:ftm]      = stats[3][/^\d+/].to_i
          bse_attrs[:fta]      = stats[3][/\d+$/].to_i
          bse_attrs[:oreb]     = stats[4].to_i

          case headers[5]
          when 'reb'
            bse_attrs[:reb]       = stats[5].to_i
            bse_attrs[:ast]       = stats[6].to_i
            bse_attrs[:stl]       = stats[7].to_i
            bse_attrs[:blk]       = stats[8].to_i
            bse_attrs[:to]        = stats[9].to_i
            bse_attrs[:pf]        = stats[10].to_i
            bse_attrs[:plusminus] = stats[11].to_i
            bse_attrs[:pts]       = stats[12].to_i
          when 'dreb'
            case stats.size
            when 13
              bse_attrs[:reb]       = stats[6].to_i
              bse_attrs[:ast]       = stats[7].to_i
              bse_attrs[:stl]       = stats[8].to_i
              bse_attrs[:blk]       = stats[9].to_i
              bse_attrs[:to]        = stats[10].to_i
              bse_attrs[:pf]        = stats[11].to_i
              bse_attrs[:plusminus] = 0
              bse_attrs[:pts]       = stats[12].to_i
            when 14
              bse_attrs[:reb]       = stats[6].to_i
              bse_attrs[:ast]       = stats[7].to_i
              bse_attrs[:stl]       = stats[8].to_i
              bse_attrs[:blk]       = stats[9].to_i
              bse_attrs[:to]        = stats[10].to_i
              bse_attrs[:pf]        = stats[11].to_i
              bse_attrs[:plusminus] = stats[12].to_i
              bse_attrs[:pts]       = stats[13].to_i
            end
          else
            log(:warn, __method__, "headers[5] = #{headers[5]}, should be either 'reb' or 'dreb': #{name}, #{stats.inspect}")
            next
          end
        else
          log(:warn, __method__, "stats.size = #{stats.size}, should be 1|13|14: #{name}, #{stats.inspect}")
          next
        end

        bse = bs.box_score_entries.where(:pid_espn => bse_attrs[:pid_espn]).first
        begin
          if bse
            bse.update_attributes!(bse_attrs)
          else
            bse = bs.box_score_entries.create!(bse_attrs)
          end
        rescue ActiveRecord::RecordInvalid => e
          log(:error,  __method__, "#{e.message}: #{bse_attrs.inspect}")
          next
        end

        # add BoxScoreEntry to Player model using p_attrs

      end

      log(:warn, __method__, "the following BoxScore has less than 20 BoxScoreEntries: #{bs.inspect}") if bs.status.downcase =~ /^final/ and bs.box_score_entries.size < 20

    end
  end

end
