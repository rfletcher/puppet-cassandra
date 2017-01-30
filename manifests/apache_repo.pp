# An optional class that will allow a suitable repository to be configured
# from which packages for DataStax Community can be downloaded.  Changing
# the defaults will allow any Debian Apt or Red Hat Yum repository to be
# configured.
# @param descr [string] Passed as the `comment` attribute to an `apt::source`
#   resource.
# @param key_id [string] OPassed as the `id` attribute to an `apt::key`
#   resource.
# @param key_url [string] Passed as the `source` attribute to an `apt::key`
#   resource.
# @param pkg_url [string] If left as the default, this will set the `baseurl`
#   to 'http://www.apache.org/dist/cassandra/debian'.
# @param release [string] Passed as the `release` attribute to an `apt::source`
#   resource.
class cassandra::apache_repo (
  $descr   = 'Apache Cassandra',
  $key_id  = 'A26E528B271F19B9E5D8E19EA278B781FE4B2BDA',
  $key_url = 'http://www.apache.org/dist/cassandra/KEYS',
  $pkg_url = undef,
  $release = '30x',
  ) {

  include apt
  include apt::update

  apt::key { 'cassandra':
    id     => $key_id,
    source => $key_url,
    before => Apt::Source['cassandra'],
  }

  if $pkg_url != undef {
    $location = $pkg_url
  } else {
    $location = 'http://www.apache.org/dist/cassandra/debian'
  }

  apt::source { 'cassandra':
    location => $location,
    comment  => $descr,
    release  => $release,
    include  => {
      'src' => false,
    },
    notify   => Exec['update-cassandra-repos'],
  }

  # Required to wrap apt_update
  exec { 'update-cassandra-repos':
    refreshonly => true,
    command     => '/bin/true',
    require     => Exec['apt_update'],
  }
}
