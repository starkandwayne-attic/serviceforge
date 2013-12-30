class BindingCommandsController < ApplicationController
  before_filter :load_binding_command_from_auth_token

  attr_reader :binding_command

  def update
    auth_token = params.fetch(:binding_auth_token)
    if @binding_command = BindingCommand.find_by_auth_token(auth_token)
      binding_command.perform
      result = binding_command.binding_command
      render json: result.to_json, status: 200
    else
      render nothing: true, status: :unauthorized
    end
  end

  protected
  def load_binding_command_from_auth_token
    true
  end
end
