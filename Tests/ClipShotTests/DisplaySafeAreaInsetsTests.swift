import AppKit
import CoreGraphics
import XCTest
@testable import ClipShotCore

final class DisplaySafeAreaInsetsTests: XCTestCase {
    struct MockGeometryCalculator {
        static func computeOrigin(
            screenFrame: CGRect,
            visibleFrame: CGRect,
            size: CGSize,
            placementMode: ClipNotchPlacementMode,
            verticalOffset: Double = 0.0
        ) -> CGPoint {
            let originX = screenFrame.midX - (size.width / 2.0)
            let originY: CGFloat

            switch placementMode {
            case .topHeader:
                originY = screenFrame.maxY - size.height - CGFloat(verticalOffset)
            case .belowMenuBar:
                originY = visibleFrame.maxY - size.height - CGFloat(verticalOffset)
            case .floatingIsland:
                originY = screenFrame.maxY - size.height - 6.0 - CGFloat(verticalOffset)
            }

            return CGPoint(x: originX, y: originY)
        }
    }

    func testTopHeaderOriginIsFlushWithScreenTop() {
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let visible = CGRect(x: 0, y: 0, width: 1920, height: 1056) // 24pt menu bar
        let size = CGSize(width: 200, height: 40)

        let origin = MockGeometryCalculator.computeOrigin(
            screenFrame: screen,
            visibleFrame: visible,
            size: size,
            placementMode: .topHeader,
            verticalOffset: 0.0
        )

        XCTAssertEqual(origin.x, (1920 - 200) / 2.0)
        XCTAssertEqual(origin.y, 1080 - 40)
    }

    func testBelowMenuBarOriginRespectsMenuBarHeight() {
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let visible = CGRect(x: 0, y: 0, width: 1920, height: 1056) // 24pt menu bar
        let size = CGSize(width: 200, height: 40)

        let origin = MockGeometryCalculator.computeOrigin(
            screenFrame: screen,
            visibleFrame: visible,
            size: size,
            placementMode: .belowMenuBar,
            verticalOffset: 0.0
        )

        XCTAssertEqual(origin.x, (1920 - 200) / 2.0)
        XCTAssertEqual(origin.y, 1056 - 40)
        XCTAssertEqual(screen.maxY - (origin.y + size.height), 24.0) // Exactly 24pt below top edge
    }

    func testFloatingIslandIncludesSixPointGap() {
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let visible = CGRect(x: 0, y: 0, width: 1920, height: 1056)
        let size = CGSize(width: 200, height: 40)

        let origin = MockGeometryCalculator.computeOrigin(
            screenFrame: screen,
            visibleFrame: visible,
            size: size,
            placementMode: .floatingIsland,
            verticalOffset: 0.0
        )

        XCTAssertEqual(origin.x, (1920 - 200) / 2.0)
        XCTAssertEqual(origin.y, 1080 - 40 - 6.0)
        XCTAssertEqual(screen.maxY - (origin.y + size.height), 6.0)
    }

    func testVerticalOffsetTranslatesDownward() {
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let visible = screen
        let size = CGSize(width: 200, height: 40)

        let baseOrigin = MockGeometryCalculator.computeOrigin(
            screenFrame: screen,
            visibleFrame: visible,
            size: size,
            placementMode: .topHeader,
            verticalOffset: 0.0
        )

        let offsetOrigin = MockGeometryCalculator.computeOrigin(
            screenFrame: screen,
            visibleFrame: visible,
            size: size,
            placementMode: .topHeader,
            verticalOffset: 12.0
        )

        XCTAssertEqual(baseOrigin.y - offsetOrigin.y, 12.0)
    }
}
