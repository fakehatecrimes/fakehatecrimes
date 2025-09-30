require File.join(File.dirname( __FILE__ ), 'generic.rb' )
require File.join(File.dirname( __FILE__ ), '../helpers/application_helper' )
class Fake < ActiveRecord::Base

  include Generic

  self.per_page = NUM_PER_PAGE

  belongs_to :user
  belongs_to :media_type
  has_and_belongs_to_many :media

  attr_accessor :user_id, :media_type_id, :media, :reason, :date, :city, :state

  validates_presence_of :user
  validates_presence_of :media_type, message: " - a report must have a 'type', for example, 'charged with inventing crime'"
  validates_presence_of :reason, message: "summary can't be blank"
  validates_presence_of :date, :state
  validate :date_check
  
  before_save :process_urls_in_reason

# Get rid of hours, minutes and seconds when displaying dates - '1991-01-02' not '1991-01-02 00:00:00'
  def date_yyyy_mm_dd
    Medium.shorten_date read_attribute( :date )
  end

  def date_mmm_d_yyyy
    date_format read_attribute( :date )
  end

  def reason
    get :reason
  end

  def date
    get :date
  end

  def state
    get :state
  end

  def city
    get :city
  end

  def add_medium( medium_id )
    return unless medium_id
    fakes_media = FakesMedium.where( fake_id: get( :id ), medium_id: medium_id )

    return unless fakes_media.empty?
    fakes_medium = FakesMedium.new
    fakes_medium["fake_id"] = get :id
    fakes_medium["medium_id"] = medium_id
    fakes_medium.save!
  end

  def media
    fake_media( self )
  end

def date_check
    date = get :date
    unless date.blank?
      if Medium.comparable(date) > Date.today
        errors.add :date, ' - the date cannot be in the future'
        return false
      end
    end

    true
  end

  def media_check
    type = MediaType.all.select{ |t| t.id == get( :media_type_id )}.first
    if self.media.size < 1 and (type.nil? || type.name.downcase != SUSPECTED.downcase)
      @errors.add( :media, "- a report must have at least one tv, radio, print or online reference unless it's merely '#{SUSPECTED}'" )
      return false
    end

    unless type.nil?
      if type.name.downcase == SUSPECTED.downcase and media.size < 1 and (date.blank? or reason.blank? or state.blank?)
        errors.add( :reason, "- a report of a suspected hoax must have a date, details and why its '#{SUSPECTED}' if there are no tv, radio, print or online references" )
        return false
      end
    end

    true
  end

  def short_description( can_change=false )
    city = get :city
    state = get :state
    reason = get :reason
    "#{ reason.short } #{ self.date_yyyy_mm_dd } #{ city } #{ state }"
  end

  def user_link( can_change )
    return id.to_s + '. <a' + ' id=report_' + id.to_s + '_ href="/reports/' + id.to_s + '/edit">' + short_description + '</a>' if can_change
    return id.to_s + '. <a' + ' id=report_' + id.to_s + '_ href="/reports/' + id.to_s + '">' + short_description + '</a>'
  end

  private

  def process_urls_in_reason
    reason_text = get(:reason)
    return if reason_text.blank?
    
    # Strip all HTML to prevent HTML injection and malformed links
    # This is the safest approach to prevent the whole page from becoming a link
    processed_reason = reason_text.gsub(/<[^>]*>/, '')
    
    self[:reason] = processed_reason
  end

end
