require 'spec_helper'

describe 'graphdb::instance', type: :define do
  let :facts do
    {
      kernel: 'Linux',
      operatingsystem: 'Ubuntu',
      operatingsystemmajrelease: '6',
      machine_java_home: '/opt/jdk7',
      ipaddress: '127.0.0.1'
    }
  end

  let(:title) { 'test' }

  describe 'with minimum configuration' do
    let :pre_condition do
      "class { 'graphdb': version => '7.0.0', edition => 'ee' }"
    end
    context 'with ensure set to present' do
      let(:params) { { license: 'license' } }

      it do
        is_expected.to contain_graphdb__instance(title).that_requires('Class[graphdb::install]')
        is_expected.to contain_file('/opt/graphdb/instances/test/license').with(ensure: 'present',
                                                                                owner: 'graphdb',
                                                                                group: 'graphdb',
                                                                                mode: '0555',
                                                                                notify: "Service[graphdb-#{title}]")
        is_expected.to contain_file('/opt/graphdb/instances/test').with(ensure: 'directory',
                                                                        owner: 'graphdb',
                                                                        group: 'graphdb',
                                                                        notify: "Service[graphdb-#{title}]")
        is_expected.to contain_file('/var/lib/graphdb/test/plugins').with(ensure: 'directory',
                                                                          owner: 'graphdb',
                                                                          group: 'graphdb',
                                                                          notify: "Service[graphdb-#{title}]")
        is_expected.to contain_file('/var/lib/graphdb/test').with(ensure: 'directory',
                                                                  owner: 'graphdb',
                                                                  group: 'graphdb',
                                                                  notify: "Service[graphdb-#{title}]")
        is_expected.to contain_file('/var/tmp/graphdb/test').with(ensure: 'directory',
                                                                  owner: 'graphdb',
                                                                  group: 'graphdb',
                                                                  notify: "Service[graphdb-#{title}]")
        is_expected.to contain_file('/opt/graphdb/instances/test/conf').with(ensure: 'directory',
                                                                             owner: 'graphdb',
                                                                             group: 'graphdb')

        is_expected.to contain_file('/opt/graphdb/instances/test/conf/graphdb.properties')
          .with(ensure: 'present',
                notify:  "Service[graphdb-#{title}]",
                owner: 'graphdb',
                group: 'graphdb',
                content: "graphdb.connector.port = 8080
graphdb.home.data = /var/lib/graphdb/test
graphdb.home.logs = /var/log/graphdb/test
graphdb.license.file = /opt/graphdb/instances/test/license
")

        is_expected.to contain_graphdb__service("graphdb-#{title}").with(ensure: 'present', status: 'enabled')
        is_expected.to contain_graphdb_validator(title).with(endpoint: 'http://127.0.0.1:8080')
      end
    end

    context 'with ensure set to absent' do
      let(:params) { { license: 'license', ensure: 'absent' } }

      it do
        is_expected.to contain_file('/opt/graphdb/instances/test/license').with(ensure: 'absent')
        is_expected.to contain_file('/opt/graphdb/instances/test').with(ensure: 'absent')
        is_expected.to contain_file('/var/lib/graphdb/test/plugins').with(ensure: 'absent')
        is_expected.to contain_file('/var/lib/graphdb/test').with(ensure: 'absent')
        is_expected.to contain_file('/var/tmp/graphdb/test').with(ensure: 'absent')
        is_expected.to contain_file('/opt/graphdb/instances/test/conf').with(ensure: 'absent')
        is_expected.to contain_file('/opt/graphdb/instances/test/conf/graphdb.properties').with(ensure: 'absent')
        is_expected.to contain_graphdb__service("graphdb-#{title}").with(ensure: 'absent')
        is_expected.to_not contain_graphdb_validator(title).with(endpoint: 'http://127.0.0.1:8080')
      end
    end
  end

  describe 'with status set to disabled' do
    let :pre_condition do
      "class { 'graphdb': version => '7.0.0', edition => 'ee' }"
    end

    let(:params) { { license: 'license', status: 'disabled' } }

    it do
      is_expected.to contain_graphdb__service("graphdb-#{title}").with(ensure: 'present', status: 'disabled')
    end
  end

  describe 'with custom http_port' do
    let :pre_condition do
      "class { 'graphdb': version => '7.0.0', edition => 'ee' }"
    end

    let(:params) { { license: 'license', http_port: 9090 } }

    it do
      is_expected.to contain_file('/opt/graphdb/instances/test/conf/graphdb.properties')
        .with(ensure: 'present',
              owner: 'graphdb',
              group: 'graphdb',
              content: /graphdb.connector.port = 9090/)

      is_expected.to contain_graphdb_validator(title).with(endpoint: 'http://127.0.0.1:9090')
    end
  end

  describe 'with custom kill_timeout' do
    let :pre_condition do
      "class { 'graphdb': version => '7.0.0', edition => 'ee' }"
    end

    let(:params) { { license: 'license', kill_timeout: 300 } }
    context 'upstart' do
      let :facts do
        {
          kernel: 'Linux',
          operatingsystem: 'Ubuntu',
          operatingsystemmajrelease: '6',
          machine_java_home: '/opt/jdk7',
          ipaddress: '127.0.0.1'
        }
      end
      it do
        is_expected.to contain_file('/etc/init/graphdb-test.conf').with(content: /kill timeout 300/)
      end
    end

    context 'systemd' do
      let :facts do
        {
          kernel: 'Linux',
          operatingsystem: 'Ubuntu',
          operatingsystemmajrelease: '16',
          machine_java_home: '/opt/jdk7',
          ipaddress: '127.0.0.1'
        }
      end
      it do
        is_expected.to contain_file('/lib/systemd/system/graphdb-test.service').with(content: /TimeoutStopSec=300/)
      end
    end
  end

  describe 'with custom jolokia_secret' do
    let :pre_condition do
      "class { 'graphdb': version => '7.0.0', edition => 'ee' }"
    end

    let(:params) { { license: 'license', jolokia_secret: 'test_jolokia_secret' } }

    it do
      is_expected.to contain_file('/opt/graphdb/instances/test/conf/graphdb.properties')
        .with(content: /graphdb.jolokia.secret = test_jolokia_secret/)
    end
  end

  describe 'with extra_properties' do
    let :pre_condition do
      "class { 'graphdb': version => '7.0.0', edition => 'ee' }"
    end

    let(:params) { { license: 'license', extra_properties: { 'test_property' => 'test_property_value' } } }

    it do
      is_expected.to contain_file('/opt/graphdb/instances/test/conf/graphdb.properties')
        .with(content: /test_property = test_property_value/)
    end
  end

  describe 'with not valid params' do
    let :pre_condition do
      "class { 'graphdb': version => '7.0.0', edition => 'ee' }"
    end
    context 'not valid license' do
      let(:params) { { license: 123 } }

      it do
        expect { is_expected.to contain_graphdb__instance(title) }.to raise_error(Puppet::ParseError)
      end
    end

    context 'not valid jolokia_secret' do
      let(:params) { { license: 'license', jolokia_secret: 123 } }

      it do
        expect { is_expected.to contain_graphdb__instance(title) }.to raise_error(Puppet::ParseError)
      end
    end
  end
end
