class MediaController < ApplicationController
  before_action :require_user, except: [:search, :index, :show, :pic]

  # {"text"=>"azalea cooley", "commit"=>"Enter something to search for and click here"}
  # {"text"=>"\"Azalea Cooley\"", "commit"=>"Enter something to search for and click here"}
  # {"text"=>"'azalea cooley'", "commit"=>"Enter something to search for and click here"}
  def search
  # results = Medium.find_by_sql( "select reason from fakes where   " +
  #                                       reason like '%azalea%' or " +
  #                                       reason like '%george%' union select title from media where "+
  #                                       title like '%azalea%' or "  +
  #                                       title like '%george%'" ) # is cool SQL, but it's not what we need
    @results = [ ]
    text = params[:text]
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

    respond_to do |format|
      format.html { render html: @results }
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
    @medium = create_medium_if_possible( params.dup )
    @medium.save! if @medium.valid?
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
    @medium = Medium.find(media_params[:id])
    @medium["title"] = params["medium"]["title"]
    @medium["url"] = params["medium"]["url"]
    @medium["name"] = params["medium"]["name"]
    @medium["authors"] = params["medium"]["authors"]
    @medium["body"] = params["medium"]["body"]
    @medium["retrieval_date"] = params["medium"]["retrieval_date"]
    @medium["publication_date"] = params["medium"]["publication_date"]
    @medium.article = Article.find(media_params["article_id"])

    respond_to do |format|
      if @medium.save
        ApplicationController.create_picture( @medium )
        format.html { redirect_to '/media', notice: 'Updated' }
      else
        errs = 'Medium not saved: ' + flash_errs( @medium )
        flash[:notice] = errs
        format.html { render action: "edit" }
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
    params.permit(:id, :user_id, :title, :name, :authors, :url, :body, :retrieval_date, :publication_date, :article_id)
  end

end
