require 'will_paginate/array'
require 'timeout'

class ApplicationController < ActionController::Base
  protect_from_forgery

  helper_method :current_user_session, :current_user
  helper_method :logged_in?

  HASHY = [ActiveSupport::HashWithIndifferentAccess, ActionController::Parameters, Hash]

  def remove_html_tags str # https://snippets.aktagon.com/snippets/192-Removing-HTML-tags-from-a-string-in-Ruby
    reg = /<("[^"]*"|'[^']*'|[^'">])*>/
    str.gsub!(reg, '')
  end

  def sanitize_params params
    args = params.dup
    args.each do |k, v|
      if HASHY.include? v.class
        args[k] = sanitize_params v # Recursion
      elsif (String == v.class) && (v.include? "<")
        args[k] = remove_html_tags v
      end
    end
    args['url'] = args['url'][0..254] if args['url'].present? && args['url'].size > 255
    args
  end

# {"user_id"=>"1", "medium"=>{"title"=>"Another boring program", "name"=>"My program"} }
# becomes
# {"user_id"=>"1", "title"=>"Another boring program", "name"=>"My program"}
  def squish( hash, n = 0 )
    @hash = { } if n == 0
    hash.each do |k, v|
      if v.is_a? Hash
        hash[ k ] = squish( v, n + 1 )
      else
        @hash[ k ] = v
      end
    end
    @hash
  end

  def create_medium_if_possible(params)

    raise "create_medium_if_possible can only be called from the fakes controller or the media controller" unless
        self.class == FakesController or self.class == MediaController
    Rails.logger.info "create_medium_if_possible"
    args = sanitize_params params
    hash = squish args
    hash.remove_unnecessary_keys!

    errs = []
    ['retrieval_date', 'publication_date'].each do |str|
      unless hash[str].blank?
        begin
          # Handle YYYY-MM-DD format from HTML5 date inputs
          hash[str] = Date.parse(hash[str])
        rescue ArgumentError => err
          errs << err.message
          hash[str] = ''
        end
      end
    end

    @medium = Medium.new(hash)

    # Only skip validation if no medium fields are set AND we're in FakesController
    if self.class == FakesController && ! Medium.any_medium_fields_set?(hash)
      Rails.logger.info "create_medium_if_possible: skipping validation"
      return @medium
    end

    if errs.present?
      @medium.errors.clear
      @medium.errors.add :retrieval_date, ' - invalid date'
      flash_errs( @medium )
      Rails.logger.info "create_medium_if_possible: skipping validation because of errors #{errs.join(', ')}"
      return @medium
    end

    @medium.user = User.find(hash["user_id"])
    @medium["title"] = hash["title"]    # The only way which works
    hash.each do |k, v|
      @medium[k.to_s] = v
    end
    @medium.article_id = hash["article_id"]

    done = @medium.valid?
    Rails.logger.info "create_medium_if_possible: valid? #{done}"            
    unless done
      if self.class == FakesController
        flash_errs( @medium )
        return @medium
      end
    end

    if done 
      @medium.save!
      Rails.logger.info "create_medium_if_possible: create_picture"
      @medium.create_picture
    else
      Rails.logger.info "create_medium_if_possible: not creating picture"
    end

    if self.class == MediaController # A medium can be saved from the new fake form as well as the new media form - only redirect for the latter case
      respond_to do |format|
        if done
          format.html { redirect_to '/media', notice: Article::DESCRIPTION + ' saved' }
        else
          flash_errs @medium
          format.html { render template: 'media/new' }
        end
      end
    end

    Rails.logger.info "create_medium_if_possible: returning medium"
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

  def ApplicationController::create_picture( medium )
    Rails.logger.info "ApplicationController::create_picture medium: '#{medium.nil? ? 'nil' : medium.id}'"
    
    return if medium.nil?
    return if medium.url.blank?
    return if medium.id.blank?
    
    Rails.logger.info "=== Screenshot Request ==="
    Rails.logger.info "Medium ID: #{medium.id}"
    Rails.logger.info "URL: #{medium.url}"
    Rails.logger.info "Path: #{Medium.picture_path(medium.id)}"
    
    begin
      # Check if screenshot already exists
      path = Medium.picture_path(medium.id)
      if File.exist?(path)
        Rails.logger.info "Screenshot already exists - skipping"
        return
      end
      
      # ScreenshotMachine API configuration
      api_key = 'ccd69a'  # Replace with your actual API key
      base_url = 'https://api.screenshotmachine.com'
      
      # Build the API request URL
      params = {
        key: api_key,
        url: medium.url,
        dimension: '1024x768',
        format: 'png',
        cacheLimit: 0  # Don't use cached results
      }
      
      api_url = "#{base_url}?#{params.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')}"
      Rails.logger.info "API URL: #{api_url}"
      
      # Make the HTTP request
      require 'net/http'
      require 'uri'
      require 'timeout'
      
      uri = URI(api_url)
      Timeout::timeout(30) do
        response = Net::HTTP.get_response(uri)
        
        if response.code == '200'
          # Save the image
          File.open(path, 'wb') do |f|
            f.write(response.body)
          end
          Rails.logger.info "Screenshot saved successfully to: #{path}"
        else
          Rails.logger.error "ScreenshotMachine API error: #{response.code} - #{response.message}"
        end
      end
      
    rescue Timeout::Error
      Rails.logger.error "Screenshot request timed out for Medium #{medium.id}"
    rescue => e
      Rails.logger.error "Screenshot error for Medium #{medium.id}: #{e.message}"
    end
    
    Rails.logger.info "========================="
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
