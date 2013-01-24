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
end
