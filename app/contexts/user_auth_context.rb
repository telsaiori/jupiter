class UserAuthContext < BaseContext
  before_perform :find_authorization
  before_perform :parse_email!
  # before_perform :already_auth?, if: :current_user?
  before_perform :email_uniqueness?, if: :current_user?
  before_perform :find_or_create_user, unless: :current_user?
  before_perform :bind_authorization_to_user
  after_perform :update_user_omniauth_data
  after_perform :update_github_full_access_token
  after_perform :user_confirm!
  after_perform :update_github_data!
  after_perform :new_user_comming

  # params should be env["omniauth.auth"] in controller
  def initialize(params, current_user = nil)
    @params = ActionController::Parameters.new(params)
    @provider = @params[:provider]
    @user = current_user
    @authorization = nil
    @new_user_comming = false
  end

  def perform
    run_callbacks :perform do
      if @authorization
        responds
      else
        false
      end
    end
  end

  private

  def responds
    { user: @user,
      authorization: @authorization
    }
  end

  def find_authorization
    @authorization = Authorization.find_by(provider: Authorization.providers[@provider], uid: @params[:uid])
  end

  def parse_email!
    @email = params_to_user_attributes[:email]
    add_error(:omniauth_parse_email_fail) unless @email
  end

  def already_auth?
    return add_error(:omniauth_already_auth) if @authorization
  end

  def email_uniqueness?
    scope = User.where(email: @email)
    scope = scope.where("id != ?", @user.id)
    return add_error(:omniauth_email_registered) unless scope.count == 0
  end

  def find_or_create_user
    @user = @authorization.try(:auth) || User.find_by(email: @email) || initialize_user
    if @user.new_record?
      @user.save!
      @new_user_comming = true
    end
  end

  def bind_authorization_to_user
    @authorization = @user.authorizations.create!(uid: @params[:uid], provider: @provider, auth_data: @params) unless @authorization
  end

  def update_user_omniauth_data
    @authorization.update_attribute :auth_data, @params
  end

  def user_confirm!
    @user.confirm if @user.confirmable? && !@user.confirmed?
  end

  def current_user?
    @user.present?
  end

  def initialize_user
    user = User.new(params_to_user_attributes)
    def user.password_required?
      false
    end
    user
  end

  def params_to_user_attributes
    case @provider.to_sym
    when :facebook      then { email: @params[:info][:email], name: @params[:info][:name] }
    when :google_oauth2 then { email: @params[:info][:email], name: @params[:info][:name] }
    when :github        then { email: @params[:info][:email], name: @params[:info][:name] }
    end
  end

  def provider_name
    @provider.to_s.titleize
  end

  def update_github_data!
    if @provider.to_sym == :github
      @user.update_attributes(name: @authorization.auth_data["info"]["name"],
                              github_id: @authorization.uid,
                              github_account: @authorization.auth_data["info"]["nickname"],
                              github_avatar: @authorization.auth_data["info"]["image"],
                              github_token: @authorization.auth_data["credentials"]["token"])
    end
  end

  def update_github_full_access_token
    @user.full_access_token = @authorization.auth_data["credentials"]["token"] if @provider.to_sym == :github
  end

  def new_user_comming
    return unless @new_user_comming
    SlackService.delay(retry: false).notify_admin("新使用者註冊! (##{@user.id})#{@user.name}<#{@user.email}>")
  end
end
