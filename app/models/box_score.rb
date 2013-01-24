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

  def to_s
    return "bs: #{gid_espn}: #{date}, #{status}"
  end

end
