#!/bin/bash

# Workaround for rsync permission issues
# This script copies frameworks using cp instead of rsync

if [ -z ${FRAMEWORKS_FOLDER_PATH+x} ]; then
  exit 0
fi

echo "📦 Embedding frameworks with cp workaround..."

CONFIGURATION_BUILD_DIR="${CONFIGURATION_BUILD_DIR:-/Users/shalin/Library/Developer/Xcode/DerivedData/Brrow-gsfyebdnxhgmddbckbyaoqwnjvum/Build/Products/Debug-iphoneos}"
FRAMEWORKS_FOLDER_PATH="${FRAMEWORKS_FOLDER_PATH:-Brrow.app/Frameworks}"
BUILT_PRODUCTS_DIR="${BUILT_PRODUCTS_DIR:-/Users/shalin/Library/Developer/Xcode/DerivedData/Brrow-gsfyebdnxhgmddbckbyaoqwnjvum/Build/Products/Debug-iphoneos}"

mkdir -p "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"

# List of frameworks to copy
frameworks=(
  "Alamofire.framework"
  "AppAuth.framework"
  "AppCheckCore.framework"
  "FBLPromises.framework"
  "FirebaseAppCheckInterop.framework"
  "FirebaseAuth.framework"
  "FirebaseAuthInterop.framework"
  "FirebaseCore.framework"
  "FirebaseCoreExtension.framework"
  "FirebaseCoreInternal.framework"
  "FirebaseInstallations.framework"
  "FirebaseMessaging.framework"
  "GTMAppAuth.framework"
  "GTMSessionFetcher.framework"
  "GoogleDataTransport.framework"
  "GoogleSignIn.framework"
  "GoogleUtilities.framework"
  "RecaptchaInterop.framework"
  "SDWebImage.framework"
  "SocketIO.framework"
  "Starscream.framework"
  "StripeApplePay.framework"
  "StripeCore.framework"
  "StripePaymentSheet.framework"
  "StripePayments.framework"
  "StripePaymentsUI.framework"
  "StripeUICore.framework"
  "nanopb.framework"
)

for framework in "${frameworks[@]}"; do
  source="${BUILT_PRODUCTS_DIR}/${framework}"
  destination="${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
  
  if [ -d "${source}" ]; then
    echo "Copying ${framework}..."
    rm -rf "${destination}/${framework}"
    cp -R "${source}" "${destination}/"
  fi
done

echo "✅ Frameworks embedded successfully!"
