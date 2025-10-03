# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

target 'Brrow' do
  # Optimized for M4 Pro Max parallel building
  use_frameworks!
  use_modular_headers!

  # Pods for Brrow
  pod 'Socket.IO-Client-Swift', '~> 16.1.0'
  pod 'StripePaymentSheet', '~> 23.0'
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
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'

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
    
    # Fix Alamofire bundle issue
    if target.name == 'Alamofire'
      target.build_configurations.each do |config|
        config.build_settings['EXCLUDED_SOURCE_FILE_NAMES'] = '*.bundle'
        config.build_settings.delete('PRODUCT_BUNDLE_IDENTIFIER')
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
  
  # Remove problematic Alamofire bundle files
  require 'fileutils'
  FileUtils.rm_rf(Dir.glob("#{installer.sandbox.root}/Alamofire/**/*.bundle"))
end