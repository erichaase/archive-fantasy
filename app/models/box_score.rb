require 'common'

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

  def final?
    if status =~ /^final/
      return true
    else
      return false
    end
  end

  def self.syncDay ( args={} )
    raise ArgumentError, %q`'args' argument is not a Hash object`  unless args.class == Hash

    # setup sb_html and gids
    if args.has_key?(:date)
      raise ArgumentError, %q`'date' argument is not a Date object` unless args[:date].class == Date
      date = args[:date]
      sb_html = open(scoreboardURI(date)).read
      sleep 1
      gids = sb_html.scan(RE[:gid]).collect { |gid| gid[0].strip.to_i }
    else
      date = Date.today + 1
      gids = []
      while gids.empty?
        date -= 1
        sb_html = open(scoreboardURI(date)).read
        sleep 1
        gids = sb_html.scan(RE[:gid]).collect { |gid| gid[0].strip.to_i }
      end
    end

    # log variables
    log(:info,  __method__, { :date => date, :gids => gids })
    log(:debug, __method__, { :date => date, :gids => gids, :sb_html => sb_html })

    # syncGame() each game
    gids.each do |gid|
      BoxScore.syncGame(:gid => gid, :sb_html => sb_html)
    end
  end

  def self.syncGame ( args )
    raise ArgumentError, %q`'args' argument is not a Hash object`  unless args.class == Hash
    raise ArgumentError, %q`'gid' argument not passed`             unless args.has_key?(:gid)
    raise ArgumentError, %q`'gid' argument is not a Fixnum object` unless args[:gid].class == Fixnum

    gid = args[:gid]
    bs = BoxScore.where(:gid_espn => gid).first

    # don't process final box scores
    if bs and bs.final? and not ENV.has_key?("FORCE")
      log(:info, __method__, "skipping box score #{gid} because it is final")
      return
    end

    # setup bs_html and date
    bs_html = open(boxscoreURI(gid)).read
    sleep 1
    d = bs_html.scan(RE[:date])[0][0]
    date = Date.new(d[0,4].to_i, d[4,2].to_i, d[6,2].to_i)
    
    # setup sb_html
    if args.has_key?(:sb_html)
      raise ArgumentError, %q`'sb_html' argument is not a String object` unless args[:sb_html].class == String
      sb_html = args[:sb_html]
    else
      sb_html = open(scoreboardURI(date)).read
      sleep 1
    end

    # log html
    log(:debug, __method__, { :gid => gid, :date => date, :sb_html => sb_html, :bs_html => bs_html })

    # get status
    re_status = %r`\sid\s*=\s*"\s*#{gid}-statusLine1\s*"[^>]*>\s*([^<]+)`
    status = sb_html.scan(re_status)[0][0]
    # throw exception if status isn't found
    quarter, time = '', ''
    [status, quarter, time].each { |x| x.strip!; x.downcase! }

=begin
scan for statusLine2
sb_html.scan(re_status) do |status, quarter, time|
RE[:open] = '\s*<\s*[^>]+>\s*'
RE[:close] = '\s*<\s*/\s*[^>]+>\s*'
%r`#{RE[:close]}#{RE[:close]}<\s*div\s+id\s*=\s*"\s*#{gid}-statusLine2\s*"[^>]*>(#{RE[:open]})([^<]+)`
=end

    # save/create box score
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
      log(:error, __method__, "#{e.message}: #{bs.inspect}")
      return
    end
    log(:info, __method__, {:bs => bs})

    # get headers
    headers_html = bs_html.scan(RE[:headers])[0][0]
    headers = headers_html.split(%r`\s*<\s*/\s*th\s*>\s*<\s*th[^>]+>\s*`)
    if headers.size > 1
      headers[0].sub!(%r`^\s*<\s*th[^>]*>\s*`,'')
      headers[-1].sub!(%r`\s*<\s*/\s*th\s*>\s*$`,'')
    else
      # throw exception instead of logging
      log(:error, __method__, "headers.size < 2: headers = #{headers}")
    end
    headers.each { |x| x.strip!; x.downcase! }
    log(:debug, __method__, { :headers_size => headers.size, :headers => headers })

    bs_html.scan(RE[:player]) do | href, name, pos, rest |
      log(:debug, __method__, { :href => href, :name => name, :pos => pos, :rest => rest })

      stats = rest.split(%r`\s*<\s*/\s*td\s*>\s*<\s*td[^>]*>\s*`)
      if stats.size > 1
        stats[0].sub!(%r`^\s*<\s*td[^>]*>\s*`,'')
        stats[-1].sub!(%r`\s*<\s*/\s*td\s*>\s*$`,'')
      elsif stats.size == 1
        stats[0].sub!(%r`^\s*<\s*td[^>]*>\s*`,'')
        stats[0].sub!(%r`\s*<\s*/\s*td\s*>\s*$`,'')
      end
      log(:debug, __method__, { :stats_size => stats.size, :stats => stats })

      [href, name, pos].concat(stats).each { |x| x.strip!; x.downcase! }

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

        if stats.size == 13
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
            bse_attrs[:reb]       = stats[6].to_i
            bse_attrs[:ast]       = stats[7].to_i
            bse_attrs[:stl]       = stats[8].to_i
            bse_attrs[:blk]       = stats[9].to_i
            bse_attrs[:to]        = stats[10].to_i
            bse_attrs[:pf]        = stats[11].to_i
            bse_attrs[:plusminus] = 0
            bse_attrs[:pts]       = stats[12].to_i
          else
            log(:warn, __method__, "headers[5] = #{headers[5]}, should be either 'reb' or 'dreb': #{name}, #{stats.inspect}")
            next
          end
        elsif stats.size == 14
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
        log(:error, __method__, "#{e.message}: #{bse_attrs.inspect}")
        next
      end
      log(:info,  __method__, {:fname => bse_attrs[:fname], :lname => bse_attrs[:lname], :stats_size => stats.size})
      log(:debug, __method__, {:bse => bse})

      # add BoxScoreEntry to Player model using p_attrs

    end

    log(:warn, __method__, "the following BoxScore has less than 20 BoxScoreEntries: #{bs.inspect}") if bs.status.downcase =~ /^final/ and bs.box_score_entries.size < 20

  end

end
