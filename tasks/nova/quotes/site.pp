class { 'nova::quota' :
  quota_instances                       => 100,
  quota_cores                           => 100,
  quota_volumes                         => 100,
  quota_gigabytes                       => 1000,
  quota_floating_ips                    => 100,
  quota_metadata_items                  => 1024,
  quota_max_injected_files              => 50,
  quota_max_injected_file_content_bytes => 102400,
  quota_max_injected_file_path_bytes    => 4096
}
