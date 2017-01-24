class Make < Utility

  desc "Utility for directing compilation"
  homepage "https://www.gnu.org/software/make/"
  #url "https://ftpmirror.gnu.org/make/make-${version}.tar.bz2"

  release version: '3.81', crystax_version: 1, sha256: { linux_x86_64:   '0bc17909588d6c909960ad3814be244ca5b5b044e4128fd981098710ba8f41e7',
                                                         darwin_x86_64:  '083982581fba1e3b91b5b333103eb9e39759ba50f1514eb78da9dcf35c5479ce',
                                                         windows_x86_64: 'ad3f8902baf777bc0a512a6c77228d0d375df1d3c3381edd0bda6d68eca279fb',
                                                         windows:        '0fd4bf8f9be5c0abe4402ae407f84cbe99f61c8e812ae675407f3a84e2bd1332'
                                                       }

  executables 'make'

  def prepare_source_code(release, dir, src_name, log_prefix)
    # source code is in sources/host-tools/ directory
  end

  def build_for_platform(platform, release, options, _host_dep_dirs, _target_dep_dirs)
    src_dir = File.join(Build::NDK_HOST_TOOLS_DIR, "make-#{release.version}")
    install_dir = install_dir_for_platform(platform, release)

    args = ["--prefix=#{install_dir}",
            "--host=#{platform.configure_host}",
            "--disable-nls",
            "--disable-rpath"
           ]

    system "#{src_dir}/configure", *args
    system 'make', '-j', num_jobs
    system 'make', 'test' if options.check? platform
    system 'make', 'install'

    # remove unneeded files before packaging
    FileUtils.cd(install_dir) { FileUtils.rm_rf 'share' }
  end
end
