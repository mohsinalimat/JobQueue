Pod::Spec.new do |s|
  s.name         = "JobQueue"
  s.version      = "0.0.7"
  s.summary      = "A persistent and flexible job queue for Swift applications"
  s.description  = <<-DESC
  A persistent and flexible job queue for Swift applications.
                   DESC

  s.homepage     = "https://tundaware.com"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "George Cox" => "george@tundaware.com" }
  s.social_media_url   = "https://twitter.com/Tundaware"

  s.ios.deployment_target = '11.0'
  s.tvos.deployment_target = '11.0'
  s.watchos.deployment_target = '4.0'
  s.osx.deployment_target = '10.12'

  s.source = {
    :git => "https://github.com/Tundaware/JobQueue.git",
    :tag => s.version.to_s
  }
  s.swift_version = '5.1'

  s.default_subspecs = 'Standard'

  s.subspec 'Standard' do |ss|
    ss.subspec 'JobQueue' do |sss|
      sss.source_files = 'Sources/JobQueue/**/*.swift'
      sss.dependency = 'JobQueue/JobQueueCore'
      sss.dependency = 'ReactiveSwift', '~> 6.2.0'

      sss.subspec 'JobQueueCore' do |ssss|
        ssss.source_files = 'Sources/JobQueueCore/**/*.swift'
        sss.dependency = 'ReactiveSwift', '~> 6.2.0'
      end
    end
  end

  # spec.subspec 'InMemoryStorage' do |sp|
  #   sp.source_files = 'Sources/JobQueueInMemoryStorage/**/*.swift'
  #   sp.dependency "JobQueue/JobQueueCore"
  #   sp.dependency "ReactiveSwift", "~> 6.2.0"
  # end
end
