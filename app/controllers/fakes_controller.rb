class FakesController < ApplicationController
  before_action :require_user, except: [:index, :show]

  def index
    @fakes = Fake.all.reverse.paginate(page: params[:page])
    
    if params[:commit] == HIT_THIS_BUTTON # or params[:commit] == SAVE_MEDIUM_BUTTON
      create params.dup
    else
      respond_to do |format|
        format.html
      end
    end
  end

  def show
    @fake = Fake.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  # {"utf8"=>"✓", "authenticity_token"=>"I1CM2HtpN3tZBeOLUHDOnj2HdwFPoMYogf5Avh1Iumw=",
  # "I have read the rules and agree to them"=>"yes", "commit"=>"Click here to add a fake hate crime report"}
  def new
    ok = current_user.has_read_rules_recently?
# The 2 main/_form submit buttons (params['commit']) must have different labels, even though this action doesn't look at that param. See application_helper.
    if (params[ AGREE_TO_RULES_BELOW ] == 'yes' or params[ AGREE_TO_RULES_ABOVE ] == 'yes')
      ok = true
      current_user.rules_read!
    end

    if ok
      @fake = Fake.new if @fake.nil?
      @medium = Medium.new if @medium.nil?
      respond_to do |format|
        format.html
      end
    else
      flash[ :notice ] = (current_user.has_ever_read_rules??
        "The rules may have changed: please read and agree to them before reporting a fake hate crime" : # Need to read them again
        "Please read the rules and agree to them before reporting a fake hate crime" )                   # They've never read them
      redirect_to '/rules'
    end

  end

  def edit
    @fake = Fake.find(params[:id])
  end

  def create(*args) # This can be passed a parameter, otherwise, it acts like a normal Rails create method
    # When invoked as a Rails action, args will be empty; use params in that case
    incoming = args.present? ? args.first : params
    sanitized = sanitize_params incoming

    respond_to do |format|
      # Build arguments hash expected by the rest of the flow
      arguments = sanitized.dup
      arguments['medium'] ||= {}
      arguments['user_id'] ||= sanitized['user_id']
      arguments['article_id'] ||= sanitized['article_id']
      arguments['medium']['user_id'] = arguments['user_id']
      arguments['medium']['article_id'] = arguments['article_id']

      @medium = create_medium_if_possible(arguments.dup)
      @fake = find_or_initialize_report(arguments.dup) # The fakes/new form has an area for creating a new medium too
      
      # Ensure date values are properly set from form parameters
      # Handle dates directly without complex parsing to avoid issues
      if arguments['date'].present?
        begin
          @fake.date = Date.parse(arguments['date'])
        rescue ArgumentError
          @fake.date = arguments['date'] # Keep as string if parsing fails
        end
      end
      
      if arguments['retrieval_date'].present?
        begin
          @medium.retrieval_date = Date.parse(arguments['retrieval_date'])
        rescue ArgumentError
          @medium.retrieval_date = arguments['retrieval_date'] # Keep as string if parsing fails
        end
      end
      
      if arguments['publication_date'].present?
        begin
          @medium.publication_date = Date.parse(arguments['publication_date'])
        rescue ArgumentError
          @medium.publication_date = arguments['publication_date'] # Keep as string if parsing fails
        end
      end

      uid = arguments['user_id']
      if uid.blank?
        format.html { redirect_to('/', notice: 'Invalid parameters') }
      else
        @fake.user = User.find uid
        # Check if medium fields were actually provided
        if Medium.any_medium_fields_set?(arguments)
          notice = try_to_save_report( arguments, @fake, @medium )
        else
          notice = try_to_save_report_without_medium( arguments, @fake )
        end
        if notice =~ /Report saved/
          format.html { redirect_to('/', notice: notice) }
        else
          # On errors, render new so the form shows validation messages
          flash[:notice] = notice
          # Ensure the objects have the user's input for re-rendering
          # Handle dates directly without complex parsing to avoid issues
          if arguments['date'].present?
            begin
              @fake.date = Date.parse(arguments['date'])
            rescue ArgumentError
              @fake.date = arguments['date'] # Keep as string if parsing fails
            end
          end
          
          if arguments['retrieval_date'].present?
            begin
              @medium.retrieval_date = Date.parse(arguments['retrieval_date'])
            rescue ArgumentError
              @medium.retrieval_date = arguments['retrieval_date'] # Keep as string if parsing fails
            end
          end
          
          if arguments['publication_date'].present?
            begin
              @medium.publication_date = Date.parse(arguments['publication_date'])
            rescue ArgumentError
              @medium.publication_date = arguments['publication_date'] # Keep as string if parsing fails
            end
          end
          format.html { render template: 'fakes/new' }
        end
      end
    end
  end

# {"fake"=>{"user_id"=>"1", "date"=>"2019-07-01", "city"=>"London", "state"=>"ON", "reason"=>"Why I think it's a hoax"},
# "media_type"=>"3", "media_id_465"=>"465", "commit"=>"Fill in the form and hit this button", "id"=>"322"}
  def update
    args = params.merge params["fake"]
    args = sanitize_params args 

    @fake = Fake.find(params[:id])
    uid = @fake.user_id.nil?? current_user.id : @fake.user_id
    args["user_id"] = uid

    @fake = find_or_initialize_report(args.dup)

    FakesMedium.where(fake_id: params[:id]).delete_all
    keys = args.keys.dup

    add_media @fake, keys

    respond_to do |format|
      notice = try_to_save_report_update( args, @fake )

      if notice =~ /Report saved/
        format.html { redirect_to('/reports', notice: notice) }
      else
        format.html { redirect_to("/reports/#{params[:id]}/edit", notice: notice) }
      end
    end
  end

  def destroy
    @fake = Fake.find(params[:id])

    Fake.delete @fake.id

    respond_to do |format|
      notice = 'Report deleted'
      flash[:notice] = notice
      format.html { redirect_to("/reports", notice: notice) }
    end
  end

  private

  def try_to_save_report( args, fake, medium )

    if fake.valid?
      type = MediaType.all.select{ |t| t.id == fake.get( :media_type_id )}.first

      if type.attributes['name'].downcase == SUSPECTED.downcase
        # For suspected reports, medium is optional but if provided must be valid
        if Medium.any_medium_fields_set?(args)
          unless medium.save
            # Medium was provided but invalid
            medium_errors = medium.errors.full_messages.join('; ')
            notice = 'Report not saved: ' + flash_errs( fake ) + (medium_errors.present? ? '; ' + medium_errors : '')
            flash[:notice] = notice
            return notice
          end
        end
      else
        # For non-suspected reports, medium is required and must be valid
        unless medium.save
          fake.errors.add( :media, "- a report of a fake must have at least one tv, radio, print or online reference unless it's merely '#{SUSPECTED}'" )
          # Also add medium validation errors to the notice
          medium_errors = medium.errors.full_messages.join('; ')
          notice = 'Report not saved: ' + flash_errs( fake ) + (medium_errors.present? ? '; ' + medium_errors : '')
          flash[:notice] = notice
          return notice
        end
      end
      fake.save!

      keys = args.keys.dup
      add_media fake, keys
      fake.add_medium medium.id if medium.id
      notice = 'Report saved'
      flash[:notice] = notice
      return notice
    else
      fake.media_check
      notice = 'Report not saved: ' + flash_errs( fake )
      flash[:notice] = notice
      return notice
    end
  end

  def try_to_save_report_without_medium( args, fake )
    if fake.valid?
      type = MediaType.all.select{ |t| t.id == fake.get( :media_type_id )}.first
      
      # Check if medium is required for this report type
      if type.attributes['name'].downcase != SUSPECTED.downcase
        # Non-suspected reports require a medium
        fake.errors.add( :media, "- a report of a fake must have at least one tv, radio, print or online reference unless it's merely '#{SUSPECTED}'" )
        notice = 'Report not saved: ' + flash_errs( fake )
        flash[:notice] = notice
        return notice
      end
      
      # For suspected reports, no medium is required
      fake.save!
      keys = args.keys.dup
      add_media fake, keys
      notice = 'Report saved'
      flash[:notice] = notice
      return notice
    end
    fake.media_check
    notice = 'Report not saved: ' + flash_errs( fake )
    flash[:notice] = notice
    return notice
  end

  def try_to_save_report_update( args, fake )
    if fake.valid?
      # For updates, we don't require media validation since the report already exists
      # and may already have media associated with it
      fake.save!
      keys = args.keys.dup
      add_media fake, keys
      notice = 'Report saved'
      flash[:notice] = notice
      return notice
    end
    fake.media_check
    notice = 'Report not saved: ' + flash_errs( fake )
    flash[:notice] = notice
    return notice
  end

  def add_media( fake, keys )

    keys.each do |key|
      if key.to_s =~ /^media_id_[0-9]+$/ # Find the checkboxes which look like this: media_id_42 - user chose medium with id 42
        mid = key.to_s[ 'media_id_'.size .. -1 ].to_i # Only the keys matter - if the box wasn't checked, the key isn't there
        fid = fake.id
        fms = FakesMedium.where( fake_id: fid, medium_id: mid )
        if fms.empty?
          fm = FakesMedium.new
          fm.fake_id = fid
          fm.medium_id = mid
          fm.save!
        end
      end
    end
  end

  def find_or_initialize_report(args)
    args.delete 'retrieval_date'
    args.delete 'publication_date'
    args.delete 'medium'

    tid = args["media_type_id"]
    tid = args["media_type"] if tid.nil?
    uid = args["user_id"]
    rsn = args["reason"]
    stt = args["state"]
    cty = args["city"]
    dat = args["date"]
    aid = args["article_id"]
    fid = args["id"]
    arguments = {media_type_id: tid, user_id: uid, reason: rsn, state: stt, city: cty, date: dat}

    if fid
      fake = Fake.find fid
    else
      fake = Fake.new( arguments )
    end

    fake.user = User.find uid
    fake.media_type = MediaType.find tid
    fake["reason"] = rsn
    fake["state"] = stt
    fake["city"] = cty
    fake["date"] = dat

    unless dat.blank?
      errs = nil
      dat = Medium.valid_date(dat)
      begin
        dat = DateTime.parse(dat)
      rescue ArgumentError => err
        errs = ' - invalid date'
      end
      unless errs.nil?
        fake.errors.add( :date, errs )
        return fake
      end
    end

    if fake.nil?
      fake = Fake.new( arguments )
    end
    return fake
  end

end
