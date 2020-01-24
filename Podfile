abstract_target 'All' do
  use_frameworks!
  pod "ReactiveSwift"

  abstract_target 'Frameworks' do
    target 'JobQueueCore.iOS' do
      platform :ios, '11.0'
    end
    target 'JobQueueCore.tvOS' do
      platform :tvos, '11.0'
    end
    target 'JobQueueCore.watchOS' do
      platform :watchos, '4.0'
    end
    target 'JobQueueCore.macOS' do
      platform :macos, '10.12'
    end

    target 'JobQueue.iOS' do
      platform :ios, '11.0'
    end
    target 'JobQueue.tvOS' do
      platform :tvos, '11.0'
    end
    target 'JobQueue.watchOS' do
      platform :watchos, '4.0'
    end
    target 'JobQueue.macOS' do
      platform :macos, '10.12'
    end

    target 'JobQueueInMemoryStorage.iOS' do
      platform :ios, '11.0'
    end
    target 'JobQueueInMemoryStorage.tvOS' do
      platform :tvos, '11.0'
    end
    target 'JobQueueInMemoryStorage.watchOS' do
      platform :watchos, '4.0'
    end
    target 'JobQueueInMemoryStorage.macOS' do
      platform :macos, '10.12'
    end
  end

  abstract_target 'Tests' do
    pod "Nimble"
    pod "Quick"

    target 'JobQueue.tests.iOS' do
      platform :ios, '11.0'
    end
    target 'JobQueue.tests.tvOS' do
      platform :tvos, '11.0'
    end
    target 'JobQueue.tests.macOS' do
      platform :macos, '10.12'
    end
  end
end