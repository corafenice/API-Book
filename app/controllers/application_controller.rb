class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  before_action :authenticate_admin

  protected

  def pagination(records)
    {
      pagination: {
        per_page: records.per_page,
        total_pages: records.total_pages,
        total_objects: records.total_entries
      }
    }
  end

  def current_user
    @user ||= admin_user
  end

  def current_admin
    @admin
  end

  def admin_user
    return unless @admin && params[:user_id]

    User.find_by(id: params[:user_id])
  end

  def pundit_user
    Contexts::UserContext.new(current_user, current_admin)
  end

  def authenticate
    authenticate_admin_with_token || authenticate_user_with_token || render_unauthorized_request
  end

  def current_user_presence
    unless current_user
      render json: { error: 'Missing a user' }, status: 422
    end
  end
  def not_authorized
    render json: { error: 'Unauthorized' }, status: 403
  end
end

  private

  def authenticate_admin
    authenticate_admin_with_token || render_unauthorized_request
  end

  def authenticate_user
    authenticate_user_with_token || render_unauthorized_request
  end

  def authenticate_admin_with_token
    authenticate_with_http_token do |token, options|
      @admin = User.find_by(api_key: token, admin: true)
    end
  end

  def authenticate_user_with_token
    authenticate_with_http_token do |token, options|
      @user = User.find_by(api_key: token)
    end
  end

  def render_unauthorized_request
    self.headers['WWW-Authenticate'] = 'Token realm="Application"'
    render json: { error: 'Bad credentials' }, status: 401
  end

  def record_not_found
    render json: { error: 'Record not found' }, status: 404
  end
end
