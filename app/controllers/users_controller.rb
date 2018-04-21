module V1
  class UsersController < ApplicationController
    before_action :set_user, only: [:show, :destroy, :update]
    before_create :generate_api_key

    def index
      users = User.preload(:book_copies).paginate(page: params[:page])
      render json: users, meta: pagination(users), adapter: :json
    end

    def show
      render json: @user, adapter: :json
    end

    def create
      user = User.new(user_params)
      if user.save
        render json: user, adapter: :json, status: 201
      else
        render json: { error: user.errors }, status: 422
      end
    end

    def update
      if @user.update(user_params)
        render json: @user, adapter: :json, status: 200
      else
        render json: { error: @user.errors }, status: 422
      end
    end

    def destroy
      @user.destroy
      head 204
    end

    private

    def generate_api_key
      loop do
        self.api_key = SecureRandom.base64(30)
        break unless User.exists?(api_key: self.api_key)
      end
    end

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:first_name, :last_name, :email)
    end
  end
end
