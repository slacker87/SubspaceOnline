class HomeController < ApplicationController
  include ActionController::Live
  include Tubesock::Hijack
  @@players = []

  def index
    @messages = Message.all.order('created_at DESC').limit(50)
    #try and get players subscribed, not yet working
    #@players = $redis.smembers('joined')
    @@players += [current_or_guest_player.email.gsub(/[^0-9A-Za-z]/, '')]
    @players = @@players
  end

def create
  @message = Message.new
  @message.content = params[:message][:content]
  @message.name = current_or_guest_player.email
  @message.save!
  return render :nothing => true
end

 def chat
    hijack do |tubesock|
      # Listen on its own thread
      redis_thread = Thread.new do
        # Needs its own redis connection to pub
        # and sub at the same time
        Redis.new.subscribe "chat" do |on|
          on.message do |channel, message|
            tubesock.send_data message
          end
        end
      end
      tubesock.onmessage do |m|
        # pub the message when we get one
        # note: this echoes through the sub above
        Redis.new.publish "chat", m
      end
      tubesock.onclose do
        # stop listening when client leaves
        redis_thread.kill
      end
    end
  end

  def joined
    hijack do |tubesock|
      # Listen on its own thread
      redis_thread = Thread.new do
        # Needs its own redis connection to pub
        # and sub at the same time
        Redis.new.subscribe "joined" do |on|
          on.message do |channel, message|
            tubesock.send_data message
          end
        end
      end
      tubesock.onmessage do |m|
        # pub the message when we get one
        # note: this echoes through the sub above
        Redis.new.publish "joined", m
      end
      tubesock.onclose do
        # stop listening when client leaves
        redis_thread.kill
      end
    end
  end

  def movement
    hijack do |tubesock|
      # Listen on its own thread
      redis_thread = Thread.new do
        # Needs its own redis connection to pub
        # and sub at the same time
        Redis.new.subscribe "movement" do |on|
          on.message do |channel, message|
            tubesock.send_data message
          end
        end
      end
      tubesock.onmessage do |m|
        # pub the message when we get one
        # note: this echoes through the sub above
        Redis.new.publish "movement", m
      end
      tubesock.onclose do
        # stop listening when client leaves
        redis_thread.kill
      end
    end
  end
end