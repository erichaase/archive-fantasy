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

  def min
    log(:debug, __method__, :status => status)

    s = status.split(",")
    if final?
      if s.size > 2 && s[2].strip.downcase =~ /ot/
        ot = s[2][/\d+/]
        if ot
          return 48 + ot.to_i * 5
        else
          return 48 + 5
        end
      else
        return 48
      end
    else
      #@bs_status = status[1,2].join(" (").concat(")")
      return -1
    end

  end

  def to_s
    return "bs: #{gid_espn}: #{date}, #{status}"
  end

end
