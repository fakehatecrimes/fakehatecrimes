class EmailersController < ApplicationController

   def index
      render file: 'emailers/index.html.haml'
   end

   def sendmail
      errs = validate( params )
      if errs.blank?
        recipient = EMAIL_ADDRESS
        subject =   params["subject"]
        message =   "From #{ params["recipient"] } - \n\n#{ params["message"] }"
        Emailer.contact(recipient, subject, message).deliver
        return if request.xhr?
        flash[:notice] = 'Message sent<br/><br/><a href="/">Continue</a>'
      else
        flash[:notice] = errs
      end
      redirect_to '/email'
   end

 private

  def validate( params )
    errs = ''
    errs += "Not a valid e-mail address<br/>" unless params[ :recipient ] =~ User::EMAIL_REG
    word = params[ :secret_word ].to_s.downcase
    errs += "Invalid captcha word - try again<br/>" unless WORDS.include?( word )
    errs += "You must enter a subject line<br/>" unless params[ :subject ].to_s.strip.size > 0
    errs += "You must enter a meaningful message<br/>" unless params[ :message ].to_s.strip.size > 4
    errs
  end

end
