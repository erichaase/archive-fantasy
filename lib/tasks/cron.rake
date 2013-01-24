require 'common'
require 'sync'

namespace :cron do
  desc "Retrieve and store most recent day's box scores"
  task :ten_min => :environment do
    now = DateTime.now
    log(:debug, :ten_min, :now => now)

    min = now.min
    if (min >= 0 && min < 10) || (min >= 15 && min < 25) || (min >= 30 && min < 40) || (min >= 45 && min < 55)
      sb = Sync::Scoreboard.new
      log(:debug, :ten_min, sb.to_yaml)
      sb.save
    end
  end
end
