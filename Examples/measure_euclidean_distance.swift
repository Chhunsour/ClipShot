#!/usr/bin/env swift
import Foundation
import CoreGraphics

print("--- ClipShot: Pixel Measurement & Snapping Algorithm ---")

func distance(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
    let dx = p2.x - p1.x
    let dy = p2.y - p1.y
    return sqrt(dx * dx + dy * dy)
}

func formatDistance(from p1: CGPoint, to p2: CGPoint) -> String {
    let dist = Int(round(distance(from: p1, to: p2)))
    let dx = Int(round(abs(p2.x - p1.x)))
    let dy = Int(round(abs(p2.y - p1.y)))

    if dx == 0 { return "\(dy) px (Vertical)" }
    if dy == 0 { return "\(dx) px (Horizontal)" }
    return "\(dist) px (Δx: \(dx), Δy: \(dy))"
}

// 1. Horizontal measurement
let start = CGPoint(x: 100, y: 200)
let horizontalEnd = CGPoint(x: 450, y: 200)
print("Horizontal: \(formatDistance(from: start, to: horizontalEnd))")

// 2. Vertical measurement
let verticalEnd = CGPoint(x: 100, y: 550)
print("Vertical:   \(formatDistance(from: start, to: verticalEnd))")

// 3. Diagonal measurement
let diagonalEnd = CGPoint(x: 400, y: 600)
print("Diagonal:   \(formatDistance(from: start, to: diagonalEnd))")

// 4. Bounding box dimension formatting
let selectionRect = CGRect(x: 100, y: 150, width: 1280, height: 720)
print("Selection:  \(Int(selectionRect.width)) × \(Int(selectionRect.height)) px")
