#!/usr/bin/env ruby

require "chef-utils"
require "mixlib/shellout/helper"
include Mixlib::ShellOut::Helper

install_dir = ARGV.shift

class Fake
  def trace?; false end
end

def __config; {} end
def __log; Fake.new end

# Install gems from git repos.  This makes the assumption that there is a <gemname>.gemspec and
# you can simply gem build + gem install the resulting gem, so nothing fancy.  This does not use
# rake install since we need --conservative --minimal-deps in order to not install duplicate gems.
#
Dir["#{install_dir.tr('\\', "/")}/embedded/lib/ruby/gems/*/bundler/gems/*"].each do |gempath|
  matches = File.basename(gempath).match(/(.*)-[A-Fa-f0-9]{12}/)
  next unless matches

  gemname = matches[1]
  next unless gemname

  # we can't use "commmand" or "bundle" or "gem" DSL methods here since those are lazy and we need to run commands immediately
  # (this is like a shell_out inside of a ruby_block in core chef, you don't use an execute resource inside of a ruby_block or
  # things get really weird and unexpected)
  shell_out! "gem build #{gemname}.gemspec", cwd: gempath
  shell_out! "gem install #{gemname}*.gem --conservative --minimal-deps --no-document", cwd: gempath
end
