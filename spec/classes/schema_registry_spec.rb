require 'spec_helper'

describe 'confluent::schema::registry' do
  supported_osfamalies.each do |osfamily, osversions|
    osversions.each do |osversion|
      context "with osfamily => #{osfamily} and operatingsystemmajrelease => #{osversion}" do
        default_facts = {
            'osfamily' => osfamily,
            'operatingsystemmajrelease' => osversion
        }
        default_params = {
            'config' => {
                'kafkastore.connection.url' => {
                    'value' => 'zookeeper-01:2181,zookeeper-02:2181,zookeeper-03:2181'
                }
            }
        }

        environment_file = nil

        case osfamily
          when 'Debian'
            environment_file = '/etc/default/schema-registry'
          when 'RedHat'
            environment_file = '/etc/sysconfig/schema-registry'
        end

        let(:facts) {default_facts}
        let(:params) {default_params}

        log_paths = %w(/var/log/schema-registry /logs/var/lib/schema-registry)
        log_paths.each do |log_path|
          context "with log_path => #{log_path}" do
            let(:params) {default_params.merge({'log_path' => log_path})}
            it {is_expected.to contain_file(log_path).with({'owner' => 'schema-registry', 'group' => 'schema-registry'})}
          end
        end

        expected_heap = '-Xmx256M'

        it {is_expected.to contain_ini_subsetting('schema-registry_SCHEMA_REGISTRY_HEAP_OPTS').with({'path' => environment_file, 'value' => expected_heap})}
        it {is_expected.to contain_ini_setting('schema-registry_kafkastore.connection.url').with({'path' => '/etc/schema-registry/schema-registry.properties', 'value' => 'zookeeper-01:2181,zookeeper-02:2181,zookeeper-03:2181'})}
        it {is_expected.to contain_package('confluent-schema-registry')}
        it {is_expected.to contain_user('schema-registry')}
        it {is_expected.to contain_service('schema-registry').with({'ensure' => 'running', 'enable' => true})}
      end
    end
  end
end