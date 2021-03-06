class ProfilesController < ApplicationController
  def show
    @user = User.find_by_username(params[:username])
    return not_found unless @user

    @thumbup_num = @user.thumbs.sum(:value)
    @editable = true if current_user == @user
  end

  def edit
    authenticate_user!

    @user = User.find_by_username(params[:username])
    return not_found unless @user

    redirect_to profile_path(@user) unless current_user == @user
  end

  def update
    authenticate_user!

    @user = User.find_by_username(params[:username])
    return not_found unless @user

    return redirect_to profile_path(@user), alert: "You cannot edit another user's profile!" unless current_user == @user

    if @user.update(user_params)
      redirect_to profile_path(@user)
    else
      render :edit
    end

  end

  private

  def user_params
    params.require(:user).permit(:bio)
  end
end
