require_relative 'spec_helper.rb'
require_relative '../library/global.rb'
require_relative 'data/releases_info.rb'

describe "crew cleanup" do
  before(:all) do
    ndk_init
  end

  before(:each) do
    clean_cache
    clean_hold
    clean_utilities
    repository_init
    repository_clone
  end

  context "with wrong argument" do
    it "outputs error message" do
      crew 'cleanup', 'bar'
      expect(exitstatus).to_not be_zero
      expect(err.split("\n")[0]).to eq('error: this command accepts only one optional argument: -n')
    end
  end

  context "when there are no formulas and nothing installed" do
    it "outputs nothing" do
      crew 'cleanup'
      expect(result).to eq(:ok)
      expect(out).to eq('')
    end
  end

  # context "when one release installed" do
  #   it "outputs nothing" do
  #     copy_formulas 'libone.rb'
  #     crew_checked 'install', 'libone'
  #     crew 'cleanup'
  #     expect(result).to eq(:ok)
  #     expect(out).to eq('')
  #     expect(in_cache?(:target, 'libone', '1.0.0', 1)).to eq(true)
  #   end
  # end

  # context "when one release installed and -n specified" do
  #   it "outputs nothing" do
  #     copy_formulas 'libone.rb'
  #     crew_checked 'install', 'libone'
  #     crew 'cleanup', '-n'
  #     expect(result).to eq(:ok)
  #     expect(out).to eq('')
  #     expect(in_cache?(:target, 'libone', '1.0.0', 1)).to eq(true)
  #   end
  # end

  # context "when two releases installed" do
  #   it "outputs about removing libtwo 1.1.0" do
  #     copy_formulas 'libone.rb', 'libtwo.rb'
  #     crew_checked 'install', 'libone:1.0.0'
  #     crew_checked 'install', 'libtwo:1.1.0'
  #     crew_checked 'install', 'libtwo:2.2.0'
  #     crew '-b', 'cleanup'
  #     expect(result).to eq(:ok)
  #     expect(out).to eq("removing: #{Global::HOLD_DIR}/libtwo/1.1.0\n" \
  #                       "removing: #{Global::PKG_CACHE_DIR}/#{archive_name(:target, 'libtwo', '1.1.0', 1)}\n")
  #     expect(in_cache?(:target, 'libone', '1.0.0', 1)).to eq(true)
  #     expect(in_cache?(:target, 'libtwo', '1.1.0', 1)).to eq(false)
  #     expect(in_cache?(:target, 'libtwo', '2.2.0', 1)).to eq(true)
  #   end
  # end

  # context "when two releases installed and -n specified" do
  #   it "outputs that would remove libtwo 1.1.0" do
  #     copy_formulas 'libone.rb', 'libtwo.rb'
  #     crew_checked 'install', 'libone:1.0.0'
  #     crew_checked 'install', 'libtwo:1.1.0'
  #     crew_checked 'install', 'libtwo:2.2.0'
  #     crew 'cleanup', '-n'
  #     expect(result).to eq(:ok)
  #     expect(out).to eq("would remove: #{Global::HOLD_DIR}/libtwo/1.1.0\n" \
  #                       "would remove: #{Global::PKG_CACHE_DIR}/#{archive_name(:target, 'libtwo', '1.1.0', 1)}\n")
  #     expect(in_cache?(:target, 'libone', '1.0.0', 1)).to eq(true)
  #     expect(in_cache?(:target, 'libtwo', '1.1.0', 1)).to eq(true)
  #     expect(in_cache?(:target, 'libtwo', '2.2.0', 1)).to eq(true)
  #   end
  # end

  # context "when three formulas has one release, two releases and three releases installed" do
  #   it "outputs about removing libtwo 1.1.0, libthree 1.1.1 and 2.2.2" do
  #     copy_formulas 'libone.rb', 'libtwo.rb', 'libthree.rb'
  #     crew_checked 'install', 'libone:1.0.0'
  #     crew_checked 'install', 'libtwo:1.1.0'
  #     crew_checked 'install', 'libtwo:2.2.0'
  #     crew_checked 'install', 'libthree:1.1.1'
  #     crew_checked 'install', 'libthree:2.2.2'
  #     crew_checked 'install', 'libthree:3.3.3'
  #     crew 'cleanup'
  #     expect(result).to eq(:ok)
  #     expect(out).to eq("removing: #{Global::HOLD_DIR}/libthree/1.1.1\n"       \
  #                       "removing: #{Global::HOLD_DIR}/libthree/2.2.2\n"       \
  #                       "removing: #{Global::HOLD_DIR}/libtwo/1.1.0\n"         \
  #                       "removing: #{Global::PKG_CACHE_DIR}/libthree-1.1.1_1.#{Global::ARCH_EXT}\n" \
  #                       "removing: #{Global::PKG_CACHE_DIR}/libthree-2.2.2_1.#{Global::ARCH_EXT}\n" \
  #                       "removing: #{Global::PKG_CACHE_DIR}/libtwo-1.1.0_1.#{Global::ARCH_EXT}\n")
  #     expect(in_cache?(:target, 'libone', '1.0.0', 1)).to eq(true)
  #     expect(in_cache?(:target, 'libtwo', '1.1.0', 1)).to eq(false)
  #     expect(in_cache?(:target, 'libtwo', '2.2.0', 1)).to eq(true)
  #     expect(in_cache?(:target, 'libthree', '1.1.1', 1)).to eq(false)
  #     expect(in_cache?(:target, 'libthree', '2.2.2', 1)).to eq(false)
  #     expect(in_cache?(:target, 'libthree', '3.3.3', 1)).to eq(true)
  #   end
  # end

  # context "when two releases of the curl utility are installed, releases differ in crystax_version" do
  #   it "outputs about removing old curl release" do
  #     repository_add_formula :host, 'curl-2.rb:curl.rb'
  #     crew_checked 'update'
  #     crew_checked 'upgrade'
  #     crew '-b', 'cleanup'
  #     curl_new_rel = Crew_test::UTILS_RELEASES['curl'][1]
  #     curl_old_rel = Crew_test::UTILS_RELEASES['curl'][0]
  #     expect(result).to eq(:ok)
  #     expect(out).to eq("removing: #{Global::UTILITIES_DIR}/curl/#{curl_old_rel}\n")
  #     expect(in_cache?(:host, 'curl', curl_new_rel.version, curl_new_rel.crystax_version)).to eq(true)
  #   end
  # end

  # context "when two releases of the curl utility are installed, releases differ in upstream version" do
  #   it "outputs about removing old curl release" do
  #     repository_add_formula :host, 'curl-3.rb:curl.rb'
  #     crew_checked 'update'
  #     crew_checked 'upgrade'
  #     crew '-b', 'cleanup'
  #     curl_new_rel = Crew_test::UTILS_RELEASES['curl'][2]
  #     curl_old_rel = Crew_test::UTILS_RELEASES['curl'][0]
  #     expect(result).to eq(:ok)
  #     expect(out).to eq("removing: #{Global::UTILITIES_DIR}/curl/#{curl_old_rel}\n")
  #     expect(in_cache?(:host, 'curl', curl_new_rel.version, curl_new_rel.crystax_version)).to eq(true)
  #   end
  # end

  # context "when two releases of the two utilities are installed" do
  #   it "says about removing two old releases" do
  #     repository_add_formula :host, 'curl-3.rb:curl.rb', 'ruby-2.rb:ruby.rb'
  #     crew_checked 'update'
  #     crew_checked 'upgrade'
  #     crew '-b', 'cleanup'
  #     curl_new_rel = Crew_test::UTILS_RELEASES['curl'][2]
  #     curl_old_rel = Crew_test::UTILS_RELEASES['curl'][0]
  #     ruby_new_rel = Crew_test::UTILS_RELEASES['ruby'][1]
  #     ruby_old_rel = Crew_test::UTILS_RELEASES['ruby'][0]
  #     expect(result).to eq(:ok)
  #     expect(out).to eq("removing: #{Global::UTILITIES_DIR}/curl/#{curl_old_rel}\n" \
  #                       "removing: #{Global::UTILITIES_DIR}/ruby/#{ruby_old_rel}\n")
  #     expect(in_cache?(:host, 'curl', curl_new_rel.version, curl_new_rel.crystax_version)).to eq(true)
  #     expect(in_cache?(:host, 'ruby', ruby_new_rel.version, ruby_new_rel.crystax_version)).to eq(true)
  #   end
  # end

  # context "when three releases of the curl utility are installed" do
  #   it "outputs about removing curl 7.42.0:3" do
  #     repository_add_formula :host, 'curl-2.rb:curl.rb'
  #     crew_checked 'update'
  #     crew_checked 'upgrade'
  #     repository_add_formula :host, 'curl-3.rb:curl.rb'
  #     crew_checked 'update'
  #     crew_checked 'upgrade'
  #     crew '-b', 'cleanup'
  #     curl_2_rel = Crew_test::UTILS_RELEASES['curl'][2]
  #     curl_1_rel = Crew_test::UTILS_RELEASES['curl'][1]
  #     curl_0_rel = Crew_test::UTILS_RELEASES['curl'][0]
  #     expect(result).to eq(:ok)
  #     expect(out).to eq("removing: #{Global::UTILITIES_DIR}/curl/#{curl_0_rel}\n" \
  #                       "removing: #{Global::UTILITIES_DIR}/curl/#{curl_1_rel}\n" \
  #                       "removing: #{Global::PKG_CACHE_DIR}/curl-#{curl_1_rel}-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}\n")
  #     expect(in_cache?(:host, 'curl', curl_2_rel.version, curl_2_rel.crystax_version)).to eq(true)
  #   end
  # end

  # context "when all utilities have more than one release installed" do
  #   it "says about removing old releases" do
  #     repository_clone
  #     repository_add_formula :host, 'curl-2.rb:curl.rb', 'libarchive-2.rb:libarchive.rb', 'ruby-2.rb:ruby.rb'
  #     crew_checked 'update'
  #     crew_checked 'upgrade'
  #     repository_add_formula :host, 'curl-3.rb:curl.rb'
  #     crew_checked 'update'
  #     crew_checked 'upgrade'
  #     crew 'cleanup'
  #     bsdtar_1_rel = Crew_test::UTILS_RELEASES['libarchive'][1]
  #     bsdtar_0_rel = Crew_test::UTILS_RELEASES['libarchive'][0]
  #     curl_2_rel = Crew_test::UTILS_RELEASES['curl'][2]
  #     curl_1_rel = Crew_test::UTILS_RELEASES['curl'][1]
  #     curl_0_rel = Crew_test::UTILS_RELEASES['curl'][0]
  #     ruby_1_rel = Crew_test::UTILS_RELEASES['ruby'][1]
  #     ruby_0_rel = Crew_test::UTILS_RELEASES['ruby'][0]
  #     expect(result).to eq(:ok)
  #     expect(out).to eq("removing: #{Global::UTILITIES_DIR}/curl/#{curl_0_rel}\n"         \
  #                       "removing: #{Global::UTILITIES_DIR}/curl/#{curl_1_rel}\n"         \
  #                       "removing: #{Global::UTILITIES_DIR}/libarchive/#{bsdtar_0_rel}\n" \
  #                       "removing: #{Global::UTILITIES_DIR}/ruby/#{ruby_0_rel}\n"         \
  #                       "removing: #{Global::PKG_CACHE_DIR}/curl-#{curl_1_rel}-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}\n")
  #     expect(in_cache?(:host, 'libarchive', bsdtar_1_rel.version, bsdtar_1_rel.crystax_version)).to eq(true)
  #     expect(in_cache?(:host, 'curl',       curl_2_rel.version,   curl_2_rel.crystax_version)).to   eq(true)
  #     expect(in_cache?(:host, 'ruby',       ruby_1_rel.version,   ruby_1_rel.crystax_version)).to   eq(true)
  #   end
  # end

  # context "when two releases of one library installed and two releases of the curl utility are installed" do
  #   it "outputs about removing libtwo 1.1.0 and removing old curl release" do
  #     copy_formulas 'libone.rb', 'libtwo.rb'
  #     crew_checked 'install', 'libone:1.0.0'
  #     crew_checked 'install', 'libtwo:1.1.0'
  #     crew_checked 'install', 'libtwo:2.2.0'
  #     repository_add_formula :host, 'curl-3.rb:curl.rb'
  #     crew_checked 'update'
  #     crew_checked 'upgrade'
  #     crew '-b', 'cleanup'
  #     curl_2_rel = Crew_test::UTILS_RELEASES['curl'][2]
  #     curl_0_rel = Crew_test::UTILS_RELEASES['curl'][0]
  #     expect(result).to eq(:ok)
  #     expect(out.split("\n")).to eq(["removing: #{Global::UTILITIES_DIR}/curl/#{curl_0_rel}",
  #                                    "removing: #{Global::HOLD_DIR}/libtwo/1.1.0",
  #                                    "removing: #{Global::PKG_CACHE_DIR}/#{archive_name(:target, 'libtwo', '1.1.0', 1)}"
  #                                   ])
  #     expect(in_cache?(:host, 'curl', curl_2_rel.version, curl_2_rel.crystax_version)).to eq(true)
  #     expect(in_cache?(:target, 'libone', '1.0.0', 1)).to eq(true)
  #     expect(in_cache?(:target, 'libtwo', '1.1.0', 1)).to eq(false)
  #     expect(in_cache?(:target, 'libtwo', '2.2.0', 1)).to eq(true)
  #   end
  # end

  # context "when all utilities and all libraries have more than one release installed" do
  #   it "says about removing old releases" do
  #     repository_clone
  #     repository_add_formula :host, 'curl-2.rb:curl.rb', 'libarchive-2.rb:libarchive.rb', 'ruby-2.rb:ruby.rb'
  #     crew_checked 'update'
  #     crew_checked 'upgrade'
  #     repository_add_formula :host, 'curl-3.rb:curl.rb'
  #     crew_checked 'update'
  #     crew_checked 'upgrade'
  #     copy_formulas 'libone.rb', 'libtwo.rb', 'libthree.rb'
  #     crew_checked 'install', 'libone:1.0.0'
  #     crew_checked 'install', 'libtwo:1.1.0'
  #     crew_checked 'install', 'libtwo:2.2.0'
  #     crew_checked 'install', 'libthree:1.1.1'
  #     crew_checked 'install', 'libthree:2.2.2'
  #     crew_checked 'install', 'libthree:3.3.3'
  #     crew 'cleanup'
  #     bsdtar_1_rel = Crew_test::UTILS_RELEASES['libarchive'][1]
  #     bsdtar_0_rel = Crew_test::UTILS_RELEASES['libarchive'][0]
  #     curl_2_rel = Crew_test::UTILS_RELEASES['curl'][2]
  #     curl_1_rel = Crew_test::UTILS_RELEASES['curl'][1]
  #     curl_0_rel = Crew_test::UTILS_RELEASES['curl'][0]
  #     ruby_1_rel = Crew_test::UTILS_RELEASES['ruby'][1]
  #     ruby_0_rel = Crew_test::UTILS_RELEASES['ruby'][0]
  #     expect(result).to eq(:ok)
  #     expect(out.split("\n")).to eq(["removing: #{Global::UTILITIES_DIR}/curl/#{curl_0_rel}",
  #                                    "removing: #{Global::UTILITIES_DIR}/curl/#{curl_1_rel}",
  #                                    "removing: #{Global::UTILITIES_DIR}/libarchive/#{bsdtar_0_rel}",
  #                                    "removing: #{Global::UTILITIES_DIR}/ruby/#{ruby_0_rel}",
  #                                    "removing: #{Global::HOLD_DIR}/libthree/1.1.1",
  #                                    "removing: #{Global::HOLD_DIR}/libthree/2.2.2",
  #                                    "removing: #{Global::HOLD_DIR}/libtwo/1.1.0",
  #                                    "removing: #{Global::PKG_CACHE_DIR}/curl-#{curl_1_rel}-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}",
  #                                    "removing: #{Global::PKG_CACHE_DIR}/libthree-1.1.1_1.#{Global::ARCH_EXT}",
  #                                    "removing: #{Global::PKG_CACHE_DIR}/libthree-2.2.2_1.#{Global::ARCH_EXT}",
  #                                    "removing: #{Global::PKG_CACHE_DIR}/libtwo-1.1.0_1.#{Global::ARCH_EXT}"
  #                                   ])
  #     expect(in_cache?(:host, 'libarchive', bsdtar_1_rel.version, bsdtar_1_rel.crystax_version)).to eq(true)
  #     expect(in_cache?(:host, 'curl',       curl_2_rel.version,   curl_2_rel.crystax_version)).to   eq(true)
  #     expect(in_cache?(:host, 'ruby',       ruby_1_rel.version,   ruby_1_rel.crystax_version)).to   eq(true)
  #     expect(in_cache?(:target, 'libone',     '1.0.0',  1)).to eq(true)
  #     expect(in_cache?(:target, 'libtwo',     '1.1.0',  1)).to eq(false)
  #     expect(in_cache?(:target, 'libtwo',     '2.2.0',  1)).to eq(true)
  #     expect(in_cache?(:target, 'libthree',   '1.1.1',  1)).to eq(false)
  #     expect(in_cache?(:target, 'libthree',   '2.2.2',  1)).to eq(false)
  #     expect(in_cache?(:target, 'libthree',   '3.3.3',  1)).to eq(true)
  #   end
  # end
end
