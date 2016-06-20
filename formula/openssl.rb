class Openssl < Package

  desc "Cryptography and SSL/TLS Toolkit"
  homepage "https://openssl.org/"
  url 'https://openssl.org/source/openssl-${version}.tar.gz'

  release version: '1.0.2h', crystax_version: 1, sha256: '0'

  build_options copy_bin: true
  build_copy 'LICENSE'
  build_libs 'libcrypto', 'libssl'

  def build_for_abi(abi, toolchain,  _release, _dep_dirs)
    install_dir = install_dir_for_abi(abi)
    build_env['CFLAGS'] << ' -DOPENSSL_NO_DEPRECATED'

    args = ["--prefix=#{install_dir}",
            "shared",
            "zlib-dynamic",
            target(abi),
            build_env['CFLAGS'],
            build_env['LDFLAGS'],
           ]

    system './Configure',  *args
    fix_ccgost_makefile build_dir_for_abi(abi), toolchain.ldflags(abi)
    system 'make', 'depend'
    system 'make', '-j', num_jobs
    system "make install"

    # prepare installed files for packaging
    FileUtils.rm_rf File.join(install_dir, 'lib', 'pkgconfig')
    FileUtils.cd(File.join(install_dir, 'lib')) do
      FileUtils.rm 'libcrypto.so'
      FileUtils.mv 'libcrypto.so.1.0.0', 'libcrypto.so'
      FileUtils.rm 'libssl.so'
      FileUtils.mv 'libssl.so.1.0.0', 'libssl.so'
    end

    # copy engines
    libs_dir = "#{package_dir}/libs/#{abi}"
    FileUtils.mkdir_p libs_dir
    FileUtils.cp_r File.join(install_dir, 'lib', 'engines'), libs_dir
  end

  def target(abi)
    case abi
    when 'x86'       then 'linux-elf'
    when 'x86_64'    then 'linux-x86_64'
    when /^armeabi/  then 'linux-armv4'
    when 'arm64-v8a' then 'linux-aarch64'
    when 'mips'      then 'linux-generic32'   # Looks like asm code in OpenSSL doesn't support MIPS32r6
    when 'mips64'    then 'linux-generic64'   # Looks like asm code in OpenSSL doesn't support MIPS64r6
    else
      raise "Unsupported abi #{abi}"
    end
  end

  def fix_ccgost_makefile(build_dir, ldflgs)
    makefile = File.join(build_dir, 'engines', 'ccgost', 'Makefile')
    lines = []
    replaced = false
    File.foreach(makefile) do |l|
      if not l.include?('LIBDEPS=\'-L$(TOP) -lcrypto\'')
        lines << l
      else
        lines << l.gsub('LIBDEPS=\'', "LIBDEPS=\'#{ldflgs} ")
        replaced = true
      end
    end

    raise "not found required line in #{makefile}" unless replaced

    File.open(makefile, 'w') { |f| f.puts lines }
  end
end
