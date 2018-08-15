# frozen_string_literal: true

# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

mailer_creds = Rails.application.credentials.mailer

# Always try to configure the mailer outside test and dev envs
# If the mailer creds are present, configure it in those two envs too
if (!Rails.env.development? && !Rails.env.test?) || mailer_creds.present?
  puts "Configuring mailer"
  Rails.application.configure do
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address:              'smtp.gmail.com',
      port:                 587,
      domain:               'gmail.com',
      user_name:            mailer_creds[:user_name],
      password:             mailer_creds[:password],
      authentication:       'plain',
      enable_starttls_auto: true
    }
  end
end
