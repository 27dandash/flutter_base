#!/usr/bin/env ruby
# frozen_string_literal: true

require 'xcodeproj'

abort('usage: configure_optional_ios_flavors.rb IOS_PATH BASE_ID INTEGRATION') unless ARGV.length == 3

ios_path, base_id, integration = ARGV
abort('integration must be maps or firebase') unless %w[maps firebase].include?(integration)

project_path = File.join(ios_path, 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)
runner = project.targets.find { |target| target.name == 'Runner' }
tests = project.targets.find { |target| target.name == 'RunnerTests' }
abort('Runner and RunnerTests targets are required') unless runner && tests

flavors = {
  'development' => {
    id: "#{base_id}.dev",
    display: integration == 'maps' ? 'Maps Example Dev' : 'Remote Config Example Dev',
  },
  'staging' => {
    id: "#{base_id}.staging",
    display: integration == 'maps' ? 'Maps Example Staging' : 'Remote Config Example Staging',
  },
  'production' => {
    id: base_id,
    display: integration == 'maps' ? 'Maps Example' : 'Remote Config Example',
  },
}
modes = %w[Debug Profile Release]
flutter_group = project.main_group.find_subpath('Flutter', true)

def clone_configuration(project, list, source_name, destination_name)
  existing = list.build_configurations.find { |config| config.name == destination_name }
  return existing if existing

  source = list.build_configurations.find { |config| config.name == source_name }
  abort("missing source configuration #{source_name}") unless source

  destination = project.new(Xcodeproj::Project::Object::XCBuildConfiguration)
  destination.name = destination_name
  destination.build_settings = source.build_settings.dup
  destination.base_configuration_reference = source.base_configuration_reference
  list.build_configurations << destination
  destination
end

flavors.each do |flavor, values|
  modes.each do |mode|
    name = "#{mode}-#{flavor}"
    clone_configuration(project, project.build_configuration_list, mode, name)

    runner_config = clone_configuration(
      project,
      runner.build_configuration_list,
      mode,
      name,
    )
    runner_config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = values[:id]
    runner_config.build_settings['APP_DISPLAY_NAME'] = values[:display]
    runner_config.build_settings.delete('DEVELOPMENT_TEAM')
    config_name = "#{mode}-#{flavor}.xcconfig"
    config_ref = flutter_group.files.find do |file|
      [config_name, "Flutter/#{config_name}"].include?(file.path)
    end || flutter_group.new_file("Flutter/#{config_name}")
    # The stock Flutter Xcode group is intentionally virtual (it has no path).
    # Keep the physical Flutter/ prefix on custom references, matching the
    # generated Debug.xcconfig and Release.xcconfig references.
    config_ref.name = config_name
    config_ref.path = "Flutter/#{config_name}"
    runner_config.base_configuration_reference = config_ref

    test_config = clone_configuration(
      project,
      tests.build_configuration_list,
      mode,
      name,
    )
    test_config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] =
      "#{values[:id]}.RunnerTests"
    test_config.build_settings.delete('DEVELOPMENT_TEAM')
  end

  scheme = Xcodeproj::XCScheme.new
  scheme.configure_with_targets(runner, tests)
  scheme.launch_action.build_configuration = "Debug-#{flavor}"
  scheme.test_action.build_configuration = "Debug-#{flavor}"
  scheme.profile_action.build_configuration = "Profile-#{flavor}"
  scheme.analyze_action.build_configuration = "Debug-#{flavor}"
  scheme.archive_action.build_configuration = "Release-#{flavor}"
  scheme.save_as(project_path, flavor, true)
end

if integration == 'firebase'
  phase_name = 'Select flavor Firebase configuration'
  phase = runner.shell_script_build_phases.find { |item| item.name == phase_name }
  phase ||= runner.new_shell_script_build_phase(phase_name)
  phase.shell_path = '/bin/sh'
  phase.shell_script = '"${SRCROOT}/scripts/copy_firebase_config.sh"'
  phase.input_paths = []
  phase.output_paths = [
    '$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist',
  ]
end

project.save
puts "Configured #{integration} iOS development, staging, and production schemes."
