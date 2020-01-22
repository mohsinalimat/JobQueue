[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-orange.svg)](#swift-package-manager) [![GitHub release](https://img.shields.io/github/release/Tundaware/JobQueue/all.svg)](https://github.com/Tundaware/JobQueue/releases) ![Swift 5.1](https://img.shields.io/badge/Swift-5.1-orange.svg) ![platforms](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20tvOS.svg)
[![Build Status](https://travis-ci.com/Tundaware/JobQueue.svg?token=68ifssJzBEm6iihApcf1&branch=master)](https://travis-ci.com/Tundaware/JobQueue)

# JobQueue

A persistent and flexible job queue for Swift applications.

There are other queue implementations for Swift that are based on `Operation` and `OperationQueue`. Unfortunately, those classes have several drawbacks, all due to being closed source.

## Features

- [x] No `Operation` or `OperationQueue`
- [x] Concurrency per job type
- [x] Manual processing order
- [x] Delayed jobs
- [x] Paused jobs
- [ ] Scheduled jobs
- [ ] Repeating jobs
- [ ] Rate limiting
- [x] Custom execution sorting
- [x] Custom persistance
- [x] In memory persistence
- [ ] YapDatabase persistence
- [ ] Couchbase Lite persistence
- [ ] Core Data persistence
- [ ] Realm persistence