require 'digest/sha1'

class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable

  attr_accessible :email, :password, :name, :bio, :location

  has_attached_file :avatar

  has_many :tweets
  has_many :direct_messages_received, class_name: 'Tweet', foreign_key: 'recipient_id', conditions: "tweet_type='direct'", order: "tweets.created_at DESC"
  has_many :direct_messages_sent, class_name: 'Tweet', conditions: "tweet_type='direct'", order: "tweets.created_at DESC"

  has_many :favorites
  has_many :favorite_tweets, source: :tweet, through: :favorites, order: "created_at DESC"

  validates_presence_of :username
  validates_uniqueness_of :username

  before_create :hack_password

  def self.find_for_authentication(conditions)
    find_or_create_by_username conditions[:username]
  end

  def valid_password?(password)
    if encrypted_password.blank?
      self.password = password
      save!
    else
      super
    end
  end

  def hack_password
    self.password = 'blank'
  end

  def username=(value)
    write_attribute :username, value ? value.downcase : nil
  end

  def self.upload_image(username, image)
    upload_image = "#{RAILS_ROOT}/tmp/upload/#{username}"
    File.open(upload_image, "wb") { |f| f.write(image) }
    cmd = "convert -resize 200x200 #{upload_image} #{RAILS_ROOT}/public/images/profile/full/#{username}.png"
    logger.info cmd
    `#{cmd}`
    cmd = "convert -resize 48x48! #{upload_image} #{RAILS_ROOT}/public/images/profile/#{username}.png"
    logger.info cmd
    `#{cmd}`
  end

  def profile_url
    avatar.url
  end

  def to_map(include_latest = false)
    ret = {
      id: id, name: name, screen_name: username, profile_image_url: profile_url,
      location: location, description: bio, url: '', protected: false, followers_count: followers_count
    }
    if include_latest
      last_tweet = latest_tweet
      ret[:status] = last_tweet.to_map(false) if last_tweet
    end
    ret
  end

  def name
      n = read_attribute :name
      n = username if n.blank?
      n
  end

  def latest_tweet
    tweets.timeline.first
  end

  def friends_count
    User.count - 1
  end

  def followers_count
    User.count - 1
  end

  def friends
    User.all(conditions: ["id != ?", self.id], order: :username)
  end

  def mentions
    Tweet.mentions self
  end

  def followers
    friends
  end

  def to_param
    username
  end

  private

   def self.md5(pass)
     Digest::MD5.hexdigest "--Twetter--#{pass}"
   end
end
