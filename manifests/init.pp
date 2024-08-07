# @summary # This class is able to install or remove graphdb distribution on a node. It manages the status of the related service.
#
#
# @param archive_dl_timeout
#   For http downloads you can set how long the exec resource may take.
#   default: 600 seconds
#
# @param data_dir
#   String. GraphDB data directory
#
# @param edition
#   String. GraphDB edition to install
#
# @param ensure
#   String. Controls if the managed resources shall be <tt>present</tt> or
#   <tt>absent</tt>. If set to <tt>absent</tt>:
#   * The managed distribution is being uninstalled.
#   * Any traces of installation will be purged as good as possible. This may
#     include existing configuration files. The exact behavior is provider
#     dependent. Q.v.:
#     * Puppet type reference: {package, "purgeable"}[http://j.mp/xbxmNP]
#     * {Puppet's package provider source code}[http://j.mp/wtVCaL]
#   * System modifications (if any) will be reverted as good as possible
#     (e.g. removal of created users, services, changed log settings, ...).
#   * This is thus destructive and should be used with care.
#   Defaults to <tt>present</tt>.
#
# @param graphdb_download_password
#   For http downloads you can set password(basic auth credentials)
#
# @param graphdb_download_user
#   For http downloads you can set user(basic auth credentials)
#
# @param graphdb_download_url
#   Url to the archive to download.
#   This can be a http or https resource for remote packages
#   puppet:// resource or file:/ for local packages
#
# @param graphdb_group
#   String. The group GraphDB should run as. This also sets the file rights
#
# @param graphdb_user
#   String. The group GraphDB should run as. This also sets the file rights
#
# @param import_dir
#   String. GraphDB import location
#
# @param install_dir
#   String. GraphDB distribution location
#
# @param java_home
#   String. The location of java installation
#
# @param log_dir
#   String. GraphDB log directory
#
# @param manage_graphdb_user
#   Boolean. Whether this module manages GraphDB user
#
# @param pid_dir
#   String. GraphDB pid directory
#
# @param purge_data_dir
#   Boolean. Purge data directory on removal
#
# @param restart_on_change
#   Boolean that determines if the application should be automatically restarted
#   whenever the configuration change. Enabling this
#   setting will cause GraphDB to restart whenever there is cause to
#   re-read configuration files, load new plugins, or start the service using an
#   updated/changed executable. This may be undesireable in highly available
#   environments.
#
# @param status
#   String to define the status of the service. Possible values:
#   * <tt>enabled</tt>: Service is running and will be started at boot time.
#   * <tt>disabled</tt>: Service is stopped and will not be started at boot
#     time.
#   * <tt>running</tt>: Service is running but will not be started at boot time.
#     You can use this to start a service on the first Puppet run instead of
#     the system startup.
#   * <tt>unmanaged</tt>: Service will not be started at boot time and Puppet
#     does not care whether the service is running or not. For example, this may
#     be useful if a cluster management software is used to decide when to start
#     the service plus assuring it is running on the desired node.
#   Defaults to <tt>enabled</tt>. The singular form ("service") is used for the
#   sake of convenience. Of course, the defined status affects all services if
#   more than one is managed (see <tt>service.pp</tt> to check if this is the
#   case).
#
# @param tmp_dir
#   String. The location of temporary files that this module will use
#
# @param version
#   String. GraphDB version to install
#
class graphdb (
  Integer $archive_dl_timeout                 = 600,
  Stdlib::Absolutepath $data_dir              = '/var/lib/graphdb',
  Optional[String] $edition                   = undef,
  Graphdb::Ensure $ensure                     = 'present',
  Optional[String] $graphdb_download_password = undef,
  Optional[String] $graphdb_download_user     = undef,
  String $graphdb_download_url                = 'http://maven.ontotext.com/content/groups/all-onto/com/ontotext/graphdb',
  String[1,32] $graphdb_group                 = 'graphdb',
  String[1,32] $graphdb_user                  = 'graphdb',
  Stdlib::Absolutepath $install_dir           = '/opt/graphdb',
  Stdlib::Absolutepath $import_dir            = "${install_dir}/import",
  Optional[Stdlib::Absolutepath] $java_home   = undef,
  Stdlib::Absolutepath $log_dir               = '/var/log/graphdb',
  Boolean $manage_graphdb_user                = true,
  Stdlib::Absolutepath $pid_dir               = '/var/run/graphdb',
  Boolean $purge_data_dir                     = false,
  Boolean $restart_on_change                  = true,
  Graphdb::Status $status                     = 'enabled',
  Stdlib::Absolutepath $tmp_dir               = '/var/tmp/graphdb',
  String $version                             = undef,
) {
  #### Validate parameters

  if ($ensure == 'present') {
    if (!$version) {
      fail('"ensure" is set on present, you should provide "version"')
    }

    # version
    if versioncmp($version, '7.0.0') < 0 {
      fail('This module support GraphDB version 7.0.0 and up')
    }

    if versioncmp($version, '10') < 0 {
      if !($edition in ['se', 'ee']) {
        fail("\"${edition}\" is not a valid edition parameter value")
      }
    }

    # kernel
    $kernel = $facts['kernel']
    if !($kernel in ['Linux']) {
      fail("\"${module_name}\" provides no support for kernel \"${kernel}\"")
    }

    # os
    $operatingsystem = $facts['os']['name']
    $operatingsystemmajrelease = $facts['os']['release']['major']
    #$operatingsystem = $facts['operatingsystem'] # lint:ignore:legacy_facts
    #$operatingsystemmajrelease = $facts['operatingsystemmajrelease'] # lint:ignore:legacy_facts

    if !($operatingsystem in ['RedHat', 'CentOS', 'Debian', 'Ubuntu'])
    or  ($operatingsystem in ['RedHat', 'CentOS'] and versioncmp($operatingsystemmajrelease, '7') < 0)
    or ($operatingsystem in ['Debian'] and versioncmp($operatingsystemmajrelease, '8') < 0)
    or ($operatingsystem in ['Ubuntu'] and versioncmp($operatingsystemmajrelease, '15') < 0) {
      fail("\"${module_name}\" provides no support for \"${operatingsystem}\" \"${operatingsystemmajrelease}\"")
    }

    #basic auth credentials validation
    if ($graphdb_download_user and !$graphdb_download_password) or (!$graphdb_download_user and $graphdb_download_password) {
      fail('When using basic auth credentials you should provide both graphdb_download_user and graphdb_download_password')
    }

    if $java_home {
      $java_location = $java_home
    }
    elsif $facts['graphdb_java_home'] {
      $java_location = $facts['graphdb_java_home']
    }
    else {
      $java_location = '/usr/lib/jvm/java-8-openjdk-amd64'
    }
  }

  include graphdb::install
  include graphdb::tool_links

  #### Relationships

  if $ensure == 'present' {
    Class['graphdb::install']
    -> Class['graphdb::tool_links']
    -> Graphdb::Instance <| |>
  } else {
    Graphdb::Instance <| |> -> Class['graphdb::install']
  }
}
