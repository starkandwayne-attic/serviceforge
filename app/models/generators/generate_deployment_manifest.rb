require 'tempfile'

# Use spiff to apply templates to create a deployment manifest
class Generators::GenerateDeploymentManifest
  include ActiveModel::Model

  # File paths to YAML files
  attr_accessor :service_stub_paths

  # YAML strings
  attr_accessor :infrastructure_stub, :service_plan_stub, :deployment_stub

  def generate_manifest
    infrastructure_stub_file  = tempfile('infrastructure_stub', infrastructure_stub) unless infrastructure_stub.blank?
    service_plan_stub_file    = tempfile('service_plan_stub', service_plan_stub) unless service_plan_stub.blank?
    deployment_stub_file      = tempfile('deployment_stub', deployment_stub) unless deployment_stub.blank?
    output_file               = tempfile('output')

    input_file_paths = service_stub_paths + [
      infrastructure_stub_file.try(:path),
      service_plan_stub_file.try(:path),
      deployment_stub_file.try(:path)
    ].compact
    spiff_merge(input_file_paths, output_file.path)
    output_file.rewind
    output_file.read
  ensure
    service_plan_stub_file.try(:close)
    deployment_stub_file.try(:close)
    output_file.try(:close)
  end

  def spiff_merge(input_file_paths, output_path)
    spiff_cmd = spiff_cmd([input_file_paths])
    complete_cmd = "#{spiff_cmd} > #{Escape.shell_command([output_path])}"
    %x[#{complete_cmd}]
  end

  def spiff_cmd(args)
    Escape.shell_command(["spiff", "merge", *(args.flatten)])
  end

  # Store contents in a tempfile and return File object
  # Need to invoke #close when finished
  def tempfile(name, contents=nil)
    file = Tempfile.new(name)
    # puts "-------"
    # puts name
    # puts contents
    # puts "-------\n\n\n"
    file.write(contents) unless contents.blank?
    file.rewind
    file
  end
end
