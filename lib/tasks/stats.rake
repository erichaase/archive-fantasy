require 'common'
require 'yaml'

namespace :stats do
  desc "Retrieve a particular box score and print debugging information"
  task :syncGame, [:gid, :date, :force, :debug] => [:environment] do |t, args|
    raise ArgumentError, "'gid' argument not passed"   unless args.to_hash.has_key?(:gid)
    raise ArgumentError, "'date' argument not passed"  unless args.to_hash.has_key?(:date)
    raise ArgumentError, "'force' argument not passed" unless args.to_hash.has_key?(:force)
    raise ArgumentError, "'debug' argument not passed" unless args.to_hash.has_key?(:debug)
    raise ArgumentError, %q`'gid' argument must be in the following format: /\d{9}/`  unless args[:gid]   =~ /\d{9}/
    raise ArgumentError, %q`'date' argument must be in the following format: /\d{6}/` unless args[:date]  =~ /\d{6}/
    raise ArgumentError, %q`'force' argument must be in the following format: /0|1/`  unless args[:force] =~ /0|1/
    raise ArgumentError, %q`'debug' argument must be in the following format: /0|1/`  unless args[:debug] =~ /0|1/

    gid = args[:gid].to_i
    da  = args[:date]
    date = Date.new(2000 + da[0,2].to_i, da[2,2].to_i, da[4,2].to_i)
    force = args[:force] == "1" ? true : false
    debug = args[:debug] == "1" ? true : false

    BoxScore.syncGame(:gid => gid, :date => date, :force => force, :debug => debug)

    Notifier.error(:subject => "syncGame completed!", :body => {:gid => gid, :date => date, :force => force, :debug => debug}.to_yaml).deliver
  end
end
