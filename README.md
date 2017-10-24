# sync_spec.rb

Release 1.0.0.

## Overview

This project provides centralised management of the Rspec setup files for my Puppet modules.

## Usage

It is recommended to add this project to your $PATH, e.g. in `~/.bash_profile`:

~~~
export PATH=$PATH:/Users/alexharvey/git/sync_spec
~~~

To update the Rspec files in a project:

~~~
$ cd myproject
$ sync_spec.rb 
~~~

## Configuration

This project has a configuration file `sync_spec.yml`. For example:

~~~ yaml
'https://github.com/alexharv074/puppet-firewall_multi.git':
  repo_type: puppet_module
  fixtures:
    forge_modules:
      firewall: puppetlabs/firewall
  stubbed_facts:
    osfamily: RedHat
    operatingsystemrelease: 6.8
    operatingsystemmajrelease: 6
~~~

### Repo types

At the moment, the following repo types are managed by this project:

#### `puppet_module`

Declaring a repo of type `puppet_module` causes setup files for a Puppet module to be installed.

The following additional options can be specified:

##### `fixtures`

The list of fixtures (i.e. dependent Puppet modules) for interpolation in the `.fixtures.yml` file's `repositories` section is specified here.  If blank, this section is omitted in the generated file.

For example in the following declaration:

~~~ yaml
'https://github.com/alexharv074/puppet-firewall_multi.git':
  repo_type: puppet_module
  fixtures:
    forge_modules:
      firewall: puppetlabs/firewall
~~~

A `.fixtures.yml` file like this is generated:

~~~ yaml
fixtures:
  repositories:
    forge_modules:
      firewall: puppetlabs/firewall
  symlinks:
    firewall_multi: "#{source_dir}"
~~~

##### `stubbed_facts`

This list of stubbed facts and their values. For example given the following declaration:

~~~ yaml
  stubbed_facts:
    osfamily: RedHat
    operatingsystemrelease: 6.8
    operatingsystemmajrelease: 6
~~~

A `spec_helper.rb` file is generated with the following content included:

~~~ ruby
RSpec.configure do |c|
  c.default_facts = {
    :osfamily => 'RedHat',
    :operatingsystemrelease => '6.8',
    :operatingsystemmajrelease => '6',
  }
end
~~~
