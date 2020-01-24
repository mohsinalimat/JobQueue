Pod::Spec.new do |spec|
  spec.name         = "JobQueue"
  spec.version      = "0.0.7"
  spec.summary      = "A persistent and flexible job queue for Swift applications"
  spec.description  = <<-DESC
  A persistent and flexible job queue for Swift applications.
                   DESC

  spec.homepage     = "https://tundaware.com"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author             = { "George Cox" => "george@tundaware.com" }
  spec.social_media_url   = "https://twitter.com/Tundaware"

  spec.ios.deployment_target = '11.0'
  spec.tvos.deployment_target = '11.0'
  spec.watchos.deployment_target = '4.0'
  spec.osx.deployment_target = '10.12'

  spec.source = {
    :git => "https://github.com/Tundaware/JobQueue.git",
    :tag => spec.version.to_s
  }
  spec.swift_version = '5.1'

  spec.default_subspecs = 'Standard'

  spec.subspec 'Standard' do |ss|
    ss.subspec 'JobQueueCore' do |q|
      q.source_files = 'Sources/JobQueueCore/**/*.swift'
    end

    ss.subspec 'JobQueue' do |q|
      q.source_files = 'Sources/JobQueue/**/*.swift', 'Sources/JobQueueCore/**/*.swift'
    end
  end

  # spec.subspec 'InMemoryStorage' do |sp|
  #   sp.source_files = 'Sources/JobQueueInMemoryStorage/**/*.swift'
  #   sp.dependency "JobQueue/JobQueueCore"
  #   sp.dependency "ReactiveSwift", "~> 6.2.0"
  # end
end
