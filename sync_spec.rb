#!/usr/bin/env ruby

require 'yaml'
require 'fileutils'

class SyncSpec
  def initialize

    @origin  = %x{git remote get-url origin}.chomp

    # We expect to find sync_spec.yml in the directory with this script.
    @config = YAML::load_file(File.join(File.dirname(__FILE__), 'sync_spec.yml'))

    if !@config.has_key?(@origin)
      puts "ERROR: #{@origin} not found in sync_spec.yml"
      exit 1
    elsif !@config[@origin].include?('repo_type')
      puts "ERROR: repo_type not found for @origin (which has only #{@config[@origin]})"
      exit 1
    else
      @repo_type = @config[@origin]['repo_type']
    end

    @templates = "#{@repo_type}_templates"
    @skel      = "#{@repo_type}_skel"

    @short_name = @origin.gsub(/^.*-/, '').gsub(/\.git/, '')
  end

  def sync
    case @repo_type
    when 'puppet_module'
      sync_spec_puppet_module
    when 'rspec_only'
      sync_rspec_only
    end
  end

 private

  # Install Rspec set up files and templates for an ordinary Puppet module.

  def sync_spec_puppet_module
    copy_skel_files
    install_fixtures
    install_spec_helper

    # ONLY install init_spec.rb if no spec files already exist in spec/classes.
    # These files are otherwise not managed from here.
    unless @config[@origin].has_key?('no_init_spec')
      if (Dir.entries('spec/classes') - %w{. .. .gitkeep readme_spec.rb}).empty?
        install_template(
          ["#{@templates}/init_spec.rb"], 'spec/classes/init_spec.rb')
      end
    end
  end

  # Install Rspec for data-only tests.

  def sync_rspec_only
    copy_skel_files
  end

  # Install a .fixtures.yml file for a Puppet module, with repositories to checkout interpolated.

  def install_fixtures
    fixtures = String.new
    if @config[@origin].has_key?('fixtures')
      fixtures = @config[@origin]['fixtures'].to_yaml.chop.gsub("---\n", '').gsub("\n", "\n  ")
    end

    subs = {
      '##FIXTURES##'   => fixtures,
      '##SHORT_NAME##' => @short_name,
    }

    install_template(
      ["#{@templates}/.fixtures.yml"], '.fixtures.yml', subs)
  end

  # Install a spec_helper.rb file for a Puppet module, with hiera config and stubbed facts
  # interpolated.

  def install_spec_helper
    stubbed_facts = String.new
    if @config[@origin].has_key?('stubbed_facts')
      @config[@origin]['stubbed_facts'].keys.each do |k|
        stubbed_facts += "    :#{k} => '#{@config[@origin]['stubbed_facts'][k]}',\n"
      end
    end

    subs = {
      '##STUBBED_FACTS##'  => stubbed_facts,
    }

    install_template(["#{@templates}/spec_helper.rb"], 'spec/spec_helper.rb', subs)
  end

  # Copy all files and directories from the skel directory into the repo.

  # Params:
  # +exclude+: A list of files to exclude, relative to the top level of
  #            the repo. Defaults to an empty list.

  def copy_skel_files(exclude = [])
    full_path = File.join(File.dirname(__FILE__), @skel)
    excluded = exclude.map {|x| "#{full_path}/#{x}" }
    Dir.glob("#{full_path}/**/*").select {|x| File.directory?(x)}.each do |f|
      relative_path = f.gsub(/#{full_path}\//, '')
      FileUtils.mkdir_p relative_path
    end
    (
      Dir.glob("#{full_path}/**/*") + Dir.glob("#{full_path}/**/.*") - excluded
    )
    .select {|x| File.file?(x)}.each do |f|
      next if f =~ /\.gitkeep/
      relative_path = f.gsub(/#{full_path}\//, '')
      FileUtils.cp f, relative_path
    end
  end

  # Build and install a template. We support concatenation of multiple
  # file parts, and simple interpolation of key/value pairs. By convention,
  # the placeholder string is expected to be of the form ##FOO##.

  # Params:
  # +file_parts+: An array of file parts used to build the resultant file.
  # +dest+: The path to where the file will be installed.
  # +subs+: A Hash of key/value pairs. All instances of the string on the
  #         left-hand side are replaced by values on the right-hand side.

  def install_template(file_parts, dest, subs = {})
    content = String.new
    file_parts.each do |file_part|
      full_path = File.join(File.dirname(__FILE__), file_part)
      begin
        content += File.open(full_path).read
      rescue
      end
    end
    subs.keys.each do |k|
      content.gsub!(/#{k}/, subs[k])
    end
    File.open(dest, 'w') {|file| file.write(content)}
  end
end

SyncSpec.new.sync
