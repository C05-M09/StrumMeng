//
//  UserDefaultsSettingsStoreTests.swift
//  StrumMeng
//
//  Created by rasyel on 27/10/26.
//


import XCTest
@testable import StrumMeng

@MainActor
final class UserDefaultsSettingsStoreTests: XCTestCase {
    private var suiteName = ""
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "settings-tests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func test_init_withNothingSaved_usesTheDefaultVolume() {
        let store = UserDefaultsSettingsStore(defaults: defaults)

        XCTAssertEqual(store.soundVolume, VolumeConfig.defaultVolume)
        XCTAssertEqual(store.sfxVolume, VolumeConfig.defaultVolume)
    }

    func test_setSoundVolume_updatesTheValue() {
        let store = UserDefaultsSettingsStore(defaults: defaults)

        store.setSoundVolume(0.8)

        XCTAssertEqual(store.soundVolume, 0.8)
        XCTAssertEqual(store.sfxVolume, VolumeConfig.defaultVolume)
    }

    func test_setSFXVolume_updatesTheValue() {
        let store = UserDefaultsSettingsStore(defaults: defaults)

        store.setSFXVolume(0.2)

        XCTAssertEqual(store.sfxVolume, 0.2)
        XCTAssertEqual(store.soundVolume, VolumeConfig.defaultVolume)
    }

    func test_values_surviveCreatingANewStore() {
        let first = UserDefaultsSettingsStore(defaults: defaults)
        first.setSoundVolume(0.3)
        first.setSFXVolume(0.9)

        let second = UserDefaultsSettingsStore(defaults: defaults)

        XCTAssertEqual(second.soundVolume, 0.3)
        XCTAssertEqual(second.sfxVolume, 0.9)
    }

    func test_setVolume_clampsToTheRange() {
        let store = UserDefaultsSettingsStore(defaults: defaults)

        store.setSoundVolume(5)
        store.setSFXVolume(-1)

        XCTAssertEqual(store.soundVolume, 1)
        XCTAssertEqual(store.sfxVolume, 0)
    }

    func test_init_clampsAnOutOfRangeSavedValue() {
        defaults.set(7.0, forKey: UserDefaultsSettingsStore.Key.soundVolume)
        defaults.set(-3.0, forKey: UserDefaultsSettingsStore.Key.sfxVolume)

        let store = UserDefaultsSettingsStore(defaults: defaults)

        XCTAssertEqual(store.soundVolume, 1)
        XCTAssertEqual(store.sfxVolume, 0)
    }

    func test_volumeConfig_nonNumberFallsBackToTheDefault() {
        XCTAssertEqual(VolumeConfig.clamped(.nan), VolumeConfig.defaultVolume)
        XCTAssertEqual(VolumeConfig.clamped(.infinity), VolumeConfig.defaultVolume)
    }

    func test_zeroVolume_isKeptAndNotTreatedAsMissing() {
        let first = UserDefaultsSettingsStore(defaults: defaults)
        first.setSoundVolume(0)

        let second = UserDefaultsSettingsStore(defaults: defaults)

        XCTAssertEqual(second.soundVolume, 0)
    }
}
