#!/usr/bin/env swift
import Foundation

print("--- ClipShot: Screenshot History LRU Thumbnail Buffer Eviction Simulator ---")

final class LRUCache<Key: Hashable, Value> {
    private final class Node {
        let key: Key
        var value: Value
        var cost: Int
        var prev: Node?
        var next: Node?

        init(key: Key, value: Value, cost: Int) {
            self.key = key
            self.value = value
            self.cost = cost
        }
    }

    private let maxCount: Int
    private let maxCost: Int
    private var totalCost: Int = 0
    private var dict: [Key: Node] = [:]
    private var head: Node?
    private var tail: Node?

    var hits: Int = 0
    var misses: Int = 0
    var evictions: Int = 0

    init(maxCount: Int, maxCost: Int) {
        self.maxCount = maxCount
        self.maxCost = maxCost
    }

    var currentCount: Int {
        return dict.count
    }

    var currentCostBytes: Int {
        return totalCost
    }

    func get(_ key: Key) -> Value? {
        guard let node = dict[key] else {
            misses += 1
            return nil
        }
        hits += 1
        moveToHead(node)
        return node.value
    }

    func set(_ key: Key, value: Value, cost: Int) {
        if let node = dict[key] {
            totalCost -= node.cost
            node.value = value
            node.cost = cost
            totalCost += cost
            moveToHead(node)
        } else {
            let newNode = Node(key: key, value: value, cost: cost)
            dict[key] = newNode
            totalCost += cost
            insertAtHead(newNode)
        }

        prune()
    }

    private func moveToHead(_ node: Node) {
        guard node !== head else { return }
        removeNode(node)
        insertAtHead(node)
    }

    private func insertAtHead(_ node: Node) {
        node.next = head
        node.prev = nil
        head?.prev = node
        head = node
        if tail == nil {
            tail = node
        }
    }

    private func removeNode(_ node: Node) {
        if node === head {
            head = node.next
        }
        if node === tail {
            tail = node.prev
        }
        node.prev?.next = node.next
        node.next?.prev = node.prev
    }

    private func prune() {
        while dict.count > maxCount || totalCost > maxCost {
            guard let oldest = tail else { break }
            dict.removeValue(forKey: oldest.key)
            totalCost -= oldest.cost
            removeNode(oldest)
            evictions += 1
        }
    }
}

// Simulate caching thumbnail bitmaps of various sizes
struct ScreenshotThumbnail {
    let filename: String
    let width: Int
    let height: Int
    var byteSize: Int { width * height * 4 } // 32-bit RGBA
}

let cache = LRUCache<String, ScreenshotThumbnail>(maxCount: 5, maxCost: 15 * 1024 * 1024) // Max 5 items, max 15 MB

let testImages: [ScreenshotThumbnail] = [
    ScreenshotThumbnail(filename: "shot_01.png", width: 1024, height: 768),   // ~3.15 MB
    ScreenshotThumbnail(filename: "shot_02.png", width: 1024, height: 768),   // ~3.15 MB
    ScreenshotThumbnail(filename: "shot_03.png", width: 1280, height: 800),   // ~4.10 MB
    ScreenshotThumbnail(filename: "shot_04.png", width: 1440, height: 900),   // ~5.18 MB
    ScreenshotThumbnail(filename: "shot_05.png", width: 1024, height: 768),   // ~3.15 MB
    ScreenshotThumbnail(filename: "shot_06.png", width: 1920, height: 1080),  // ~8.29 MB (large)
    ScreenshotThumbnail(filename: "shot_07.png", width: 800, height: 600)     // ~1.92 MB
]

print("Simulating sequence of screenshot captures and clipboard accesses...\n")

for (idx, img) in testImages.enumerated() {
    let mb = Double(img.byteSize) / (1024.0 * 1024.0)
    print("[\(idx + 1)] Ingesting '\(img.filename)' (\(String(format: "%.2f", mb)) MB)...")
    cache.set(img.filename, value: img, cost: img.byteSize)
    let totalMB = Double(cache.currentCostBytes) / (1024.0 * 1024.0)
    print("    Cache status: \(cache.currentCount) items, \(String(format: "%.2f", totalMB)) MB total, \(cache.evictions) cumulative evictions")
}

print("\n--- Access Simulation (Testing Hits vs Misses) ---")
let accessKeys = ["shot_07.png", "shot_01.png", "shot_06.png", "shot_02.png", "shot_05.png"]

for key in accessKeys {
    if let found = cache.get(key) {
        print("  ✓ HIT: '\(key)' (\(found.width)x\(found.height)) retrieved from cache")
    } else {
        print("  ✗ MISS: '\(key)' was evicted; reloading from disk required")
    }
}

print("\n--- Summary Statistics ---")
print("Total Hits:      \(cache.hits)")
print("Total Misses:    \(cache.misses)")
print("Total Evictions: \(cache.evictions)")
let hitRate = Double(cache.hits) / Double(cache.hits + cache.misses) * 100.0
print("Hit Rate:        \(String(format: "%.1f", hitRate))%")

print("\nArchitectural Rationale: Dual-constraint (count + byte cost) LRU eviction guarantees responsive notch thumbnail previews while keeping memory footprint bounded under 15 MB.")
