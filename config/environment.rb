# Load the rails application
require File.expand_path('../application', __FILE__)

Fantasy::Application.configure do
  config.action_mailer.raise_delivery_errors = true
end

# Initialize the rails application
Fantasy::Application.initialize!
