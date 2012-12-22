require 'common'

namespace :stats do
  desc "Retrieve most recent day's box score entries and stores them in database"
  task :sync => :environment do
    now = DateTime.now
    if (now.min >= 10 && now.min < 20) || (now.min >= 40 && now.min < 50)
      BoxScore.sync
    end
  end
end
