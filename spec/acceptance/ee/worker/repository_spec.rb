# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'graphdb::ee::worker::repository', unless: UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do
  graphdb_version = ENV['GRAPHDB_VERSION']
  graphdb_timeout = ENV['GRAPHDB_TIMEOUT']

  context 'ee installation with worker repository' do
    let(:manifest) do
      <<-EOS
       class{ 'graphdb':
         version              => '#{graphdb_version}',
         edition              => 'ee',
         graphdb_download_url => 'file:///tmp',
       }

       graphdb::instance { 'test':
         license           => '/tmp/ee.license',
         http_port         => 8080,
         validator_timeout => #{graphdb_timeout},
       }

       graphdb::ee::worker::repository { 'test-repo':
         repository_id       => 'test-repo',
         endpoint            => "http://${::ipaddress}:8080",
         repository_context  => 'http://ontotext.com/pub/',
         timeout             => #{graphdb_timeout},
       }
      EOS
    end
    it do
      apply_manifest(manifest, catch_failures: true, debug: ENV['DEBUG'] == 'true')
      expect(apply_manifest(manifest, catch_failures: true, debug: ENV['DEBUG'] == 'true').exit_code).to be_zero
    end

    describe command("curl -f -s -m 30 --connect-timeout 20 -X GET 'http://#{fact('ipaddress')}:8080/repositories/test-repo/size'") do
      its(:exit_status) { should eq 0 }
    end
  end

  context 'ee installation with worker repository removal' do
    let(:manifest) do
      <<-EOS
       class{ 'graphdb':
         version              => '#{graphdb_version}',
         edition              => 'ee',
         graphdb_download_url => 'file:///tmp',
       }

       graphdb::instance { 'test':
         license           => '/tmp/ee.license',
         http_port         => 8080,
         validator_timeout => #{graphdb_timeout},
       }

       graphdb::ee::worker::repository { 'test-repo':
         ensure              => 'absent',
         repository_id       => 'test-repo',
         endpoint            => "http://${::ipaddress}:8080",
         repository_context  => 'http://ontotext.com/pub/',
         timeout             => #{graphdb_timeout},
       }
      EOS
    end

    it do
      apply_manifest(manifest, catch_failures: true, debug: ENV['DEBUG'] == 'true')
      expect(apply_manifest(manifest, catch_failures: true, debug: ENV['DEBUG'] == 'true').exit_code).to be_zero
    end

    describe command("curl -f -m 30 --connect-timeout 20 -X GET 'http://#{fact('ipaddress')}:8080/repositories/test-repo/size'") do
      its(:exit_status) { should eq 22 }
      its(:stderr) { should match /The requested URL returned error: 404/ }
    end
  end
end
