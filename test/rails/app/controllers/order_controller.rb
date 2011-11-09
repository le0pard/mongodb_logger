class OrderController < ApplicationController
  include MongodbLogger::Base
  LOG_MESSAGE = "FOO"

  def index
    logger.debug LOG_MESSAGE
    logger.add_metadata(:application_name_again => Rails.root.basename.to_s)
    render :text => "nothing"
  end

  def new
    raise OrderController::LOG_MESSAGE
  end

  def create
    render :text => "create"
  end
end
