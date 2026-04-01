class UsersController < ApplicationController
  skip_before_action :require_login, only: [:new]
  before_action :set_user, only: [:show, :edit, :update, :destroy]

   # GET /users
   # GET /users.json
   def index
     @users = User.all
   end

   # GET /users/1
   # GET /users/1.json
   def show
   end

   # GET /users/new
   def new
     @user = User.new
   end


  def edit
    @user = User.find(params[:id])

    unless can_change?( @user )

      flash[ :notice ] = MUST_BE_USER
      redirect_to( '/' )

    end
  end

  def create
    @user = User.new(user_create_params)
    
    respond_to do |format|
      if @user.save
        UserMailer.confirmation_email(@user).deliver_now
        format.html { redirect_to "/", notice: "Please check your email, including the Spam folder. The email can take over 10 minutes to arrive." }
      else
        flash_errs @user
        format.html { redirect_to "/users/new", notice: flash[:notice] }
      end
    end
  end

  def update
    @user = User.find(params[:id])

    old_password = params[ :user ][ :old_password ]
    params[ :user ].delete :old_password
    @user.errors.add( :password, " - old password must be filled in") if old_password.blank?
    @user.errors.add( :password, " - old password is wrong") unless @user.valid_password?( old_password )
    params[:user][:secret_word] = WORDS[0]

    respond_to do |format|
      if @user.errors.empty? && @user.update(user_update_params)
        format.html { redirect_to :users, notice: 'Updated' }

      else
        flash_errs @user
        format.html { redirect_to "/users/#{params[:id]}/edit", notice: flash[:notice] }

      end
    end
  end

  def destroy
    @user = User.find(params[:id])

    if @user.admin?
      @user.errors.add( :email, ' - admin user cannot be deleted' )
      flash_errs @user
    else
#      User.delete_all("id = " + @user.id.to_s) # didn't call the callback in user.rb: before_destroy :reassign_fakes_and_media
      @user.destroy                             # this does call the callback

      respond_to do |format|
        format.html { redirect_to(:users, notice: 'Deleted') }

      end
    end
  end

  def confirm
    @user = User.find_by(confirmation_token: params[:token])
  
    if @user && @user.confirmed_at.nil?
      # Skip validations here
      @user.update_columns(
        confirmation_token: nil,
        confirmed_at: Time.current
      )
      flash[:notice] = "Your account has been confirmed. Please log in."
      redirect_to new_user_session_path
    else
      flash[:notice] = "Invalid or already used confirmation link."
      redirect_to root_path
    end
  end
  
   private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    def user_create_params
      params.require(:user).permit(:email, :password, :password_confirmation, :secret_word)
    end

    def user_update_params
      params.require(:user).permit(:password, :password_confirmation, :old_password, :secret_word)
    end
end
