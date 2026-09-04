import XCTest
import simd
@testable import DogCompanion

final class CompanionMeshDeformTests: XCTestCase {
    func testBellyMaskIsLocalToTheTorso() {
        XCTAssertLessThan(CompanionMeshDeform.bellyWeight(u: 0.5, v: 0.12), 0.05)
        XCTAssertGreaterThan(CompanionMeshDeform.bellyWeight(u: 0.5, v: 0.62), 0.4)
        XCTAssertLessThan(CompanionMeshDeform.bellyWeight(u: 0.08, v: 0.62), 0.05)
    }

    func testTailMaskIsLocalToTheLowerSides() {
        XCTAssertGreaterThan(CompanionMeshDeform.tailWeight(u: 0.1, v: 0.78), 0.2)
        XCTAssertGreaterThan(CompanionMeshDeform.tailWeight(u: 0.9, v: 0.78), 0.2)
        XCTAssertLessThan(CompanionMeshDeform.tailWeight(u: 0.5, v: 0.2), 0.05)
    }

    func testIdleWarpLoopsWithSineTime() {
        let uv = SIMD2<Float>(0.5, 0.62)
        let origin = SIMD2<Float>(0, 0)
        let a = CompanionMeshDeform.displaced(position: origin, uv: uv, time: 0, enabled: 1)
        let b = CompanionMeshDeform.displaced(position: origin, uv: uv, time: 1.0, enabled: 1)
        XCTAssertGreaterThan(simd_distance(a, b), 0.002)

        let breathPeriod = Float.pi * 2 / CompanionMeshDeform.breathFrequency
        let looped = CompanionMeshDeform.displaced(position: origin, uv: uv, time: breathPeriod, enabled: 1)
        XCTAssertEqual(a.y, looped.y, accuracy: 0.0001)
    }

    func testWarpStopsWhenDisabled() {
        let uv = SIMD2<Float>(0.5, 0.62)
        let origin = SIMD2<Float>(0.1, -0.2)
        let warped = CompanionMeshDeform.displaced(position: origin, uv: uv, time: 0.8, enabled: 0)
        XCTAssertEqual(warped.x, origin.x, accuracy: 0.0001)
        XCTAssertEqual(warped.y, origin.y, accuracy: 0.0001)
    }

    func testHeadVerticesBarelyMove() {
        let uv = SIMD2<Float>(0.5, 0.12)
        let origin = SIMD2<Float>(0, 0.7)
        let warped = CompanionMeshDeform.displaced(position: origin, uv: uv, time: 0.9, enabled: 1)
        XCTAssertLessThan(simd_distance(origin, warped), 0.004)
    }
}
