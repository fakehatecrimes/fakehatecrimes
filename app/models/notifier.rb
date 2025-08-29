     class Notifier < ActionMailer::Base
       
       default from: 'no-reply@fakehatecrimes.org', 
               :return_path => 'no-reply@fakehatecrimes.org'
       default_url_options[:host] = 'fakehatecrimes.org' 
       
       def password_reset_instructions( recipient )
         
	       @account = recipient
         msg = edit_password_reset_url(recipient.perishable_token)  
         msg = "Click here, or copy and paste it into a browser:\n" + msg

	       mail(to: recipient.email,
              subject: "Password reset instructions",
              body: msg) 
       end

     end


 
