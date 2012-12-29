class Notifier < ActionMailer::Base

  default from: "NBA Fantasy App <#{ENV['GMAIL_SMTP_USER']}>",
          to:   "#{ENV['NOTIFIER_TO']}"

  def error ( args )
    raise ArgumentError, %q`'args' argument is not a Hash object`      unless args.class == Hash
    raise ArgumentError, %q`'subject' argument not passed`             unless args.has_key?(:subject)
    raise ArgumentError, %q`'body' argument not passed`                unless args.has_key?(:body)
    raise ArgumentError, %q`'subject' argument is not a String object` unless args[:subject].class == String
    raise ArgumentError, %q`'body' argument is not a String object`    unless args[:body].class == String

    @body = args[:body]

    mail(:subject => "Error: #{args[:subject]}")
  end

end
