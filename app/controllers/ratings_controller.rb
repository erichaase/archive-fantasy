require 'common'
require 'player'

class RatingsController < ApplicationController

=begin
  def index
    log(:debug, __method__)
    if params[:days]
    elsif params[:from] and params[:to]
    else
      players = getPlayers(XactiveTodayX)
      render :json => players
    end
  end
  def now
    log(:debug, __method__)
    date = XactiveTodayX
    BoxScore.sync(date)
    players = getPlayers(date)
    render :json => players
  end
=end

  def day
    d = params[:date]
    log(:debug, __method__, :d => d)
    verify_var(d, String)

    date = Date.new(2000 + d[0,2].to_i, d[2,2].to_i, d[4,2].to_i)

    players = []
    BoxScore.where(:date => date).each do |bs|
      bs.box_score_entries.each do |bse|
        players << Player.new(bs,bse) if bse.play?
      end
    end
    players.sort! { |a,b| b.r_tot <=> a.r_tot }

    log(:debug, __method__, :players => players)

    render :json => players
  end

end
