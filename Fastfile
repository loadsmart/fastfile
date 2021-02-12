# This is the minimum version number required.
# Update this, if you use features of a newer version
fastlane_version "2.112.0"

default_platform :ios

platform :ios do

  before_all do
    setup_circle_ci if is_ci
  end

  desc "Increment version's major number"
  lane :major do |options|
    increment_version_number(bump_type: "major")
    commit_version if options[:commit]
  end

  desc "Increment version's minor number"
  lane :minor do |options|
    increment_version_number(bump_type: "minor")
    commit_version if options[:commit]
  end

  desc "Increment version's patch number"
  lane :patch do |options|
    increment_version_number(bump_type: "patch")
    commit_version if options[:commit]
  end

  desc "Read version from package.json and set it into plist"
  lane :stamp_js_version do |options|
    require 'json'

    packageJSON = File.read('../../package.json')
    data = JSON.parse(packageJSON)

    increment_version_number(version_number: data['version'])
    commit_version if options[:commit]
  end

  desc "Increment build number"
  lane :bump do |options|
    increment_build_number
    commit_version if options[:commit]
  end

  desc "Create a commit for an app version"
  private_lane :commit_version do
    version = get_version_number
    sh "git commit -am 'app: bump version to #{version} (#{get_build_number}) [skip ci]' --no-verify"
  end

  desc "Run main target test"
  lane :test do
    scan
  end

  desc "Add new device for debugging"
  lane :device do
    device_name = prompt(text: "Device name: ")
    device_UDID = prompt(text: "Device UDID: ")
    register_devices(devices: {device_name => device_UDID})
    match(type: "development", force_for_new_devices: true)
  end

  desc "Submit a new Beta version to Firebase App Distribution"
  lane :firebase_beta do |options|
    app_identifier = options[:app_identifier]
    raise "Missing parameter app_identifier" unless app_identifier
    
    configuration = options[:configuration]
    raise "Missing parameter configuration" unless configuration
    
    firebase_group = options[:firebase_group]
    raise "Missing parameter firebase_group" unless firebase_group
    
    scheme = options[:scheme]
    raise "Missing parameter scheme" unless scheme
    
    firebase_app = ENV["FIREBASE_IOS_APP"]
    raise "Env var 'FIREBASE_IOS_APP' not set" unless firebase_app

    sync_code_signing(type: "adhoc", app_identifier: [app_identifier])
    bump
    build_app(scheme: scheme, configuration: configuration, export_method: "ad-hoc")
    firebase_app_distribution(app: firebase_app, groups: firebase_group)
    commit_version if options[:commit]
    push_to_git_remote if options[:push]
  end

  desc "Submit a new Beta version to Testflight"
  lane :testflight do
    setup_circle_ci if is_ci
    sync_code_signing(type: "appstore")
    bump
    build_app
    upload_to_testflight(username: "mobile@loadsmart.com", changelog: changelog, skip_waiting_for_build_processing: is_ci)
    commit_version
    push_to_git_remote
    notify_on_slack(changelog: changelog)
  end

  desc "Deploy a new version to the App Store"
  lane :appstore do
    setup_circle_ci if is_ci
    sync_code_signing(type: "appstore")
    increment_build_number
    build_app
    deliver(force: true)
    commit_version
    push_to_git_remote
    notify_on_slack(changelog: changelog)
  end

  desc "Notify release on Slack"
  private_lane :notify_on_slack do |options|
    changelog = options[:changelog]
    attachment_properties = {
      fields: [{
        title: 'Version',
        value: "#{get_version_number} (#{get_build_number})",
        short: true
      }, {
        title: 'App',
        value: "#{get_project_name} ios :iphone:",
        short: true
      }]
    }

    if !changelog.empty?
      attachment_properties[:fields].push({
        title: 'Change Log',
        value: "```#{changelog}```",
        short: false
      })
    end

    slack(
      message: "Hey team, we have a new beta version available for you.",
      username: "Beta Releaser",
      icon_url: "https://user-images.githubusercontent.com/235208/50868371-3571c900-137d-11e9-96ac-9d23d3df9690.png",
      attachment_properties: attachment_properties,
      default_payloads: []
    )
  end

  desc "Read Changelog"
  private_lane :changelog do
    read_changelog(
      changelog_path: '../CHANGELOG.md',
      section_identifier: '[Unreleased]',
      excluded_markdown_elements: ['-', '###']
    ).strip
  end

  desc "Find project name"
  private_lane :get_project_name do
    sh("find .. -name '*.xcodeproj' -maxdepth 1 | sed -E 's/\\.\\.\\/(.+)\\.xcodeproj/\\1/g'").strip
  end

end
