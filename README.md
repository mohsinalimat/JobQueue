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