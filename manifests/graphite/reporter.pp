class cassandra::graphite::reporter(
  $ensure   = 'present',
  $source   = 'http://repo1.maven.org/maven2/io/dropwizard/metrics/metrics-graphite/3.1.0/metrics-graphite-3.1.0.jar',
  $settings = {},
) {
  include ::cassandra::params

  $jar_name = basename( $source )

  wget::fetch { $source:
    destination => "/usr/share/cassandra/lib/${jar_name}",
    timeout     => 0,
    verbose     => false,
    require     => Package['cassandra'],
    notify      => Service['cassandra'],
  } ->

  file { "${::cassandra::params::config_path}/graphite.yaml":
    ensure  => $ensure,
    content => to_yaml( { 'graphite' => [$settings] } ),
    group   => 'cassandra',
    owner   => 'cassandra',
    mode    => '0644',
    require => [
      Package['cassandra'],
      File[$::cassandra::params::config_path],
    ],
    notify => Service['cassandra'],
  } ->

  file_line { 'cassandra-graphite-reporter-env':
    ensure  => $ensure,
    line    => 'export JVM_EXTRA_OPTS="-Dcassandra.metricsReporterConfigFile=graphite.yaml"',
    match   => 'cassandra\.metricsReporterConfigFile',
    path    => '/etc/default/cassandra',
    require => Package['cassandra'],
    notify  => Service['cassandra'],
  }
}
