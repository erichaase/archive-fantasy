require 'common'

namespace :stats do
  desc "Retrieve and store a particular box score"
  task :syncGame, [:gid] => [:environment] do |t, args|
    raise ArgumentError, %q`'gid' argument not passed` unless args.to_hash.has_key?(:gid)
    raise ArgumentError, %q`'gid' argument must be in the following format: /\d{9}/` unless args[:gid]   =~ /\d{9}/

    BoxScore.syncGame(:gid => args[:gid].to_i)

    body = {:gid => args[:gid].to_i}.to_yaml
    Notifier.error(:subject => "syncGame completed!", :body => body).deliver
  end
end
