class BoxScoreEntry < ActiveRecord::Base
  attr_accessible :ast, :blk, :fga, :fgm, :fname, :fta, :ftm, :lname, :min, :oreb, :pf, :pid_espn, :plusminus, :pts, :reb, :status, :stl, :to, :tpa, :tpm

  belongs_to :box_score

  validates :pid_espn, :fname, :lname, :box_score_id, :status, :presence => true
  validates :pid_espn, :box_score_id, :numericality => { :only_integer => true }
  with_options :if => :play? do |bse|
    bse.validates :min, :fgm, :fga, :tpm, :tpa, :ftm, :fta, :oreb, :reb, :ast, :stl, :blk, :to, :pf, :plusminus, :pts, :presence => true
    bse.validates :min, :fgm, :fga, :tpm, :tpa, :ftm, :fta, :oreb, :reb, :ast, :stl, :blk, :to, :pf, :plusminus, :pts, :numericality => { :only_integer => true }
    bse.validates_each :min, :fgm, :fga, :tpm, :tpa, :ftm, :fta, :oreb, :reb, :ast, :stl, :blk, :to, :pf, :pts do |record, attr, value|
      record.errors.add(attr, 'cannot be a negative number') if value < 0
    end
  end

  # additional validations to add later
  #   fgm <= fga
  #   tpm <= tpa
  #   ftm <= fta
  #   oreb <= reb
  #   pf <= 6
  #   tpm <= fgm
  #   pts = (fgm - tpm) * 2 + tpm * 3 + ftm

  before_save do |bse|
    bse.fname.strip!
    bse.lname.strip!
    bse.status.strip!
  end

  def play?
    status == 'play'
  end

  def ratings
    log(:debug, __method__)

    return Nil if not play?

    r = {}

    if fga == 0
      r[:fgp] = 0.0
    else
      r[:fgp] = (((fgm.to_f / fga.to_f) - 0.47) * (fga / 22.8181818181818)) * 55.0266638166801
    end

    if fta == 0
      r[:ftp] = 0.0
    else
      r[:ftp] = (((ftm.to_f / fta.to_f) - 0.769) * (fta / 10.4901960784314)) * 25.5465168615693
    end

    r[:tpm] = (tpm - 0.9) * 3.33333333333333
    r[:pts] = (pts - 16.6) * 0.316872427983539
    r[:reb] = (reb - 6.0) * 0.779487179487179
    r[:ast] = (ast - 3.65) * 0.85972850678733
    r[:stl] = (stl - 1.1) * 4.66666666666667
    r[:blk] = (blk - 0.7) * 3.01724137931034
    r[:to]  = (to - 2.08) * -2.36111111111111
    r[:total] = r[:fgp] + r[:ftp] + r[:tpm] + r[:pts] + r[:reb] + r[:ast] + r[:stl] + r[:blk] + r[:to]

    return r
  end

  def to_s
    case status
    when 'play'
      return sprintf("bse: %d: [%s %s %d] [%d-%d %d-%d %d-%d] [%d-%d-%d-%d-%d-%d] [%d %d]",
        pid_espn, fname, lname, min, fgm, fga, ftm, fta, tpm, tpa, pts, reb, ast, stl, blk, to, pf, plusminus )
    when 'dnp'
      return sprintf("bse: %d: [%s %s %s]", pid_espn, fname, lname, status)
    else
      log(:error, __method__, :pid_espn => pid_espn, :fname => fname, :lname => lname, :status => status)
    end
  end

  def to_html
    log(:debug, __method__)

    return '' if not play?

    fn = fname[0].capitalize + fname[1,fname.size-1]
    ln = lname[0].capitalize + lname[1,lname.size-1]
    name = "#{fn} #{ln}"

    p = ENV.has_key?("PLAYERS") ? ENV["PLAYERS"] : ""
    p = p.split(/\s*,\s*/).map { |x| x.to_i }
    if p.include? pid_espn
      dt = "e"
    elsif ratings[:total] >= 5
      dt = "b"
    else
      dt = "a"
    end

    bs = box_score
    min_bs = bs.min
    gid = bs.gid_espn

    return <<END
    <div data-role="collapsible" data-theme="#{dt}" data-collapsed-icon="minus" data-expanded-icon="minus">
      <h2>#{name} [#{ratings[:total].to_i}] [#{min}/#{min_bs}]</h2>
      <ul data-role="listview" data-theme="c">
        <li>#{fgm}-#{fga} FG, #{ftm}-#{fta} FT, #{tpm} 3PT</li>
        <li>#{pts} PTS, #{reb} REB, #{ast} AST</li>
        <li>#{stl} STL, #{blk} BLK, #{to} TO</li>
        <li><a href="#">Add Player</a></li>
        <li><a href="#">Profile</a></li>
        <li><a target="_blank" href="http://espn.go.com/nba/player/gamelog/_/id/#{pid_espn}/">Game Log</a></li>
        <li><a target="_blank" href="http://scores.espn.go.com/nba/boxscore?gameId=#{gid}">Box Score</a></li>
        <li><a href="#">Depth Chart</a></li>
        <li><a target="_blank" href="http://www.rotoworld.com/content/playersearch.aspx?searchname=#{lname},%20#{fname}">Rotoworld</a></li>
      </ul>
    </div>
END
  end

end
