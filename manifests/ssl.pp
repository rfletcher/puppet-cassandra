class cassandra::ssl(
  $ensure = present,
  $bits   = 2048,
  $dir    = '/var/lib/cassandra/ssl',
  $node_name,
  $password,
  $root_key,
  $root_cert,
) {
  include ::cassandra::params

  File {
    group   => 'cassandra',
    mode    => '0440',
    owner   => 'cassandra',
    require => User['cassandra'],
  }

  # configure static SSL config

  file { $dir:
    ensure  => $ensure ? { absent => $ensure, default => directory, },
    force   => true,
    mode    => '0550',
    recurse => true,
  }

  file { "${dir}/rootCa.key":
    ensure  => $ensure,
    content => $root_key,
    require => File[$dir],
    notify  => Exec['update-cassandra-ssl'],
  }

  file { "${dir}/rootCa.crt":
    ensure  => $ensure,
    content => $root_cert,
    require => File[$dir],
    notify  => Exec['update-cassandra-ssl'],
  }

  # configure dynamic SSL config generation

  $cassandra_ca_path = "${::cassandra::params::config_path}/cassandra-ca.yaml"

  # see `pydoc cassandra-ca`
  $cassandra_ca_config = {
    cert => {
      subject => {
        country      => "US",
        organization => "None",
        unit         => "None",
      },
      valid => 36500,
    },
    key      => { size => $bits },
    password => $password,
  }

  file { $cassandra_ca_path:
    ensure  => $ensure,
    content => to_yaml( {
      authority      => $cassandra_ca_config,
      base_directory => $dir,
      keystores      => [merge( $cassandra_ca_config, { name => $node_name } )],
    } ),
    notify  => Exec['update-cassandra-ssl'],
    require => Package['cassandra'],
  }

  file { '/usr/local/bin/cassandra-ca':
    source => 'puppet:///modules/cassandra/cassandra-ca.py',
    group  => 'root',
    mode   => '0555',
    owner  => 'root',
  }

  exec { 'update-cassandra-ssl':
    command     => "cassandra-ca ${cassandra_ca_path}",
    refreshonly => true,
    require     => File['/usr/local/bin/cassandra-ca'],
    notify      => Service['cassandra'],
  }
}
