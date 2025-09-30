# http://www.logansbailey.com/2010/10/06/how-to-setup-authlogic-in-rails-3/
class User < ActiveRecord::Base

  ADMIN = "administrator@fakehatecrimes.org"
  VALID_PASSWORD = "tT@#!55nnvbI"
  INVALID_EMAIL_PASSWORD_OR_SECRET = 'foo'
  MSG = " must have an upper and lower case letter and a number, and may have punctuation"
  EMAIL_REG = /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i # http://www.regular-expressions.info/email.html
  UPPER = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  LOWER = 'abcdefghijklmnopqrstuvwxyz'
  NUMBERS = '0123456789'
  PUNCTUATION = '!@#$%^&*()_+-=<>.{}[]|,;:? '
  VALID_CHARS = UPPER + LOWER + NUMBERS + PUNCTUATION

  acts_as_authentic do |c|
    c.logged_in_timeout(30.minutes)
  end

  before_create :generate_confirmation_token
  before_destroy :reassign_fakes_and_media

  has_many                :fakes
  has_many                :media
  validates_presence_of   :email
  validates_uniqueness_of :email
  validates_format_of     :email, with: EMAIL_REG
  validate                :secret_word_validation
  validate                :password_validation

  attr_accessor :secret_word

  def confirmed?
    confirmed_at.present?
  end

  def confirm!
    update_columns(confirmed_at: Time.current, confirmation_token: nil)
  end

  def user_params
    params.require(:user).permit( :crypted_password, :email, :password_salt, :persistence_token, :password, :password_confirmation, :secret_word)
  end

  def secret_word_validation
    if secret_word.nil? or ( not( WORDS.include?( secret_word.downcase )))
      @errors.add( :secret_word, " - '#{ secret_word }' is not valid - try again" )
      return false
    end
    true
  end

  def password_validation
    upper = UPPER.split ''
    lower = LOWER.split ''
    numbers = NUMBERS.split ''
    punctuation = PUNCTUATION.split ''
    n = false
    l = false
    u = false
    i = true

    pass = password.to_s # in case it's nil
    pwd = pass.split ''
    pwd.each { |p| i = false unless VALID_CHARS.include? p }
    numbers.each { |num| n = true if pass.include?(num) }
    lower.each { |num| l = true if pass.include?(num) }
    upper.each { |num| u = true if pass.include?(num) }
    errors.add(:password, MSG) unless n && l && u && i

    return errors.empty?
  end

  def deliver_password_reset_instructions!
    reset_perishable_token!
    Notifier.password_reset_instructions(self).deliver
  end

  def name
    email.split( '@' )[ 0 ]
  end

  def User.admin!
    User.find_by_email User::ADMIN
  end

  def admin?
    self == User.admin!
  end

  def has_ever_read_rules?
    not rules_read.nil?
  end

  def has_read_rules_recently?
    return false unless has_ever_read_rules?
    return false if Time.now > rules_read + 1.month
    true
  end

  def rules_read!
    self.update_attribute( :rules_read, Time.now )
  end

  def reassign_fakes_and_media
    admin = User.admin!
    raise "I am the administrator! I can never be destroyed!" if self == admin
    fakes.each { |f| admin.fakes << f unless admin.fakes.include?( f ) }
    media.each { |m| admin.media << m unless admin.media.include?( m ) }
  end

  def get_id
    self.id
  end

 private
  def generate_confirmation_token
    self.confirmation_token = SecureRandom.urlsafe_base64
  end

end
