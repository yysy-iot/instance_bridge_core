# instance_bridge_core

Shared core code (Objective-C/C++) for Flutter plugin bridge.  
Designed to be reused by both iOS and macOS Flutter plugins.

## Features

- Shared C++/Objective-C logic
- Used by `get_instance_bridge`
- Can be integrated via CocoaPods

## Installation

In your plugin `.podspec`:

```ruby
s.dependency 'instance_bridge_core'