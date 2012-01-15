class StatusesController < ApplicationController
  TWEETS_PER_PAGE = 50
  before_filter :find_user
  
  # We don't want to protect search from forgery, cos, well, it's not that important
  protect_from_forgery :except => :search

  def replies
    @tweets = Tweet.mentions(@user).find(:all, :include => :user,:limit => 25)
    render_tweets
  end

  def public_timeline
    friends_timeline
  end

  def friends_timeline
    @page = params[:page].nil? ? 1 : params[:page].to_i
    from = (@page - 1 ) * TWEETS_PER_PAGE
    to = TWEETS_PER_PAGE + from + 1

    @tweets = Tweet.find(
            :all,
            :order => "tweets.created_at DESC",
            :conditions => "tweets.tweet_type!='direct'",
            :include => :user,
            :limit => to,
            :offset => from
    )
    
    @more_pages = (@tweets.length > TWEETS_PER_PAGE)
    @tweets = @tweets[0, TWEETS_PER_PAGE]

    render_tweets
  end

  def search
    @tweets = []
    @keyword = params[:keyword].nil? ? '' : params[:keyword].strip

    if (@keyword.length > 0)
      conditions=["tweets.tweet_type!='direct'"]
      key_conditions=[]
            
      # Run over each of our keywords and construct an array we'll use to
      # generate the SQL snippet.
      params[:keyword].split(/\s/).each do |term|
        key_conditions << 'tweets.tweet LIKE ?'
        conditions << "%#{term}%"
      end

      conditions[0] << " AND (#{key_conditions.join(' AND ')})"
          
      @tweets = Tweet.find(
              :all,
              :order => "tweets.created_at DESC",
              :conditions => conditions,
              :include => :user,
              :limit => TWEETS_PER_PAGE
      )
      if(@tweets.length == TWEETS_PER_PAGE)
        @max_results = TWEETS_PER_PAGE
      end
    end
    render_tweets
  end

  def statistics
    @top_ten_twats = Tweet.top_ten_updaters

    @twats_per_hour = Tweet.updates_per_hour
  end

  def user_timeline
    limit = params[:all] ? 100000000000 : 25
    @tweets = @user.public_tweets.find(:all,:include => :user,:limit => limit)
    render_tweets
  end
  
  def followers
    @users=@user.followers
    render_users
  end
  
  def friends
    @users=@user.friends
    render_users
  end
  
  def show
    @tweet = Tweet.find(params[:id])
    render_tweet
  end
  
  def update
    tweet = params[:status]
    type='tweet'
    if (tweet=~/^d (\S+) (.*)$/m)
      type='direct'
      recipient_name = $1
      tweet = $2
      recipient = User.fetch(recipient_name)
    elsif params['in_reply_to_status_id']
      type="reply"
      in_reply_to_status = Tweet.find_by_id(params['in_reply_to_status_id'])
    end
      
    @tweet = Tweet.create(:tweet => tweet, :user_id => current_user.id, :recipient => recipient, :in_reply_to_status => in_reply_to_status, :tweet_type => type, :source => params[:source] || 'web')
    if (params['twttr'])
        latest_status = render_to_string :partial => "latest", :object=> @tweet
        ret = {"status_count"=>@user.public_tweets.count, "latest_status"=> latest_status,"text"=>tweet}
        ret["status_li"] = render_to_string :partial => "tweet", :object=> @tweet, :locals=>{:type=>'friends_update'}
        render :json => ret
    else
      render partial: 'statuses/tweet', locals: {tweet: @tweet, type: type}
    end
  end
  
  private
  
    def find_user
      @user = User.find_by_username(params[:username]) if params[:username]
    end
end
