source 'https://github.com/CocoaPods/Specs.git'

# ignore all warnings from all pods
inhibit_all_warnings!

def common_pods
    pod 'toxcore', '0.0.0-2ab3b14-1'
    pod 'CocoaLumberjack', '~> 1.9.2'
    pod 'Realm', '0.93.2'
end

def demo_pods
    pod 'Masonry', '~> 0.6.1'
    pod 'BlocksKit', '~> 2.2.5'
end

def test_pods
    pod 'OCMock', '~> 3.1.2'
end


target :iOSDemo do
    platform :ios, '7.0'
    link_with 'iOSDemo'
    common_pods
    demo_pods
end

target :iOSDemoTests do
    platform :ios, '7.0'
    link_with 'iOSDemoTests'
    common_pods
    test_pods
end

target :OSXDemo do
    platform :osx, '10.9'
    link_with 'OSXDemo'
    common_pods
    demo_pods
end

target :OSXDemoTests do
    platform :osx, '10.9'
    link_with 'OSXDemoTests'
    common_pods
    test_pods
end
