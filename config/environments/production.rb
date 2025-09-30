Fakehatecrimes::Application.configure do
  routes.default_url_options[:host] = "www.fakehatecrimes.org"
  config.eager_load = true
  config.log_level = :info

  # Use system sendmail instead of SMTP
  config.action_mailer.delivery_method = :sendmail
  config.action_mailer.raise_delivery_errors = true

  # The domain your app runs on (used in URLs in emails)
  config.action_mailer.default_url_options = {
    host: 'www.fakehatecrimes.org', 
    protocol: 'https'
  }

end
EMAIL_ADDRESS='xyz@sefsdffjdjd.com'
WORDS = ['xyzabc']
