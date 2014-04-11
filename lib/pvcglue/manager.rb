require 'pp'

module Pvcglue
  class Manager < Thor

    desc "bootstrap", "bootstrap"

    def bootstrap
      Pvcglue::Packages.apply('bootstrap-manager'.to_sym, manager_node, 'root')
    end

    desc "push", "push"

    def push
      Pvcglue::Packages.apply('manager-push'.to_sym, manager_node, 'pvcglue')
      self.class.clear_cloud_data_cache
    end

    desc "pull", "pull"

    def pull
      Pvcglue::Packages.apply('manager-pull'.to_sym, manager_node, 'pvcglue')
      self.class.clear_cloud_data_cache
    end

    desc "show", "show"

    def show
      self.class.initialize_cloud_data
      pp Pvcglue.cloud.data
    end

    # ------------------------------------------------------------------------------------------------------------------

    def self.initialize_cloud_data
      unless read_cached_cloud_data
        Pvcglue::Packages.apply('manager-get-all'.to_sym, manager_node, 'pvcglue')
        write_cloud_data_cache
      end
    end

    def self.write_cloud_data_cache
      File.write(Pvcglue.configuration.cloud_cache_file_name, TOML.dump(Pvcglue.cloud.data))
    end

    def self.read_cached_cloud_data
      # TODO:  Expire cache after given interval
      if File.exists?(Pvcglue.configuration.cloud_cache_file_name)
        data = File.read(Pvcglue.configuration.cloud_cache_file_name)
        Pvcglue.cloud.data = TOML.parse(data)
        return true
      end
      false
    end

    def self.clear_cloud_data_cache
      if File.exists?(Pvcglue.configuration.cloud_cache_file_name)
        File.delete(Pvcglue.configuration.cloud_cache_file_name)
      end
    end

    def self.manager_node
      {manager: {public_ip: Pvcglue.configuration.cloud_manager}}
    end

  end

end