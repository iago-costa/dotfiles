{ pkgs ? import <nixpkgs> {
  config.android_sdk.accept_license = true;
  config.android_sdk.accept_android_sdk_licenses = true;
  config.allowUnfree = true;
},
unstable ? import <nixos> {
  config.android_sdk.accept_license = true;
  config.android_sdk.accept_android_sdk_licenses = true;
  config.allowUnfree = true;
} }:
let
  buildToolsVersion = "33.0.2";
  androidenv = pkgs.androidenv.override {
    licenseAccepted = true;
  };
  androidComposition = androidenv.composeAndroidPackages {
    includeNDK = false;
    includeSystemImages = true;
    includeEmulator = true;
    platformVersions = [ "33" "34" ];
    buildToolsVersions = [ buildToolsVersion "30.0.3" ];
    abiVersions = [ "x86_64" ];
    extraLicenses = [
      "android-googletv-license"
      "android-sdk-arm-dbt-license"        
      "android-sdk-license"
      "android-sdk-preview-license"
      "google-gdk-license"
      "intel-android-extra-license"
      "intel-android-sysimage-license"
      "mips-android-sysimage-license"
    ];
  };
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    # xcbuild
    # darwin.xcode_16_1
    androidComposition.androidsdk
    androidComposition.ndk-bundle
    glibc
    unstable.flutter324
    dart
    google-chrome
    jdk17
  ];
  shellHook = ''
  zsh
  '';
  JAVA_HOME=pkgs.jdk17.home;
  ANDROID_JAVA_HOME=pkgs.jdk.home;
  FLUTTER_PATH = "${pkgs.flutter}/bin";
  DART_PATH = "${pkgs.dart}/bin";
  ANDROID_SDK_ROOT = "${androidComposition.androidsdk}/libexec/android-sdk";
  ANDROID_NDK_ROOT = "${androidComposition.androidsdk}/libexec/android-sdk/ndk-bundle";
  # Use the same buildToolsVersion here
  GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidComposition.androidsdk}/libexec/android-sdk/build-tools/${buildToolsVersion}/aapt2";
  CHROME_EXECUTABLE = "${pkgs.google-chrome}/bin/google-chrome-stable";
}

