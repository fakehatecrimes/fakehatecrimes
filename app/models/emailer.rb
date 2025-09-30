class Emailer < ActionMailer::Base

  default from: 'no-reply@fakehatecrimes.org',
               :return_path => 'no-reply@fakehatecrimes.org'
  default_url_options[:host] = 'fakehatecrimes.org'

  def contact(recipient, subject, message, sent_at = Time.now)

      mail( to: EMAIL_ADDRESS,
            subject: subject,
            body: message)

   end

end
