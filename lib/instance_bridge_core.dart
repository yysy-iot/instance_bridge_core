/// instance_bridge_core 是纯原生共享库（iOS/macOS Swift），无 Dart API。
///
/// 此文件仅用于满足 Dart package 规范（pub 包必须有 lib/ 目录），
/// 不提供任何可用的 Dart 接口。原生能力通过宿主插件
/// `get_instance_bridge` 的 MethodChannel（通道名 "MixInstances"）暴露。
library;
