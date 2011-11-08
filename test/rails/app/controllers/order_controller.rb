class OrderController < ApplicationController
  LOG_MESSAGE = "FOO"

  def index
    logger.debug LOG_MESSAGE
    logger.add_metadata(:application_name_again => Rails.root.basename.to_s)
    render :text => "nothing"
  end

  def blow_up
    raise OrderController::LOG_MESSAGE
  end

  def create
  end
end
