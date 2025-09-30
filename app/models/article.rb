require File.join(File.dirname( __FILE__ ), 'generic.rb' )
class Article < ActiveRecord::Base

  include Generic

  DESCRIPTION = "Print or online article, tv or radio program"

  validates_presence_of :name
  validates_uniqueness_of :name
  attr_accessor :name

  has_many :media

  def name
    self.attributes["name"]
  end

end
