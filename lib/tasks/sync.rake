require 'common'
require 'sync'

namespace :sync do

  desc "Retrieve and store a particular day's box scores"
  task :sync_day, [:date] => [:environment] do |t, args|
    log(:debug, :sync_day, :args => args.to_hash)
    verify_hash(:args => args.to_hash, :required => {:date => String})
    raise ArgumentError, %Q`'date' argument must be in the following format: YYMMDD` unless args[:date] =~ /^\s*\d{6}\s*$/

    d = args[:date]
    date = Date.new(2000 + d[0,2].to_i, d[2,2].to_i, d[4,2].to_i)

    sb = Sync::Scoreboard.new(:date => date)
    # store_s3("xxx", sb.to_yaml)
    sb.save
  end

  desc "Retrieve and store a particular box score"
  task :sync_game, [:gid] => [:environment] do |t, args|
    log(:debug, :sync_game, :args => args.to_hash)
    verify_hash(:args => args.to_hash, :required => {:gid => String})
    raise ArgumentError, %Q`'gid' argument must be in the following format: 123456789` unless args[:gid] =~ /^\s*\d{9}\s*$/

    gid = args[:gid].to_i

    bs = Sync::Boxscore.new(gid)
    # store_s3("xxx", bs.to_yaml)
    bs.save

  end

end
