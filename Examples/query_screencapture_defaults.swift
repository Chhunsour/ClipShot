#!/usr/bin/env swift
import Foundation

print("--- ClipShot: Query macOS screencapture Preferences ---")

let domain = "com.apple.screencapture" as CFString

// 1. Screenshot output location
if let location = CFPreferencesCopyAppValue("location" as CFString, domain) as? String {
    print("Default save location: \(location)")
} else {
    print("Default save location: ~/Desktop (System default)")
}

// 2. Screenshot format type (e.g. png, jpg, heic)
if let type = CFPreferencesCopyAppValue("type" as CFString, domain) as? String {
    print("Default image format:  \(type)")
} else {
    print("Default image format:  png (System default)")
}

// 3. Window shadow preference
if let disableShadow = CFPreferencesCopyAppValue("disable-shadow" as CFString, domain) as? Bool {
    print("Window shadows disabled: \(disableShadow)")
} else {
    print("Window shadows:        Enabled (System default)")
}

// 4. Floating thumbnail preference (macOS Mojave+)
if let showThumbnail = CFPreferencesCopyAppValue("show-thumbnail" as CFString, domain) as? Bool {
    print("System floating thumbnail: \(showThumbnail)")
} else {
    print("System floating thumbnail: Enabled (System default)")
}
