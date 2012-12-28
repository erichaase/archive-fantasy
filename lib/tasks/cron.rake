require 'common'

namespace :cron do
  desc "Retrieve most recent day's box score entries and stores them in database"
  task :tenMin => :environment do
    now = DateTime.now
    if (now.min >= 10 && now.min < 20) || (now.min >= 40 && now.min < 50)
      BoxScore.syncDay
    end
  end
end