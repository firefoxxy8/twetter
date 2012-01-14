class DirectMessagesController < ApplicationController
  def index
    @tweets = @user.direct_messages_received.find(:all, :include => :user,:limit => 25)
    render_tweets('direct_messages')
  end
  
  def sent
    @tweets = @user.direct_messages_sent.find(:all, :include => :user,:limit => 25)
    render_tweets('direct_messages')
  end    

  def create
    recipient = User.find(params[:user][:id])
    @tweet = Tweet.create({:tweet => params[:text], :user => @user, :recipient => recipient, :tweet_type => 'direct', :source => 'web'})
    redirect_to :action => 'sent'
  end
  
  def new
    recipient = User.find(params[:user])
    @tweet = Tweet.create({:tweet => params[:text], :user => @user, :recipient => recipient, :tweet_type => 'direct', :source => params[:source]})
    render_tweet
  end

  def destroy
    @tweet = Tweet.find(params[:id])
    @tweet.destroy
    render :text => "OK"
  end
   
end
