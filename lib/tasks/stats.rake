require 'common'

namespace :stats do
  desc "Retrieve most recent day's box score entries and stores them in database"
  task :sync => :environment do
    BoxScore.sync(activeToday)
  end
end
