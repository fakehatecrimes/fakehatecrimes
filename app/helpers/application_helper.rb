require "#{ Rails.root }/lib/calendar_date_select/lib/calendar_date_select.rb"

CalendarDateSelect.format = :american

HIT_THIS_BUTTON = "Fill in the form and hit this button"
SAVE_BUTTON = " Save "
SAVING_BE_PATIENT = "Saving - please be patient..."
SAVE_MEDIUM_BUTTON = "Save " + Article::DESCRIPTION.downcase
CLICK_HERE = " Click here "
SEARCH_BUTTON = " Then click here "
ADD_FAKE_BELOW = "Click here to enter a fake hate crime report"
# These two buttons must be labeled differently for the two forms in main/_form to work with fakes controller
ADD_FAKE_ABOVE = "Click here to add a fake hate crime report"
AGREE_TO_RULES_BELOW = "Check here if you have read the rules below and agree to them"
AGREE_TO_RULES_ABOVE = "Check here if you have read the rules above and agree to them"
MUST_BE_USER = "Please join this site and log in to add reports" # Don't say anything about 'administrator'
MUST_BE_ADMIN = MUST_BE_USER
SUSPECTED = 'suspected'
NOT_A_FAKE = 'not a hoax'
SMALL = 200
LARGE = 350
URL_SIZE = 200
LINK_SIZE = 50
TEXT_FIELD_SIZE = 128
NUM_PER_PAGE = 100
MAX_MEDIA = 50
DATE_REG = /^[A-Z][a-z].+ [0-9]+.+[0-9].+$/
INT_DATE_MSG = "(yyyy-mm-dd)"
USA_DATE_MSG = "(mm/dd/yyyy)"

# Hash extensions
class Hash

  def revert
    hash_new = Hash.new
    self.each { |key, value|
      if not hash_new.has_key?(key) then
        hash_new[value] = key
      end
    }
    return hash_new
  end

  KEYS = ['-', '=', '~', '_', '+', '#']
  def recurse(pr=false, n=0, key='')
    str = "\n"
    spaces = ' ' * 2 * (1 + n)
    each do |k, v|
      if v.is_a? Hash
        str += v.recurse(pr, n + 1, k)
      else
        s = "#{k}"
        s = ":#{s}" if k.is_a? Symbol
        pointer = KEYS[ n % KEYS.size ]
        first = (key == '' ? '' : "#{key} #{pointer}>")
        str += "#{spaces}#{first} #{s} #{pointer}> #{v}"
      end
    end
    puts str + "\n" if (n == 0) and pr
    str
  end

  def recurse!
    recurse true
  end

  def remove_unnecessary_keys! # Remove some of the bumf that gets into a controller's params hash
      delete :commit
      delete :controller
      delete :action
      delete :utf8
      delete :authenticity_token
      delete :_method
      delete 'commit'    # The following deletes are unnecessary, if it's a HashWithIndifferentAccess
      delete 'controller'
      delete 'action'
      delete 'utf8'
      delete 'authenticity_token' # If any of these are not there, it doesn't do anything
      delete '_method'
      delete 'media_type_id'
      delete 'reason'
      delete 'date'
      delete 'city'
      delete 'state'
      keys.each do |key|
        if( key.to_s =~ /^media_id_[0-9]+$/ )
          delete( key.to_s )
        end
      end
  end

end

# String extensions
class String

  def short
    num = SMALL / 2
    return self if self.size < num
    self[ 0 .. num-1 ] + '...'
  end

  def shuffle
    m = []
    u = ''

    until u.size == self.size
      n = rand(self.size)
      unless m.include? n
        m << n
        u << self[n]
      end
    end

    u
  end

  def shuffle!
    u = self.shuffle
    u.size.times { |t| self[t..t] = u[t..t] }
  end

# http://stackoverflow.com/questions/862140/hex-to-binary-in-ruby
  def hex_2_bin
    raise "Empty string is not a valid hexadecimal number" if self.size < 1
    hex = self.upcase.split( '' )
    hex.each { |ch| raise "#{self} is not a hexadecimal number" unless "ABCDEF0123456789".include? ch }
    hex = self.upcase
    hex = '0' + hex if((hex.length & 1) != 0)
    hex.scan(/../).map{ |b| b.to_i(16) }.pack('C*')
  end

  def bin_2_hex
    self.unpack('C*').map{ |b| "%02X" % b }.join('')
  end

  def to_b # to boolean - missing from Ruby
    return nil if self.strip.empty?
    return false if self.downcase.starts_with? 'f'
    return false if self == '0' # the opposite of Ruby
    return true if self.downcase.starts_with? 't'
    return true if self == '1'
    nil
  end

end

class NilClass
  def short
    self
  end

  def to_b
    false
  end
end

def can_change?( model ) # e.g. was this report entered by this user or admin? (otherwise they can't edit or delete it)

# puts "can_change? model.class #{model.class} model.get(:id) #{model.get(:id)} model.get(:user_id) #{model.get(:user_id)} current_user.get_id #{current_user.get_id}"

  return false unless current_user
  return true if current_user.admin?
  id = (model.class == User ? model.id : model.get( :user_id )) # Users don't have user ids, they just have ids
  id == current_user.get_id
end

def can_delete?( model )
  return false unless current_user
  current_user.admin?
end

def flash_errs( model )
  errs = ''
  unless model.errors.empty?
    errs = model.errors.collect { |k, v| "#{ k } #{ v }" }.join( '; ')
  end
  flash[:notice] = errs
  errs
end

def word_link
  "/images/word#{rand(16).to_s(16).upcase}.jpg"
end

FLASH_SPAN = '<span style="color: #F94909; font-size: 15px;">'

FAKES_LINK = '<h1>fake hate crimes: a database of <a href="/reports">hate crime hoaxes in the usa</a></h1>'
ENDOF_SPAN = '</span><br/>'
LONG_WORDS = "Not signed up: Email should look like an email address., Email can't be blank, Email is invalid, " +
             "Password is too short (minimum is 4 characters), Password doesn't match confirmation, Password must " +
             "have an upper and lower case letter and a number, and may have punctuation, Password confirmation " +
             "is too short (minimum is 4 characters), Secret word - '' is not valid - try again"
MULTI_LINE = (LONG_WORDS.size.to_f / 2.8)

def flash_format( notice )
  flash = notice
  if flash.blank?
    flash = FAKES_LINK
  else
    flash = FLASH_SPAN + flash + ENDOF_SPAN
  end
  size = 3 - ((flash.size / MULTI_LINE).to_i + 1)
  size = 1 if size < 1
  flash += "<br/>\n" * (size - 1)
  flash
end

def fake_media(fake)
  fakes_media = FakesMedium.all.select{ |fm| fm.fake_id == fake.id }.collect{ |fm| fm.medium_id }
  media = Medium.all.select{ |m| fakes_media.include? m.id }
  media
end

def medium_fakes(medium)
  fakes_media = FakesMedium.all.select{ |fm| fm.medium_id == medium.id }.collect{ |fm| fm.fake_id }
  fakes = Fake.all.select{ |f| fakes_media.include? f.id }
  fakes
end

module ApplicationHelper

  def absolute_path
    "#{request.protocol}#{request.host}#{request.fullpath}"
  end

end
