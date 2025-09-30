class PasswordResetsController < ApplicationController

  before_action :require_no_user

  def index
    redirect_to '/'
  end

  def edit
    @token = params[:id]

    render
  end

  def show
    load_user_using_perishable_token params[:token]

    password = params[:password]
    password_confirmation = params[:password_confirmation]
    if password.nil?
      password = params[:user][:password]
      password_confirmation = params[:user][:password_confirmation]
    end
    unless @user.nil?
      @user.password = password
      @user.password_confirmation = password_confirmation
      @user.secret_word = WORDS[0]
    end
    if @user and @user.save
      flash[:notice] = "Password successfully updated"
    else
      flash[:notice] = (@user ? "Error: "+@user.errors.full_messages.join(' ')
                              : "Something went wrong. Please click on the 'forgot password' link again.")
    end

    redirect_to '/' and return
  end

  def new

    if params[:email].to_s.strip == ''
      @user = User.new
      respond_to do |format|
        format.html
      end

    else

      @user = User.find_by_email(params[:email])
      if @user
        @user.deliver_password_reset_instructions!
        flash[:notice] = "Instructions to reset your password have been emailed to you. " +
            "Please check your email."
        redirect_to '/'
      else
        flash[:notice] = "No user was found with that email address"
        redirect_to '/password_resets/new', notice: flash[:notice]
      end
    end

  end

  private

  def load_user_using_perishable_token(token)
    @user = User.find_using_perishable_token(token)

    unless @user
      flash[:notice] = "We could not locate your account. " +
          "If you are having issues try copying and pasting the URL " +
          "from your email into your browser or restarting the " +
          "reset password process."

      redirect_to root_url
    end

  end

end
