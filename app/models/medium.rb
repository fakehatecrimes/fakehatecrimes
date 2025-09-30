require File.join(File.dirname( __FILE__ ), 'generic.rb' )
require File.join(File.dirname( __FILE__ ), '../helpers/application_helper' )
class Medium < ActiveRecord::Base

  include Generic
  after_find :force_utf8

  YEAR_REG = /^[1-9][0-9][0-9][0-9]$/
  EMPTY_THUMBNAIL = '<span id="thumbnail"/>'
  self.per_page = NUM_PER_PAGE

  belongs_to :user
  belongs_to :article
  has_and_belongs_to_many :fakes

  self.table_name = 'media' # Rails couldn't work it out

  attr_accessor :user_id, :article_id, :url, :title, :retrieval_date, :publication_date, :article_id, :body, :authors, :name
  validates_presence_of :user, :article, :body
  validate :valid_dates
  validate :valid_url
  validate :valid_title
  
  before_save :process_urls_in_body

  def url
    get :url
  end

  def title
    get :title
  end

  def name
    get :name
  end

  def authors
    get :authors
  end

  def body
    get :body
  end

  def article_name
    Article.find( get :article_id ).name
  end

  def valid_title
    self.title = attributes["title"]
    if self.title.blank?
      self.errors.add :title, " - needs title "
    end
  end

  def valid_dates
    rdate = Medium.comparable( self.retrieval_date_yyyy_mm_dd )
    if rdate.blank?
      self.errors.add :retrieval_date, " - the date you saw the article or program cannot be blank"
    end
    pdate = Medium.comparable( self.publication_date_yyyy_mm_dd )
    tdate = Date.today

    unless rdate.blank? or pdate.blank?
      if rdate < pdate
        self.errors.add :retrieval_date, " - the date you saw the article or program cannot be before it was published"
      end
    end
    unless rdate.blank?
      if rdate > tdate       # Since dates are read as 'mmm/dd/yyy 00.00 am', this can only happen if
                             # the retrieval_date is the next day or later
        self.errors.add :retrieval_date, " - the date you saw the article or program cannot be in the future"
      end
    end
    unless pdate.blank?
      if pdate > tdate
        self.errors.add :publication_date, " - the date the article or program became available cannot be in the future"
      end
    end
  end

# Thanks http://net.tutsplus.com/tutorials/other/8-regular-expressions-you-should-know/
# URL_REG = /^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/
# ... except it caused an infinite hang with a long URL, eg.
# http://www.google.com/hostednews/ap/article/ALeqM5iwQW7HgPFajZJSBwsJivEBBeetOQ?docId=29fa56719a3c43cfa6766bebc7a62da2
  URL_STR = "http"
  URL_PRO = "://"
  def valid_url
    url = get :url
    return true if url.blank? # They might not have a URL - that's OK
                              # But if they got one, better check to see if it makes sense
    if url.index( URL_STR ) != 0 or url.index( URL_PRO ).nil?
      self.errors.add :url, " - that doesn't look like a valid URL"
      return false
    end
    true
  end

  def fakes
    medium_fakes(self)
  end

  def urlink
    url = get :url
    return '<br/>' if url.blank?
    link = url.dup
    link = link[0..LINK_SIZE] + '...' if link.size > LINK_SIZE
    "<a href=\"#{ url }\">#{ link }</a>"
  end

  def titlink( can_change, show_id=false )
    title = get :title
    str = ActionView::Base.full_sanitizer.sanitize( title )
    str = 'edit' if str.blank?
    str = str[ 0..SMALL ] + '...' if str.size > SMALL
    id_str = show_id ? id.to_s + ". " : ""
    url = id_str + "<a id=medium_#{ id }_ href=\"/media/#{ id }\">#{ str }</a>"
    return url unless can_change
    id_str + "<a id=medium_#{ id }_ href=\"/media/#{ id }/edit\">#{ str }</a>"
  end

  def short_description( can_change=false, show_id=true )
    res = titlink( can_change, show_id )
    str = body.to_s
    str = str[ 0..SMALL ] if str.size > SMALL
    res += ' / ' + str unless str.blank?
    str = Medium.shorten_date( get :publication_date )
    res += ' / ' + str
    res = res[ 0..LARGE ] if res.size > LARGE
    res
  end

  def either_date
    one = Medium.shorten_date( get :publication_date )
    two = Medium.shorten_date( get :retrieval_date )
    return one if two.blank?
    return two if one.blank?
    one
  end

  def thumbnail
    id = get :id
    return EMPTY_THUMBNAIL unless id
    path = Medium.picture_path( id )
    return EMPTY_THUMBNAIL unless File.exists? path
    "<div style='overflow: hidden; height: 100px; width: 400px; border: 1px solid navy; padding: 3px;'>\n"+
        "<div><img id='thumbnail', src='/data/#{ self.id }.png' />\n"+
    "</div>\n</div>"
  end

  def random_thumbnail
    return EMPTY_THUMBNAIL unless self.id
    path = Medium.picture_path( self.id )
    return EMPTY_THUMBNAIL unless File.exists? path
    margin_top =- rand( 2000 ) - 1
    margin_left =- rand( 500 ) - 1
    "<div style='overflow: hidden; height: 60px; width: 240px; border: 1px solid navy; padding: 3px; float: left; margin-right: 15px; margin-bottom: 10px; margin-top: 2px;'>\n"+
        "<div style='position: relative; margin-top: #{ margin_top }px; margin-left: #{ margin_left }px'>"+
        "<img id='thumbnail', src='/data/#{ self.id }.png' />\n"+
    "</div>\n</div>"
  end

  def picture
    id = get :id
    return '' unless id
    path = Medium.picture_path( id )
    return '' unless File.exists? path
    "<div style='overflow: hidden; height: 500px; width: 1000px; border: 2px solid navy; padding: 2px;'>\n"+
        "<div><a href='/media/#{ self.id }/pic'><img src='/data/#{ self.id }.png' /></a>\n"+
    "</div></div>"
  end

  def full_picture
    "<div style='border: 2px solid navy; padding: 2px;'>\n"+
        "  <img src='/data/#{ self.id }.png' />\n"+
    "</div>"
  end

# Get rid of hours, minutes and seconds when displaying dates - '1991-01-02' not '1991-01-02 00:00:00'
  def retrieval_date_yyyy_mm_dd
    date = get :retrieval_date
    Medium.shorten_date date
  end

  def publication_date_yyyy_mm_dd
    date = get :publication_date
    Medium.shorten_date date
  end

  def retrieval_date_mmm_d_yyyy
    date = get :retrieval_date
    date_format date
  end

  def publication_date_mmm_d_yyyy
    date = get :publication_date
    date_format date
  end

  def empty? # For saving a suspected fake without a medium
    return true if self.title.blank? and self.body.blank? and self.url.blank? and self.retrieval_date.blank? and self.publication_date.blank?
    false
  end

  def create_picture
    ApplicationController::create_picture( self )
  end

  def Medium.comparable( date )
    return date if date.blank? or date.class == Date # If it's blank, we can't help you - if it's already a date, you don't need us
    
    # Handle YYYY-MM-DD format (from HTML5 date inputs)
    if date.class == String && date =~ /^\d{4}-\d{2}-\d{2}$/
      return Date.parse(date)
    end
    
    # Handle MM/DD/YYYY format (legacy)
    if date.class == String && date =~ /^\d{2}\/\d{2}\/\d{4}$/
      return Date.strptime(date, '%m/%d/%Y')
    end
    
    # Fallback to Date.parse for other formats
    begin
      return Date.parse(date.to_s)
    rescue ArgumentError
      return nil
    end
  end

# The parameter is probably a UTC::Time with all kinds of extraneous bumf on the end
  def Medium.shorten_date( time )
    return '' if time.blank?
    time.to_s[ 0 .. ('2012-01-11'.size) - 1 ]
  end

# '09/13/2012' => '2012-09-13'
# Dec 13 2012 - the Calendar has decided to start writing "December 2, 2012" instead of "12/02/2012".
  def Medium.valid_date( time )
    if time =~ DATE_REG
      date = Date.parse time
      return date.to_s
    end
    time[ 6..9 ] + '-' + time[ 0..1 ] + '-' + time[ 3..4 ]
  end

# '2012-09-13 19:30:06 -0800' => '09/13/2012'
  def Medium.this_is_america!( time )
    if time =~ DATE_REG
      time = Medium.valid_date time
    end
    time[ 5..6 ] + '/' + time[ 8..9 ] + '/' + time[ 0..3 ]
  end

  def Medium.any_medium_fields_set?( hash ) # See fakes controller
    hash['title'].present? || hash['retrieval_date'].present?
  end

  def Medium.list( fake ) # Used in new and edit forms to put included media at the top
    media = (fake.nil?? [ ] : fake.media.dup)
    Medium.all.reverse.each_with_index do |medium, index|
      media << medium if index + media.size < MAX_MEDIA unless media.include?( medium )
    end
    media
  end

  def Medium.thumbnail( media )
    return EMPTY_THUMBNAIL if media.size > 5
    media.each { |medium| return medium.thumbnail unless medium.thumbnail == EMPTY_THUMBNAIL }
    EMPTY_THUMBNAIL
  end

  def Medium.random_thumbnail
    Medium.all.shuffle.each { |medium| return medium.random_thumbnail unless medium.random_thumbnail == EMPTY_THUMBNAIL }
    EMPTY_THUMBNAIL
  end

  def Medium.picture_path( id )
    File.join( Rails.root, 'public', 'data', "#{ id }.png" )
  end

  private

  def process_urls_in_body
    body_text = self.body  # Changed from get(:body)
    return if body_text.blank?
    
    # Strip all HTML to prevent HTML injection and malformed links
    # This is the safest approach to prevent the whole page from becoming a link
    processed_body = body_text.gsub(/<[^>]*>/, '')
    
    self.body = processed_body  # Changed from set(:body, processed_body)
  end

  def force_utf8
    if url.present? && url.encoding != Encoding::UTF_8
      self.url = url.dup.force_encoding("UTF-8")
    end
  end
end
