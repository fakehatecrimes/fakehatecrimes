class UserSession < Authlogic::Session::Base
  self.logout_on_timeout = true
  
  validate :must_be_confirmed

 private
  def must_be_confirmed
    if attempted_record && !attempted_record.confirmed?
      errors.add(:base, "You must confirm your account before logging in.")
    end
  end
end
