require 'will_paginate/array'
require 'timeout'

class ApplicationController < ActionController::Base

  protect_from_forgery

  helper_method :current_user_session, :current_user
  helper_method :logged_in?

  def create_medium_if_possible(params)

    raise "create_medium_if_possible can only be called from the fakes controller or the media controller" unless
        self.class == FakesController or self.class == MediaController

    hash = params.squish
    hash.remove_unnecessary_keys!

    errs = []
    ['retrieval_date', 'publication_date'].each do |str|
      unless hash[str].blank?
        date = Medium.valid_date(hash[str])
        begin
          hash[str] = DateTime.parse(date)
        rescue ArgumentError => err
          errs << err.message
          hash[str] = ''
        end
      end
    end

    @medium = Medium.new(hash)

    return @medium unless Medium.any_medium_fields_set?( hash ) if self.class == FakesController

    if errs.present?
      @medium.errors.clear
      @medium.errors.add :retrieval_date, ' - invalid date'
      flash_errs( @medium )
      return @medium
    end

    @medium.user = User.find(hash["user_id"])
    @medium["title"] = hash["title"]    # The only way which works
    hash.each do |k, v|
      @medium[k.to_s] = v
    end
    @medium.article = Article.find(hash["article_id"])

    done = @medium.valid?

    unless done
      if self.class == FakesController
        flash_errs( @medium )
        return @medium
      end
    end

#    ApplicationController.create_picture( @medium ) if done

    if self.class == MediaController # A medium can be saved from the new fake form as well as the new media form - only redirect for the latter case
      respond_to do |format|
        if done
          format.html { redirect_to '/media', notice: Article::DESCRIPTION + ' saved' }
        else
          flash_errs @medium
          format.html { render action: "new" }
        end
      end
    end

    @medium
  end

  def require_user
    unless current_user
      store_location
      flash[:notice] = MUST_BE_USER
      redirect_to new_user_session_url
      false
    end
    true
  end

  def require_admin
    user = (! current_user.nil?)
    admin = false
    if user
      admin = true if current_user.admin?
    end
    unless admin
      store_location
      flash[:notice] = MUST_BE_ADMIN
      redirect_to new_user_session_url
    end
    admin
  end

  def require_no_user
    if current_user
      store_location
      flash[:notice] = ""
      redirect_to '/'
      false
    end
    true
  end

  def store_location
    #   session[:return_to] = request.request_uri
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def ApplicationController.create_picture( medium )
    return
    return if medium.url.blank?
    return if medium.id.blank?
    puts "application_controller create_picture beginning"
    begin
      path = Medium.picture_path( medium.id )
      fetcher = Screencap::Fetcher.new( medium.url )
      screenshot = fetcher.fetch(
          {output: path
           # ,
           # div: '.header',
           # width: 1024,
           # height: 768,
           # top: 0, left: 0, width: 100, height: 100
          } )
      puts "application_controller create_picture finished"
    rescue Exception => x
      puts "\n###\nException creating Screencap of Medium #{ medium.id }'s URL #{ medium.url }:\n #{ x.message }\n###"
    end
end

  private

   def current_user_session
     return @current_user_session if defined? @current_user_session
     @current_user_session = UserSession.find
   end

   def current_user
     return @current_user if defined? @current_user
     @current_user = current_user_session && current_user_session.user
   end

   def logged_in?
     !! current_user_session
   end

   def require_login
     redirect_to login_path unless logged_in?
   end

end
