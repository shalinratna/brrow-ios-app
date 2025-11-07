# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

target 'Brrow' do
  # Optimized for M4 Pro Max parallel building
  use_frameworks!
  use_modular_headers!

  # Pods for Brrow
  pod 'Socket.IO-Client-Swift', '~> 16.1.0'
  pod 'StripePaymentSheet', '~> 25.0'
  pod 'FirebaseMessaging'
  pod 'FirebaseAuth'
  pod 'GoogleSignIn'
  pod 'FBSDKLoginKit'
  pod 'Alamofire', '~> 5.8'
  pod 'SDWebImage', '~> 5.18'

  target 'BrrowTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'BrrowUITests' do
    # Pods for testing
  end
end

# Note: BrrowWidgetsExtension target removed - no pods needed for widgets

post_install do |installer|
  # FIX ARCHITECTURE SETTINGS FOR ALL TARGETS
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'

      # ✅ CRITICAL FIX: Set explicit architecture for Release builds
      config.build_settings['ARCHS'] = 'arm64'
      config.build_settings['VALID_ARCHS'] = 'arm64'

      # ✅ CRITICAL: Build Active Architecture Only = NO for Release
      if config.name == 'Release'
        config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
      else
        config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
      end

      # ✅ FIX: Ensure pods don't interfere with archiving
      config.build_settings['SKIP_INSTALL'] = 'YES'

      # 🚀 M4 PRO MAX SPEED OPTIMIZATIONS
      if config.name == 'Debug'
        # Debug builds: MAXIMUM SPEED
        config.build_settings['SWIFT_COMPILATION_MODE'] = 'Incremental'
        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
        config.build_settings['COMPILER_INDEX_STORE_ENABLE'] = 'NO'
        config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'
        # Enable maximum parallel compilation
        config.build_settings['SWIFT_ENABLE_BATCH_MODE'] = 'YES'
        config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '0'
      else
        # Release builds: PERFORMANCE
        config.build_settings['SWIFT_COMPILATION_MODE'] = 'wholemodule'
        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-O'
      end

      # Universal optimizations for M4 Pro Max
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['VALIDATES_PRODUCT'] = 'NO'
      config.build_settings['CLANG_ENABLE_MODULE_DEBUGGING'] = 'NO'
    end

    # Alamofire privacy manifest fix: Allow privacy manifest to be included
    # DO NOT exclude files - privacy manifest must be included for App Store
    if target.name == 'Alamofire'
      target.build_configurations.each do |config|
        # Ensure privacy manifest is included as a resource
        config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = nil if config.build_settings['PRODUCT_BUNDLE_IDENTIFIER']
      end
    end
  end

  # ✅ CRITICAL: Also update the main project targets
  installer.aggregate_targets.each do |aggregate_target|
    aggregate_target.xcconfigs.each do |config_name, config_file|
      xcconfig_path = aggregate_target.xcconfig_path(config_name)
      if File.exist?(xcconfig_path)
        config_content = File.read(xcconfig_path)

        # Ensure ARCHS is set
        unless config_content.include?('ARCHS')
          config_content += "\nARCHS = arm64\n"
        end

        # Ensure VALID_ARCHS is set
        unless config_content.include?('VALID_ARCHS')
          config_content += "\nVALID_ARCHS = arm64\n"
        end

        # Set ONLY_ACTIVE_ARCH based on configuration
        if config_name.to_s.downcase.include?('release')
          config_content.gsub!(/ONLY_ACTIVE_ARCH = .*/, 'ONLY_ACTIVE_ARCH = NO')
          unless config_content.include?('ONLY_ACTIVE_ARCH')
            config_content += "\nONLY_ACTIVE_ARCH = NO\n"
          end
        end

        File.write(xcconfig_path, config_content)
      end
    end
  end

  # Replace rsync with cp in the embed frameworks script to fix archive issues
  embed_script_path = "#{installer.sandbox.root}/Target Support Files/Pods-Brrow/Pods-Brrow-frameworks.sh"
  if File.exist?(embed_script_path)
    script_content = File.read(embed_script_path)
    # Replace all rsync commands with cp to avoid sandbox permission issues
    script_content.gsub!('rsync --delete -av "${RSYNC_PROTECT_TMP_FILES[@]}" --links --filter "- CVS/" --filter "- .svn/" --filter "- .git/" --filter "- .hg/" --filter "- Headers" --filter "- PrivateHeaders" --filter "- Modules" "${source}" "${destination}"',
                        'rm -rf "${destination}/$(basename "${source}")" 2>/dev/null; cp -R "${source}" "${destination}/"')
    script_content.gsub!('rsync -auv "${SWIFT_STDLIB_PATH}/${lib}" "${destination}"',
                        'cp -R "${SWIFT_STDLIB_PATH}/${lib}" "${destination}/"')
    script_content.gsub!('rsync --delete -av "${RSYNC_PROTECT_TMP_FILES[@]}" --filter "- CVS/" --filter "- .svn/" --filter "- .git/" --filter "- .hg/" --filter "- Headers" --filter "- PrivateHeaders" --filter "- Modules" "${source}" "${DERIVED_FILES_DIR}"',
                        'rm -rf "${DERIVED_FILES_DIR}/$(basename "${source}")" 2>/dev/null; cp -R "${source}" "${DERIVED_FILES_DIR}/"')
    script_content.gsub!('rsync --delete -av "${RSYNC_PROTECT_TMP_FILES[@]}" --links --filter "- CVS/" --filter "- .svn/" --filter "- .git/" --filter "- .hg/" --filter "- Headers" --filter "- PrivateHeaders" --filter "- Modules" "${DERIVED_FILES_DIR}/${basename}.dSYM" "${DWARF_DSYM_FOLDER_PATH}"',
                        'rm -rf "${DWARF_DSYM_FOLDER_PATH}/${basename}.dSYM" 2>/dev/null; cp -R "${DERIVED_FILES_DIR}/${basename}.dSYM" "${DWARF_DSYM_FOLDER_PATH}/"')
    script_content.gsub!('rsync --delete -av "${RSYNC_PROTECT_TMP_FILES[@]}" --filter "- CVS/" --filter "- .svn/" --filter "- .git/" --filter "- .hg/" --filter "- Headers" --filter "- PrivateHeaders" --filter "- Modules" "${bcsymbolmap_path}" "${destination}"',
                        'cp -R "${bcsymbolmap_path}" "${destination}/"')
    File.write(embed_script_path, script_content)
  end

  # DO NOT remove Alamofire files - privacy manifest must be preserved for App Store
  # Privacy manifests are required by Apple for third-party SDKs (ITMS-91061)
end
