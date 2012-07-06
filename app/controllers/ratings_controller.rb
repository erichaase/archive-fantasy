require 'common'

################################################################################

class RatingsController < ApplicationController
  def index
    log(:debug, __method__)
    if params[:days]
    elsif params[:from] and params[:to]
    else
      players = getPlayers(activeToday)
      render :json => players
    end
  end

  def now
    log(:debug, __method__)
    date = activeToday
    BoxScore.sync(date)
    players = getPlayers(date)
    render :json => players
  end

  def day
    log(:debug, __method__)
    #params[:date]
  end

end

################################################################################

def getPlayers ( date )
  raise ArgumentError, "'date' argument is not a Date object" if date.class != Date
  log(:debug, __method__, "date = #{date}")

  players = []
  BoxScore.where(:date => date).each do |bs|
    bs.box_score_entries.each do |bse|
      players << Player.new(bs,bse) if bse.play?
    end
  end
  players.sort! { |a,b| b.r_tot <=> a.r_tot }

  return players
end


class Player

  attr_reader :r_tot

  def initialize (bs,bse)
    @gid_espn      = bs.gid_espn
    @date          = bs.date
    @bs_created_at = bs.created_at
    @bs_updated_at = bs.updated_at

    status = bs.status.split(",")
    if bs.final?
      @bs_status = 'final'
    elsif status[2] =~ /&nbsp;/
      @bs_status = status[1]
    else
      @bs_status = status[1,2].join(" (").concat(")")
    end

    @pid_espn       = bse.pid_espn
    @fname          = bse.fname
    @lname          = bse.lname
    @min            = bse.min
    @fgm            = bse.fgm
    @fga            = bse.fga
    @tpm            = bse.tpm
    @tpa            = bse.tpa
    @ftm            = bse.ftm
    @fta            = bse.fta
    @oreb           = bse.oreb
    @reb            = bse.reb
    @ast            = bse.ast
    @stl            = bse.stl
    @blk            = bse.blk
    @to             = bse.to
    @pf             = bse.pf
    @plusminus      = bse.plusminus
    @pts            = bse.pts
    @box_score_id   = bse.box_score_id
    @bse_status     = bse.status
    @bse_created_at = bse.created_at
    @bse_updated_at = bse.updated_at

    if @fga == 0
      @r_fgp = 0.0
    else
      @r_fgp = (((@fgm.to_f / @fga.to_f) - 0.47) * (@fga / 22.8181818181818)) * 55.0266638166801
    end
    if @fta == 0
      @r_ftp = 0.0
    else
      @r_ftp = (((@ftm.to_f / @fta.to_f) - 0.769) * (@fta / 10.4901960784314)) * 25.5465168615693
    end
    @r_tpm = (@tpm - 0.9) * 3.33333333333333
    @r_pts = (@pts - 16.6) * 0.316872427983539
    @r_reb = (@reb - 6.0) * 0.779487179487179
    @r_ast = (@ast - 3.65) * 0.85972850678733
    @r_stl = (@stl - 1.1) * 4.66666666666667
    @r_blk = (@blk - 0.7) * 3.01724137931034
    @r_to  = (@to - 2.08) * -2.36111111111111
    @r_tot = @r_fgp + @r_ftp + @r_tpm + @r_pts + @r_reb + @r_ast + @r_stl + @r_blk + @r_to
  end

end
