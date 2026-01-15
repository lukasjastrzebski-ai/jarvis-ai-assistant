# TASK-002: SwiftUI App Scaffold

**Phase:** PHASE-01
**Status:** Pending
**Priority:** P0

---

## Scope

Create the iOS and macOS app scaffold with shared code architecture.

---

## Acceptance Criteria

### AC-001: iOS App Builds
- GIVEN iOS target is selected
- WHEN built
- THEN app launches on simulator

### AC-002: macOS App Builds
- GIVEN macOS target is selected
- WHEN built
- THEN app launches

### AC-003: Shared Code
- GIVEN shared module exists
- THEN 80%+ code is shared between platforms

### AC-004: Navigation Structure
- GIVEN app launches
- THEN tab bar (iOS) / sidebar (macOS) navigation works

---

## Test Delta

**Add:**
- tests/iOS/AppLaunchTests.swift
- tests/macOS/AppLaunchTests.swift

**Regression:**
- xcodebuild test -scheme Jarvis-iOS
- xcodebuild test -scheme Jarvis-macOS

---

## Authorized Files

- Jarvis.xcodeproj/**
- Jarvis/**
- JarvisShared/**
- tests/**

---

## Dependencies

- TASK-001
