
class UserSessionsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]

  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(user_session_params)

    if @user_session.save
      redirect_to users_path
    else
      redirect_to login_path, notice: flash[:notice]
    end
  end

  def destroy
    current_user_session.destroy
    redirect_to login_path
  end

  private

  def user_session_params
    params.require(:user_session).permit(:email, :password).to_h
  end

end
