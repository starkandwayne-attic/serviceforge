class BindingCommandsController < ApplicationController
  before_filter :load_binding_command_from_auth_token

  attr_reader :binding_command

  def update
    binding_command.perform
    render :nothing => true
  end

  protected
  def load_binding_command_from_auth_token
    auth_token = params.fetch(:binding_auth_token)
    unless @binding_command = BindingCommand.find_by_auth_token(auth_token)
      render nothing: true, status: :unauthorized
    end
  end
end
