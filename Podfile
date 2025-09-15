# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

target 'Brrow' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

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

target 'BrrowWidgetsExtension' do
  use_frameworks!
  # Pods for BrrowWidgetsExtension
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
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