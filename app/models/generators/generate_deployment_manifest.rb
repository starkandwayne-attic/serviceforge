class Generators::GenerateDeploymentManifest
  include ActiveModel::Model

  attr_accessor :deployment_stub, :service_plan_stub

  def generate_manifest
    
  end

  def spiff_merge(input_file_paths, output_path)
    spiff_cmd = spiff_cmd([input_file_paths])
    complete_cmd = "#{spiff_cmd} > #{Escape.shell_command([output_path])}"
    %x[#{complete_cmd}]
  end

  def spiff_cmd(args)
    Escape.shell_command(["spiff", *(args.flatten)])
  end
end