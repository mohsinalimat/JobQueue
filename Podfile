abstract_target 'All' do
  use_frameworks!
  pod "ReactiveSwift"

  abstract_target 'Frameworks' do
    target 'JobQueue.iOS' do
      platform :ios, '11.0'
    end
    target 'JobQueue.watchOS' do
      platform :watchos, '4.0'
    end
    target 'JobQueue.macOS' do
      platform :macos, '10.11'
    end

    target 'JobQueueInMemoryStorage.iOS' do
      platform :ios, '11.0'
    end
    target 'JobQueueInMemoryStorage.watchOS' do
      platform :watchos, '4.0'
    end
    target 'JobQueueInMemoryStorage.macOS' do
      platform :macos, '10.11'
    end
  end

  abstract_target 'Tests' do
    pod "Nimble"
    pod "Quick"

    target 'JobQueue.tests.iOS' do
      platform :ios, '11.0'
    end
    target 'JobQueue.tests.macOS' do
      platform :macos, '10.11'
    end
  end
end