class MediaController < ApplicationController
  before_action :require_user, except: [:search, :index, :show, :pic, :results]

  # {"text"=>"azalea cooley", "commit"=>"Enter something to search for and click here"}
  # {"text"=>"\"Azalea Cooley\"", "commit"=>"Enter something to search for and click here"}
  # {"text"=>"'azalea cooley'", "commit"=>"Enter something to search for and click here"}
  # results = Medium.find_by_sql( "select reason from fakes where   " +
  #                                       reason like '%azalea%' or " +
  #                                       reason like '%george%' union select title from media where "+
  #                                       title like '%azalea%' or "  +
  #                                       title like '%george%'" ) # is cool SQL, but it's not what we need

  def search
    if params[:q].present?
      
      text = params[ :q ]
      @results = [ ]
    
      unless text.blank?
        text.strip!
        quotes = ((text[ 0 ] == "'" or text[ 0 ] == '"') and (text[ -1 ] == "'" or text[ -1 ] == '"'))
        text = text[ 1..-1 ] while (text[ 0  ] == "'" or text[ 0  ] == '"') # User could enter 'Fred Smith"
        text = text[ 0..-2 ] while (text[ -1 ] == "'" or text[ -1 ] == '"') # Strip off the quotes
        text.gsub!( /\W/, ' ' )
        text.gsub!( /\s+/, ' ' )
        text.gsub!( ' ', '%' ) unless quotes
        text.downcase!

        unless text.blank?
          if text =~ Medium::YEAR_REG
            text = "'%" + text + "%'" # Eg. "'%2010%'"
            sql = "select id, url, title, body, authors, name from media where retrieval_date like #{text} or" +
                                                                          " publication_date like #{text} order by id desc"
            media = Medium.find_by_sql sql
            sql = "select id, reason, city, state from fakes where date like #{text}" +
                                          " order by id desc"
            fakes = Fake.find_by_sql sql

          else
            text = "'%" + text + "%'" # Eg. "'%fred smith%'"
            sql = "select id, url, title, body, authors, name from media where url like #{text} or title like #{text} or" +
                                        " body like #{text} or authors like #{text} or name like #{text} order by id desc"
            media = Medium.find_by_sql sql
            sql = "select id, reason, city, state from fakes where reason like #{text} or city like #{text} or" +
                                          " state like #{text} order by id desc"
            fakes = Fake.find_by_sql sql
          end

          n = 0
          while n < media.size or n < fakes.size
            medium = (n < media.size ? media[ n ] : nil)
            fake = (n < fakes.size ?   fakes[ n ] : nil)
            unless medium.nil?
              medium.body = medium.body[ 0..100 ] unless medium.body.blank? or medium.body.size < 101
              medium.title = "show" if medium.title.blank? # Can't happen
              @results << "<a href=\"/media/#{ medium.id }\">#{ medium.title }</a> #{medium.name} #{medium.authors} #{medium.body}"
            end
            unless fake.nil?
              fake.reason = fake.reason[ 0..100 ] unless fake.reason.blank? or fake.reason.size < 101
              fake.reason = "report #{fake.id}" if fake.reason.blank? # Can happen
              @results << "<a href=\"/reports/#{ fake.id }\">#{ fake.reason }</a>"
            end
            n += 1
          end

        end
      end
      render :results
    else
      render :search
    end
  end 

  def index
    @media = Medium.all.reverse.paginate(page: params[:page])
    respond_to do |format|
      format.html
    end
  end

  def new
    @medium = Medium.new if @medium.nil?

    respond_to do |format|
      format.html
    end
  end

  def create
    args = sanitize_params params
    Rails.logger.info "MediaController::create args: #{args.inspect}"
    # Create the medium using the permitted parameters
    @medium = Medium.new(media_params)
    @medium.user = User.find(args["user_id"]) if args["user_id"]
    @medium.article = Article.find(args["article_id"]) if args["article_id"]
    
    # Set additional fields that might not be in media_params
    @medium["title"] = args["medium"]["title"] if args["medium"] && args["medium"]["title"]
    @medium["name"] = args["medium"]["name"] if args["medium"] && args["medium"]["name"]
    @medium["authors"] = args["medium"]["authors"] if args["medium"] && args["medium"]["authors"]
    @medium["url"] = args["medium"]["url"] if args["medium"] && args["medium"]["url"]
    @medium["body"] = args["medium"]["body"] if args["medium"] && args["medium"]["body"]
    @medium["retrieval_date"] = args["retrieval_date"] if args["retrieval_date"]
    @medium["publication_date"] = args["publication_date"] if args["publication_date"]
    Rails.logger.info "MediaController::create medium.body: #{@medium.body}"
    
    respond_to do |format|
      if @medium.save
        @medium.create_picture
        format.html { redirect_to '/media', notice: Article::DESCRIPTION + ' saved' }
      else
        flash_errs( @medium )
        format.html { render template: 'media/new' }
      end
    end
  end

  def show
    @medium = Medium.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def edit
    @medium = Medium.find(params[:id])
  end

  def pic
    @medium = Medium.find(params[:id])
  end

  def update
    args = sanitize_params params
    @medium = Medium.find(params[:id])  # Use params[:id] instead of media_params[:id]
    @medium["title"] = args["medium"]["title"]
    @medium["url"] = args["medium"]["url"]
    @medium["name"] = args["medium"]["name"]
    @medium["authors"] = args["medium"]["authors"]
    @medium["body"] = args["medium"]["body"]
    @medium["retrieval_date"] = args["medium"]["retrieval_date"]
    @medium["publication_date"] = args["medium"]["publication_date"]
    @medium.article = Article.find(args["article_id"])

    respond_to do |format|
      if @medium.save
        @medium.create_picture
        format.html { redirect_to '/media', notice: 'Updated' }
      else
        flash_errs( @medium )
        format.html { render template: 'media/edit' }
      end
    end
  end

  def destroy
    Medium.delete_all("id = " + media_params["id"].to_s)

    respond_to do |format|
      format.html { redirect_to('/media', notice: '') }
    end
  end

  def media_params
    # Handle both nested medium parameters and top-level parameters
    if params[:medium]
      params.require(:medium).permit(:title, :name, :authors, :url, :body)
    else
      params.permit(:id, :user_id, :title, :name, :authors, :url, :body, :retrieval_date, :publication_date, :article_id)
    end
  end

end
