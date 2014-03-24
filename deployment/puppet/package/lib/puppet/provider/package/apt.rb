Puppet::Type.type(:package).provide :apt, :parent => :dpkg, :source => :dpkg do
  # Provide sorting functionality
  include Puppet::Util::Package

  desc "Package management via `apt-get`."

  has_feature :versionable

  commands :aptget => "/usr/bin/apt-get"
  commands :aptcache => "/usr/bin/apt-cache"
  commands :preseed => "/usr/bin/debconf-set-selections"
  commands :dpkgquery => '/usr/bin/dpkg-query'

  defaultfor :operatingsystem => [:debian, :ubuntu]

  ENV['DEBIAN_FRONTEND'] = "noninteractive"

  # disable common apt helpers to allow non-interactive package installs
  ENV['APT_LISTBUGS_FRONTEND'] = "none"
  ENV['APT_LISTCHANGES_FRONTEND'] = "none"

  # A derivative of DPKG; this is how most people actually manage
  # Debian boxes, and the only thing that differs is that it can
  # install packages from remote sites.

  def checkforcdrom
    unless defined?(@@checkedforcdrom)
      if FileTest.exists? "/etc/apt/sources.list"
        @@checkedforcdrom = !!(File.read("/etc/apt/sources.list") =~ /^[^#]*cdrom:/)
      else
        # This is basically a pathalogical case, but we'll just
        # ignore it
        @@checkedforcdrom = false
      end
    end

    if @@checkedforcdrom and @resource[:allowcdrom] != :true
      raise Puppet::Error,
        "/etc/apt/sources.list contains a cdrom source; not installing.  Use 'allowcdrom' to override this failure."
    end
  end

  # @param pkg <Hash,TrueClass,FalseClass,Symbol,String>
  # @param action <Symbol>
  def install_cmd(pkg)
    cmd = %w{-q -y}

    config = @resource[:configfiles]
    if config == :keep
      cmd << "-o" << 'DPkg::Options::=--force-confold'
    else
      cmd << "-o" << 'DPkg::Options::=--force-confnew'
    end

    cmd << '--force-yes'
    cmd << :install

    if pkg.is_a? Hash
      # make install string from package hash
      cmd += pkg.map do |p|
        if p[1] == :absent
          "#{p[0]}-"
        else
          "#{p[0]}=#{p[1]}"
        end
      end
    elsif pkg.is_a? String
      # install a specific version
      cmd << "#{@resource[:name]}=#{pkg}"
    else
      # install any version
      cmd << @resource[:name]
    end

    cmd
  end

  #def aptget(*cmd)
  #  p cmd
  #end

  # Install a package using 'apt-get'.  This function needs to support
  # installing a specific version.
  def install
    self.run_preseed if @resource[:responsefile]
    should = @resource[:ensure]
    @file_dir = '/var/lib/puppet/rollback'

    Dir.mkdir @file_dir unless File.directory? @file_dir

    checkforcdrom

    from = @property_hash[:ensure]
    to = @resource[:ensure]
    name = @resource[:name]
    if to == :latest
      to = latest
    end

    Puppet.notice "Installing package #{name} from #{from} to #{to}"

    # check if there is a rollback file
    rollback_file = File.join @file_dir, "#{name}=#{to}=#{from}.yaml"
    if File.readable? rollback_file
      require 'yaml'
      diff = YAML.load_file rollback_file
      if diff.is_a? Hash
        Puppet.notice "Found rollback file at #{rollback_file}"
        installed = diff['installed']
        removed = diff['removed']

        # calculate package sets
        to_update = package_updates removed, installed
        to_install = package_diff removed, installed
        to_remove = package_diff installed, removed, true

        Puppet.notice "Install: #{to_install.map {|p| "#{p[0]}=#{p[1]}" }. join ' '}" if to_install.any?
        Puppet.notice "Remove: #{to_remove.map {|p| "#{p[0]}=#{p[1]}" }. join ' '}" if to_remove.any?
        Puppet.notice "Update: #{to_update.map {|p| "#{p[0]}=#{p[1]}" }. join ' '}" if to_update.any?

        # combine package lists to a single list
        all_packages = to_install
        all_packages = all_packages.merge to_update
        to_remove.each_pair {|k,v| to_remove.store k, :absent}
        all_packages = all_packages.merge to_remove

        if all_packages.any?
          Puppet.notice "All: #{all_packages.map {|p| "#{p[0]}=#{p[1]}" }. join ' '}" if all_packages.any?
          cmd = install_cmd all_packages
          aptget(*cmd)
        end

        return
      end
    end

    cmd = install_cmd(should)

    # check if we are updating
    statuses = [ :purged ,:absent, :held, :latest, :instlled]
    unless statuses.include? from or statuses.include? to
      before = pkg_list
      aptget(*cmd)
      after = pkg_list
      installed = package_diff after, before
      removed = package_diff before, after
      diff = { 'installed' => installed, 'removed' => removed }
      file_path = File.join @file_dir, "#{name}=#{from}=#{to}.yaml"
      File.open(file_path, 'w') { |file| file.write YAML.dump(diff) + "\n" }
      Puppet.notice "Saving diff file to #{file_path}"
      return
    end

    # just install the package
    aptget(*cmd)
  end

  # Substract packages in hash b from packages in hash a
  # in noval is true only package name matters and version is ignored
  # @param a <Hash>
  # @param b <Hash>
  # @param noval <TrueClass,FalseClass>
  def package_diff(a, b, noval=false)
    result = a.dup
    b.each_pair do |k, v|
      if a.key? k
        if a[k] == v or noval
          result.delete k
        end
      end
    end
    result
  end

  # find package names in both a and b hashes
  # values are taken from a
  # @param a <Hash>
  # @param b <Hash>
  def package_updates(a, b)
    common_keys = a.keys & b.keys
    result = {}
    common_keys.each { |p| result.store p, a[p] }
    result
  end

  def pkg_list
    packages = {}
    raw_pkgs = dpkgquery [ '--show', '-f=${Package}|${Version}|${Status}\n' ]
    raw_pkgs.split("\n").each do |l|
      line = l.split('|')
      next unless line[2] == 'install ok installed'
      name = line[0]
      version = line[1]
      next unless name and version
      packages.store name, version
    end
    packages
  end

  # What's the latest package version available?
  def latest
    output = aptcache :policy,  @resource[:name]

    if output =~ /Candidate:\s+(\S+)\s/
      return $1
    else
      self.err "Could not find latest version"
      return nil
    end
  end

  #
  # preseeds answers to dpkg-set-selection from the "responsefile"
  #
  def run_preseed
    if response = @resource[:responsefile] and FileTest.exist?(response)
      self.info("Preseeding #{response} to debconf-set-selections")

      preseed response
    else
      self.info "No responsefile specified or non existant, not preseeding anything"
    end
  end

  def uninstall
    self.run_preseed if @resource[:responsefile]
    aptget "-y", "-q", :remove, @resource[:name]
  end

  def purge
    self.run_preseed if @resource[:responsefile]
    aptget '-y', '-q', :remove, '--purge', @resource[:name]
    # workaround a "bug" in apt, that already removed packages are not purged
    super
  end
end
