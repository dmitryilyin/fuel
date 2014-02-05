        class { 'cinder::volume::iscsi':
          iscsi_ip_address => $iscsi_bind_host,
          physical_volume  => $physical_volume,
          volume_group     => $volume_group,
        }
