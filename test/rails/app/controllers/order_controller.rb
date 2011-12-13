class OrderController < ApplicationController
  include MongodbLogger::Base
  LOG_MESSAGE = "FOO"
  LOG_USER_ID = 12345

  def index
    logger.debug LOG_MESSAGE
    logger.add_metadata(:application_name_again => Rails.root.basename.to_s, :user_id => LOG_USER_ID)
    render :text => "nothing"
  end

  def new
    raise OrderController::LOG_MESSAGE
  end

  def create
    render :text => "create"
  end
  
  def test_post
    render :text => "done"
  end
end
