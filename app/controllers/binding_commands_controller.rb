class BindingCommandsController < ApplicationController
  def show
    perform("GET")
  end

  def update
    perform("PUT")
  end

  protected
  def perform(allowed_http_method)
    auth_token = params.fetch(:binding_auth_token)
    if @binding_command = RegisteredBindingCommand.find_by_auth_token(auth_token)
      if @binding_command.http_method == allowed_http_method
        @binding_command.perform
        result = @binding_command.binding_command_action
        render json: result.to_json, status: 200
      else
        render nothing: true, status: 405
      end
    else
      render nothing: true, status: :unauthorized
    end
  end
end
