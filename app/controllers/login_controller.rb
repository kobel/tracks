class LoginController < ApplicationController
  
  layout 'login'
  filter_parameter_logging :user_password 
  skip_before_filter :set_session_expiration
  skip_before_filter :login_required
  before_filter :login_optional
  before_filter :get_current_user
  if ( SITE_CONFIG['authentication_schemes'].include? 'cas')
    # This will allow the user to view the index page without authentication
    # but will process CAS authentication data if the user already
    # has an SSO session open.
    if defined? CASClient
      # Only require sub-library if gem is installed and loaded
      require 'casclient/frameworks/rails/filter'
      before_filter CASClient::Frameworks::Rails::GatewayFilter, :only => :login_cas

      # This requires the user to be authenticated for viewing all other pages.
      before_filter CASClient::Frameworks::Rails::Filter, :only => [:login_cas ]
    end
  end

  def login
    if cas_enabled?
      @username = session[:cas_user]
      @login_url = CASClient::Frameworks::Rails::Filter.login_url(self)
    end
    if openid_enabled? && using_open_id?
      login_openid
    elsif cas_enabled? && session[:cas_user]
      login_cas
    else
      @page_title = "TRACKS::Login"
      cookies[:preferred_auth] = prefered_auth? unless cookies[:preferred_auth]
      case request.method
        when :post
          if @user = User.authenticate(params['user_login'], params['user_password'])
            session['user_id'] = @user.id
            # If checkbox on login page checked, we don't expire the session after 1 hour
            # of inactivity and we remember this user for future browser sessions
            session['noexpiry'] = params['user_noexpiry']
            msg = (should_expire_sessions?) ? "will expire after 1 hour of inactivity." : "will not expire." 
            notify :notice, "Login successful: session #{msg}"
            cookies[:tracks_login] = { :value => @user.login, :expires => Time.now + 1.year, :secure => SITE_CONFIG['secure_cookies'] }
            unless should_expire_sessions?
              @user.remember_me
              cookies[:auth_token] = { :value => @user.remember_token , :expires => @user.remember_token_expires_at, :secure => SITE_CONFIG['secure_cookies'] }
            end
            redirect_back_or_home
            return
          else
            @login = params['user_login']
            notify :warning, "Login unsuccessful"
          end
        when :get
          if User.no_users_yet?
            redirect_to :controller => 'users', :action => 'new'
            return
          end
      end
      respond_to do |format|
        format.html
        format.m   { render :action => 'login_mobile.html.erb', :layout => 'mobile' }
      end
    end
  end
  
  def logout
    @user.forget_me if logged_in?
    cookies.delete :auth_token
    session['user_id'] = nil
    if ( SITE_CONFIG['authentication_schemes'].include? 'cas')  && session[:cas_user]
      CASClient::Frameworks::Rails::Filter.logout(self)
    else
      reset_session
      notify :notice, "You have been logged out of Tracks."
      redirect_to_login
    end
  end
  
  def check_expiry
    # Gets called by periodically_call_remote to check whether 
    # the session has timed out yet
    unless session == nil
      if session
        return unless should_expire_sessions?
        # Get expiry time (allow ten seconds window for the case where we have none)
        expiry_time = session['expiry_time'] || Time.now + 10
        @time_left = expiry_time - Time.now
        if @time_left < (10*60) # Session will time out before the next check
          @msg = "Session has timed out. Please "
        else
          @msg = ""
        end
      end
    end
    respond_to do |format|
      format.js
    end
  end

    def login_cas
    # If checkbox on login page checked, we don't expire the session after 1 hour
    # of inactivity and we remember this user for future browser sessions

    session['noexpiry'] ||= params['user_noexpiry']
    if session[:cas_user]
      if @user = User.find_by_login(session[:cas_user])
        session['user_id'] = @user.id
        msg = (should_expire_sessions?) ? "will expire after 1 hour of inactivity." : "will not expire."
        notify :notice, "Login successful: session #{msg}"
        cookies[:tracks_login] = { :value => @user.login, :expires => Time.now + 1.year, :secure => SITE_CONFIG['secure_cookies'] }
        unless should_expire_sessions?
          @user.remember_me
          cookies[:auth_token] = { :value => @user.remember_token, :expires => @user.remember_token_expires_at, :secure => SITE_CONFIG['secure_cookies'] }
        end
        #redirect_back_or_home
      else
        notify :warning, "Sorry, no user by that CAS username exists (#{session[:cas_user]})"
        redirect_to signup_url ; return
      end
    else
      notify :warning, result.message
    end
    redirect_back_or_home 

  end
  
  private
      
  def redirect_to_login
    respond_to do |format|
      format.html { redirect_to login_path }
      format.m { redirect_to login_path(:format => 'm') }
    end
  end
  
  def should_expire_sessions?
    session['noexpiry'] != "on"
  end
  
  protected
  
  def login_openid
    # If checkbox on login page checked, we don't expire the session after 1 hour
    # of inactivity and we remember this user for future browser sessions
    session['noexpiry'] ||= params['user_noexpiry']
    authenticate_with_open_id do |result, identity_url|
      if result.successful?
        if @user = User.find_by_open_id_url(identity_url)
          session['user_id'] = @user.id
          msg = (should_expire_sessions?) ? "will expire after 1 hour of inactivity." : "will not expire." 
          notify :notice, "Login successful: session #{msg}"
          cookies[:tracks_login] = { :value => @user.login, :expires => Time.now + 1.year, :secure => SITE_CONFIG['secure_cookies'] }
          unless should_expire_sessions?
            @user.remember_me
            cookies[:auth_token] = { :value => @user.remember_token , :expires => @user.remember_token_expires_at, :secure => SITE_CONFIG['secure_cookies'] }
          end
          redirect_back_or_home
        else
          notify :warning, "Sorry, no user by that identity URL exists (#{identity_url})"
        end
      else
        notify :warning, result.message
      end
    end
  end


end
