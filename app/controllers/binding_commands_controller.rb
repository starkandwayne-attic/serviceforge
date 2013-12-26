class BindingCommandsController < ApplicationController
  before_filter :load_binding_command_from_auth_token

  def update
    render :nothing => true
  end

  protected
  def load_binding_command_from_auth_token
    auth_token = params.fetch(:binding_auth_token)
    if BindingCommand.find_by_auth_token(auth_token)
    else
      render nothing: true, status: :unauthorized
    end
  end
end
