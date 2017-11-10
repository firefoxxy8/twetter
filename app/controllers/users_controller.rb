class UsersController < ApplicationController

  def show
    params[:status] = "@#{user.username} "
    @tweets = user.tweets.timeline.page(params[:page])
  end

  private

  def user
    @user ||= User.find_by_username!(params[:username])
  end
  helper_method :user

end
