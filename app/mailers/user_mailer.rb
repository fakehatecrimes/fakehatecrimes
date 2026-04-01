class UserMailer < ActionMailer::Base
  default from: "no-reply@fakehatecrimes.org"

  def confirmation_email(user)
    @user = user
    @url  = confirm_users_url(token: @user.confirmation_token)
    Rails.logger.info "UserMailer: confirmation_email: @url #{@url}"
    mail(to: @user.email, subject: "Confirm your account")
  end
end
