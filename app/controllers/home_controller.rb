require 'common'

class HomeController < ApplicationController
  def index
    log(:debug, __method__)

    date = Date.today
    while not BoxScore.where(:date => date).first
      date -= 1
    end

    @bses = []
    BoxScore.where(:date => date).each do |bs|
      bs.box_score_entries.each do |bse|
        @bses << bse if bse.play?
      end
    end
    @bses.sort! { |a,b| b.ratings[:total] <=> a.ratings[:total] }

    log(:debug, __method__, :bses => @bses)
  end
end
