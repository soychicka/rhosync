class UsersController < ApplicationController

  # render new.rhtml
  def new
    @user = User.new
  end

  # Example xml request body:
  # <user>
  #   <login>user</login>
  #   <email>user@host.com</email>
  #   <password>password</password>
  #   <password_confirmation>password</password_confirmation>
  # </user>
  def create
    logout_keeping_session!
    @user = User.new(params[:user])
    begin
      success = @user && @user.save!
    rescue Exception
      logger.error "Error: #{$!}"
    end
    respond_to do |wants|
      wants.html do
        if success && @user.errors.empty?
          # Protects against session fixation attacks, causes request forgery
          # protection if visitor resubmits an earlier form using back
          # button. Uncomment if you understand the tradeoffs.
          # reset session
          self.current_user = @user # !! now logged in
          redirect_back_or_default('/')
          flash[:notice] = "Thanks for signing up!"
        else
          flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
          render :action => 'new'
        end
      end
      wants.xml do
        if success && @user.errors.empty?
          render :xml => @user
        else
          render :xml => @user.errors, :status => :unprocessable_entity
        end
      end
    end
  end

end
