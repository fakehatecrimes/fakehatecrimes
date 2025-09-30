require File.join(File.dirname( __FILE__ ), 'generic.rb' )
class MediaType < ActiveRecord::Base
  include Generic

  self.table_name = :types

  validates_presence_of :name
  validates_uniqueness_of :name
  attr_accessor :name

  has_many :fakes

  def name
    get :name
  end

  def id
    get :id
  end

end
