class UserSession < Authlogic::Session::Base
  self.logout_on_timeout = true
  
  validate :must_be_confirmed

 private
  def must_be_confirmed
    # Authlogic's magic_states already calls User#confirmed? automatically.
    # This validator just improves the error message when confirmation is pending.
    if attempted_record && !attempted_record.confirmed? && attempted_record.confirmation_token.present?
      errors.add(:base, "Please confirm your email before logging in — check your inbox and spam folder.")
    end
  end
end
