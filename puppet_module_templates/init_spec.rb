# This file has been auto-generated by update_rspec.rb.
# Please edit its contents to add your own tests.
# The update_rspec.rb utility will not touch it after that.

require 'spec_helper'

describe '##SHORT_NAME##' do
  it {
    File.write(
      'catalogs/##SHORT_NAME##.json',
      PSON.pretty_generate(catalogue)
    )
  }
end
