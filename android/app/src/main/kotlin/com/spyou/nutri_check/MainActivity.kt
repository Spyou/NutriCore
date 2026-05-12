package com.spyou.nutri_check

import io.flutter.embedding.android.FlutterFragmentActivity

// `FlutterFragmentActivity` (not `FlutterActivity`) is required by the
// `health` plugin so it can register an ActivityResultCallback for the
// Health Connect permission launcher. Without this base, the plugin
// throws "Permission launcher not found" when requesting permissions.
class MainActivity : FlutterFragmentActivity()
