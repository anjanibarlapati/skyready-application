module Api
  class BaseController < ActionController::API
    def render_error(status, message)
      render json: { message: message }, status: status
    end
  end
end
