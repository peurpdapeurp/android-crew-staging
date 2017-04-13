class Libobjc2 < Package

  desc 'GNUstep Objective-C Runtime'
  homepage 'https://github.com/gnustep/libobjc2'
  # todo: use commit? tag? something else?
  url 'https://github.com/crystax/android-vendor-libobjc2.git|git_commit:36d73233f25183d7f371176e0417ca1c94c43c6f'

  release version: '1.8.1', crystax_version: 1, sha256: '5098f1a67d0169412e6c69d8b82cb0b649c49519a2724579c26cb39998d4963a'

  build_options setup_env: false

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, target_dep_dirs)
    install_dir = install_dir_for_abi(abi)

    args = ["-DWITH_TESTS=NO",
	    "-DCMAKE_INSTALL_PREFIX=#{install_dir}",
	    "-DCMAKE_TOOLCHAIN_FILE=#{Build::CMAKE_TOOLCHAIN_FILE}",
	    "-DANDROID_ABI=#{abi}",
	    "-DANDROID_TOOLCHAIN_VERSION=clang#{Toolchain::DEFAULT_LLVM.version}",
	    "."
           ]

    system 'cmake', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'

    internal_headers_dir = File.join(install_dir, 'include', 'internal')
    FileUtils.mkdir_p internal_headers_dir
    FileUtils.cp ['class.h', 'visibility.h'], internal_headers_dir
  end
end
