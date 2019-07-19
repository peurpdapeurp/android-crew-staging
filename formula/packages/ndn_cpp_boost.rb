class NdnCpp < Package

  desc "ndn-cpp library"
  homepage "https://named-data.net/doc/ndn-cpp/"
  url 'git://github.com/named-data/ndn-cpp.git|git_commit:4ace2ff4e1b9671591797c84f3d8a748a6c2c64e'

  release version: '0.16-48-g4ace2ff4', crystax_version: 2

  depends_on 'boost'
  depends_on 'openssl'
  depends_on 'sqlite'
  depends_on 'protobuf'

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
    @protobuf_dir = _target_dep_dirs['protobuf']

    args =  [
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
                   "--enable-static=false",
                   "--host=#{host_for_abi(abi)}",
                   "--with-boost=#{@boost_dir}",
                   "--with-boost-libdir=#{@boost_dir}/libs/#{abi}/#{stl_name}",
                   "--with-sqlite3=#{@sqlite3_dir}",
                   "--sysconfdir=/etc",
                   "ADD_CFLAGS='-I#{@openssl_dir}/include -I#{@sqlite3_dir}/include -I#{@protobuf_dir}/include'",
                   "ADD_CXXFLAGS='-I#{@openssl_dir}/include -I#{@sqlite3_dir}/include -I#{@protobuf_dir}/include'",
                   "ADD_LDFLAGS='-L#{@openssl_dir}/libs/#{abi} -L#{@sqlite3_dir}/libs/#{abi} -L#{@protobuf_dir}/libs/#{abi}/#{stl_name} -lm -llog'",
                 ]
      # need to customize link folders through LINKFLAGS
      @build_env['LINKFLAGS'] = [
      ].join(' ')

      puts "      configuring ndn-cpp"
      system "./configure", *args, *cxx_args

      puts "      building ndn-cpp"
      system "make", "-j#{num_jobs}", "-v"
      system "make", "install", "DESTDIR=#{prefix_dir}"

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
      f.puts '    We do not support APP_STL \'$(APP_STL)\' for libndn-cpp! \\'
      f.puts '    Please use "c++_shared". \\'
      f.puts '))'
      f.puts 'endif'
      f.puts ''

      f.puts 'include $(CLEAR_VARS)'
      f.puts "LOCAL_MODULE := ndn_cpp_shared"
      f.puts "LOCAL_SRC_FILES := libs/$(TARGET_ARCH_ABI)/llvm/libndn-cpp.so"
      f.puts 'LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include'
      f.puts 'ifneq (,$(filter clang%,$(NDK_TOOLCHAIN_VERSION)))'
      f.puts 'LOCAL_EXPORT_LDLIBS := -latomic'
      f.puts 'endif'
      @lib_deps["libndn-cpp"].each do |dep|
        f.puts "LOCAL_SHARED_LIBRARIES += boost_#{dep}_shared"
      end
      f.puts "LOCAL_SHARED_LIBRARIES += libcrypto_shared libssl_shared"
      f.puts "LOCAL_SHARED_LIBRARIES += libsqlite3_shared"
      f.puts "LOCAL_SHARED_LIBRARIES += libprotobuf_shared"
      f.puts 'include $(PREBUILT_SHARED_LIBRARY)'

      f.puts ''
      f.puts "$(call import-module,../packages/#{import_module_path(@boost_dir)})"
      f.puts "$(call import-module,../packages/#{import_module_path(@openssl_dir)})"
      f.puts "$(call import-module,../packages/#{import_module_path(@sqlite3_dir)})"
      f.puts "$(call import-module,../packages/#{import_module_path(@protobuf_dir)})"

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
      "libndn-cpp.so.#{v}" => "libndn-cpp"
    }
  end

end
