class NdnCxx < Package

  desc "ndn-cxx library"
  homepage "https://named-data.net/doc/ndn-cxx/"
  url 'git://github.com/named-data/ndn-cxx.git|git_commit:0d748af32fd701b0d4fb6088a472f336790ee6f9'

  release version: '0.6.6-1', crystax_version: 1

  depends_on 'boost'
  depends_on 'openssl'
  depends_on 'sqlite'

  build_options setup_env:            false,
                use_cxx:              true,
                copy_installed_dirs:  [],
                gen_android_mk:       true

  def initialize(path)
    super path
    @lib_deps = Hash.new([])
  end

  # def pre_build(src_dir, release)
  # end

  def post_build(pkg_dir, release)
    gen_android_mk pkg_dir, release
    nil
  end

  def build_for_abi(abi, _toolchain, release, _host_dep_dirs, _target_dep_dirs, _options)
    
    @boost_dir = _target_dep_dirs['boost']
    @openssl_dir = _target_dep_dirs['openssl']
    @sqlite3_dir = _target_dep_dirs['sqlite']

    args =  [ "--enable-shared",
              "--disable-static",
            ]

    arch = Build.arch_for_abi(abi)
    src_dir = build_dir_for_abi(abi)
    
    Build::TOOLCHAIN_LIST.each do |toolchain|
      build_env.clear
      stl_name = toolchain.stl_name
      puts "    using C++ standard library: #{stl_name}"

      work_dir = "#{src_dir}/#{stl_name}"
      prefix_dir = "#{work_dir}/install"


      host_tc_dir = "#{work_dir}/host-bin"
      FileUtils.mkdir_p host_tc_dir
      host_cc = "#{host_tc_dir}/cc"
      Build.gen_host_compiler_wrapper host_cc, 'gcc'

      setup_build_env(abi, toolchain)

      File.open("VERSION", "w") do |f|
        f.write release.version
      end

      cxx_args = [ "--prefix=/",
                   "--destdir=#{prefix_dir}",
                   "--boost-includes=#{@boost_dir}/include",
                   "--boost-libs=#{@boost_dir}/libs/#{abi}/#{stl_name}",
                   "--with-openssl=#{@openssl_dir}",
                   "--with-sqlite3=#{@sqlite3_dir}",
                   "--sysconfdir=./etc",
                 ]
      # need to customize link folders through LINKFLAGS
      @build_env['LINKFLAGS'] = [
        "-L#{@openssl_dir}/libs/#{abi}",
        "-L#{@sqlite3_dir}/libs/#{abi}",
        "-llog"
      ].join(' ')

      puts "      configuring ndn-cxx"
      system './waf',  "configure", *args, *cxx_args

      puts "      building ndn-cxx"
      system "./waf", "build", "-j#{num_jobs}", "-v"
      system "./waf", "install", "--destdir=#{prefix_dir}"

      @lib_deps = Hash.new([])
      Dir["#{prefix_dir}/lib/*.so"].each do |lib|
        name = File.basename(lib).split('.')[0]
        abi_deps = toolchain.find_so_needs(lib, arch).select { |l| l.start_with? 'libboost_' }.map { |l| l.gsub(/^libboost_/, '') }.sort
        if @lib_deps[name] == []
          @lib_deps[name] = abi_deps
        elsif @lib_deps[name] != abi_deps
          raise "#{lib} has strange dependencies for #{arch.name} and #{toolchain.name}: expected: #{@lib_deps[name]}; got: #{abi_deps}"
        end
      end

      # copy headers if they were not copied yet
      inc_dir = "#{package_dir}/include"
      if !Dir.exists? inc_dir
        FileUtils.mkdir_p package_dir
        FileUtils.cp_r "#{prefix_dir}/include", package_dir
      end
      # copy libs
      libs_dir = "#{package_dir}/libs/#{abi}/#{stl_name}"
      FileUtils.mkdir_p libs_dir
      FileUtils.cp Dir["#{prefix_dir}/lib/*.so"], libs_dir
    end
  end

  def gen_android_mk(pkg_dir, release)
    File.open("#{pkg_dir}/Android.mk", "w") do |f|
      f.puts Build::COPYRIGHT_STR
      f.puts ''
      f.puts 'LOCAL_PATH := $(call my-dir)'
      f.puts ''
      f.puts 'ifeq (,$(filter c++_%,$(APP_STL)))'
      f.puts '$(error $(strip \\'
      f.puts '    We do not support APP_STL \'$(APP_STL)\' for libndn-cxx! \\'
      f.puts '    Please use "c++_shared". \\'
      f.puts '))'
      f.puts 'endif'
      f.puts ''

      f.puts 'include $(CLEAR_VARS)'
      f.puts "LOCAL_MODULE := ndn_cxx_shared"
      f.puts "LOCAL_SRC_FILES := libs/$(TARGET_ARCH_ABI)/llvm/libndn-cxx.so"
      f.puts 'LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include'
      f.puts 'ifneq (,$(filter clang%,$(NDK_TOOLCHAIN_VERSION)))'
      f.puts 'LOCAL_EXPORT_LDLIBS := -latomic'
      f.puts 'endif'
      @lib_deps["libndn-cxx"].each do |dep|
        f.puts "LOCAL_SHARED_LIBRARIES += boost_#{dep}_shared"
      end
      f.puts "LOCAL_SHARED_LIBRARIES += libcrypto_shared libssl_shared"
      f.puts "LOCAL_SHARED_LIBRARIES += libsqlite3_shared"
      f.puts 'include $(PREBUILT_SHARED_LIBRARY)'

      f.puts ''
      f.puts "$(call import-module,../packages/#{import_module_path(@boost_dir)})"
      f.puts "$(call import-module,../packages/#{import_module_path(@openssl_dir)})"
      f.puts "$(call import-module,../packages/#{import_module_path(@sqlite3_dir)})"

    end
  end

  # take two last components of the path
  def import_module_path(path)
    v = path.split('/')
    "#{v[v.size-2]}/#{v[v.size-1]}"
  end

  def sonames_translation_table(release)
    v = release.version.split('-')[0]
    puts "version for soname: #{v}"
    {
      "libndn-cxx.so.#{v}" => "libndn-cxx"
    }
  end

end
