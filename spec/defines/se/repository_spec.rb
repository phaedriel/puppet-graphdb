# frozen_string_literal: true

require 'spec_helper'

describe 'graphdb::se::repository', type: :define do
  let :facts do
    {
      kernel: 'Linux',
      os:  { 'name' => 'Debian', 'release' => { 'major' => '11' } },
      graphdb_java_home: '/opt/jdk8',
      ipaddress: '129.10.1.1',
      networking: { 'ip' => '129.10.1.1' }
    }
  end

  let(:title) { 'test' }

  let :pre_condition do
    "class { 'graphdb': version => '9.10.1', edition => 'ee' }"
  end

  context 'with ensure set to present' do
    let(:params) { { endpoint: 'http://test.com', repository_context: 'test:test' } }

    it { is_expected.to contain_graphdb__se__repository('test') }
    it do
      is_expected.to contain_graphdb_repository('test')
        .with(ensure: 'present',
              repository_id: 'test',
              endpoint: 'http://test.com',
              repository_context: 'test:test')
    end
  end

  context 'with ensure set to absent' do
    let(:params) { { ensure: 'absent', endpoint: 'http://test.com', repository_context: 'test:test' } }

    it { is_expected.to contain_graphdb__se__repository('test') }
    it do
      is_expected.to contain_graphdb_repository('test')
        .with(ensure: 'absent',
              repository_id: 'test',
              endpoint: 'http://test.com',
              repository_context: 'test:test')
    end
  end
end
