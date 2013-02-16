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
      log(:warn, __method__, "game isn't final or live: #{status}") if not s[0][/live/]

      case s[2]
      when /:/
        mleft = 12 - s[2].split(":")[0].to_i
      when /\d*\.\d*/
        mleft = 12
      else
        mleft = 0
      end

      case s[1]
      when /1st/
        return mleft
      when /2nd/
        return 12 + mleft
      when /3rd/
        return 24 + mleft
      when /4th/
        return 36 + mleft
      when /halftime/
        return 24
      when /^\s*end/
        q = s[2][/^\s*\d+/]
        if q
          return 12 * q.to_i
        else
          log(:error, __method__, "status not parsed (-2): #{status}")
          return -2
        end
      # ot
      else
        log(:error, __method__, "status not parsed (-1): #{status}")
        return -1
      end
    end

  end

  def to_s
    return "bs: #{gid_espn}: #{date}, #{status}"
  end

end
