require 'date'
require 'yaml'
require 'fileutils'

module Codelog
  module Command
    module Step
      class Version
        include FileUtils

        RELEASES_PATH = "changelogs/releases"
        UNRELEASED_LOGS_PATH = "changelogs/unreleased"

        def initialize(version, release_date=Date.today.to_s)
          @version = version
          @release_date = Date.parse(release_date).to_s
        end

        def self.run(version, release_date=Date.today.to_s)
          Codelog::Command::Step::Version.new(version, release_date).run
        end

        def run
          abort('ERROR: Please enter a version number') if @version.nil?
          abort('ERROR: Version already exists') if version_exists?
          chdir Dir.pwd do
            create_version_changelog_from changes_hash
          end
        end

        private

        def changes_hash
          abort('ERROR: No changes to be added') unless has_unreleased_changes?
          change_files_paths = Dir["#{UNRELEASED_LOGS_PATH}/*.yml"]
          change_files_paths.inject({}) do |all_changes, change_file|
            changes_per_category = YAML.load_file(change_file)
            all_changes.merge!(changes_per_category) do |category, changes, changes_to_be_added|
              changes | changes_to_be_added
            end
          end
        end

        def create_version_changelog_from(changes_hash)
          File.open("#{RELEASES_PATH}/#{@version}.md", 'a') do |line|
            line.puts "## #{@version} - #{@release_date}"
            changes_hash.each do |category, changes|
              line.puts "### #{category}"
              changes.each { |change| line.puts "- #{change}" }
              line.puts "\n"
            end
            line.puts "---\n"
          end
        end

        def version_exists?
          File.file?("#{RELEASES_PATH}/#{@version}.md")
        end

        def has_unreleased_changes?
          Dir["#{UNRELEASED_LOGS_PATH}/*.yml"].any?
        end
      end
    end
  end
end
