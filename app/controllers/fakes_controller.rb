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
    arguments = args[0].dup
    arguments['medium']['user_id'] = arguments['user_id']
    arguments['medium']['article_id'] = arguments['article_id']

    @medium = create_medium_if_possible(arguments.dup)
    @fake = find_or_initialize_report(arguments.dup) # The fakes/new form has an area for creating a new medium too

    respond_to do |format|
      uid = arguments['user_id']
      @fake.user = User.find uid
      notice = try_to_save_report( arguments, @fake, @medium )
      if notice =~ /Report saved/
        format.html { redirect_to('/reports', notice: notice) }
      else
        format.html { render action: "new", notice: notice }
      end
    end
  end

# {"fake"=>{"user_id"=>"1", "date"=>"2019-07-01", "city"=>"London", "state"=>"ON", "reason"=>"Why I think it's a hoax"},
# "media_type"=>"3", "media_id_465"=>"465", "commit"=>"Fill in the form and hit this button", "id"=>"322"}
  def update
    args = params.merge params["fake"]

    @fake = Fake.find(params[:id])
    @fake = find_or_initialize_report(args.dup)

    FakesMedium.where(fake_id: params[:id]).delete_all
    keys = args.keys.dup

    add_media @fake, keys

    respond_to do |format|
      notice = try_to_save_report( args, @fake )

      if notice =~ /Report saved/
        format.html { redirect_to('/reports', notice: notice) }
      else
        format.html { render action: "edit", notice: notice }
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

  def try_to_save_report( args, fake, medium=nil )

    if medium.nil?
      return try_to_save_report_without_medium( args, fake )
    end

    if fake.valid?
      type = MediaType.all.select{ |t| t.id == fake.get( :media_type_id )}.first

      if type.attributes['name'].downcase == SUSPECTED.downcase
        medium.save
      else
        unless medium.save
          fake.errors.add( :media, "- a report of a fake must have at least one tv, radio, print or online reference unless it's merely '#{SUSPECTED}'" )
          return
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
    arguments = {:media_type_id => tid, :user_id => uid, reason: rsn, state: stt, city: cty, date: dat}

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
