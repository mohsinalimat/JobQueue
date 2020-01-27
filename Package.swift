// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "JobQueue",
  platforms: [
    .iOS(.v11),
    .macOS(.v10_13)
  ],
  products: [
    .library(
      name: "JobQueue",
      targets: ["JobQueue"]
    ),
    .library(
      name: "JobQueueCore",
      targets: ["JobQueueCore"]
    ),
    .library(
      name: "JobQueueInMemoryStorage",
      targets: ["JobQueueInMemoryStorage"]
    ),
    .library(
      name: "JobQueueCoreDataStorage",
      targets: ["JobQueueCoreDataStorage"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/ReactiveCocoa/ReactiveSwift", from: "6.2.0"),
    .package(url: "https://github.com/Quick/Nimble", .branch("master")),
    .package(url: "https://github.com/Quick/Quick", from: "2.2.0")
  ],
  targets: [
    .target(
      name: "JobQueue",
      dependencies: ["JobQueueCore", "ReactiveSwift"],
      path: "Sources/Queue"
    ),
    .target(
      name: "JobQueueCore",
      dependencies: ["ReactiveSwift"],
      path: "Sources/Core"
    ),
    .target(
      name: "JobQueueInMemoryStorage",
      dependencies: ["JobQueueCore", "ReactiveSwift"],
      path: "Sources/Storage/InMemory"
    ),
    .target(
      name: "JobQueueCoreDataStorage",
      dependencies: ["JobQueueCore", "ReactiveSwift"],
      path: "Sources/Storage/CoreData"
    ),
    .testTarget(
      name: "JobQueueTests",
      dependencies: ["JobQueue", "JobQueueInMemoryStorage", "JobQueueCoreDataStorage", "Nimble", "Quick", "ReactiveSwift"],
      path: "Tests"
    )
  ]
)
