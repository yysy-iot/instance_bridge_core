#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint darwin/instance_bridge_core.podspec` to validate before publishing.
#
# sharedDarwinSource：iOS 与 macOS 共用本目录下的同一份源码与 podspec。
  # 注意：source_files 与 license file 必须位于 pod root（darwin/）内且为物理文件；
  # CocoaPods 用 Dir.glob('**/*') 预收集文件，`**` 不跟随符号链接目录；
  # trunk push 单独处理 spec，'../LICENSE' 这类跳出 pod root 的相对路径无法解析，
  # 故在 darwin/ 下放 LICENSE 物理副本（与根目录 LICENSE 保持一致）。
Pod::Spec.new do |s|
  s.name             = 'instance_bridge_core'
  s.version          = '0.0.14'
  s.summary          = 'Flutter plugin bridge.'
  s.description      = <<-DESC
A plugin bridge for managing instances.
                       DESC
  s.homepage         = 'https://github.com/yysy-iot'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'YueYing Industry' => 'charlie@yueying-industry.com' }

  s.source           = { :git => 'https://github.com/yysy-iot/instance_bridge_core.git', :tag => s.version.to_s }

  s.source_files = 'instance_bridge_core/Sources/instance_bridge_core/**/*', 'instance_bridge_core/Sources/instance_bridge_core_objc/**/*'
  s.public_header_files = 'instance_bridge_core/Sources/instance_bridge_core_objc/include/**/*.h'
  # ✅ 平台设置（podspec 平台无关，iOS/macOS 均声明）
  s.ios.deployment_target  = '13.0'
  s.osx.deployment_target  = '10.15'
  # ✅ 依赖
  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'

  # Flutter.framework does not contain a i386 slice.
  s.ios.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.osx.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  # ✅ Swift 支持
  s.swift_version = '5.0'
end
