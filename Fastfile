# This is the minimum version number required.
# Update this, if you use features of a newer version
fastlane_version "2.112.0"

default_platform :ios

platform :ios do

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

  desc "Submit a new Beta version to Crashlytics Beta"
  lane :crashlytics_beta do
    fabric_token = ENV["FABRIC_API_TOKEN"]
    raise "Env var 'FABRIC_API_TOKEN' not set" unless fabric_token

    fabric_secret = ENV["FABRIC_BUILD_SECRET"]
    raise "Env var 'FABRIC_BUILD_SECRET' not set" unless fabric_secret

    setup_circle_ci if is_ci
    sync_code_signing(type: "ad-hoc")
    bump
    build_app
    crashlytics(
      api_token: fabric_token,
      build_secret: fabric_secret,
      groups: ['qa-ios'],
      notes: changelog
    )
    commit_version
    push_to_git_remote
    notify_on_slack(changelog: changelog)
  end

  desc "Submit a new Beta version to Testflight"
  lane :testflight do
    setup_circle_ci if is_ci
    sync_code_signing(type: "appstore")
    bump
    build_app
    upload_to_testflight(changelog: changelog, skip_waiting_for_build_processing: is_ci)
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
        value: 'ios :iphone:', #TODO get app name somehow
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

end
