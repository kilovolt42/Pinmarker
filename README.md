# Pinmarker

[Pinmarker](http://kilovolt42.com/pinmarker) is a comfortable app for adding bookmarks to [Pinboard](https://pinboard.in/). Use a clean native interface to enter tags and a description before posting. Easily post to multiple accounts without re-entering login information. Configure powerful workflows with other apps using flexible URL schemes.

## Getting Started

Run the following commands to clone the project and install the required Cocoapods:

    git clone git@github.com:kilovolt42/Pinmarker.git
    cd Pinmarker
    pod install

Because this project uses CocoaPods you will need to open Pinmarker.xcworkspace, not Pinmarker.xcodeproj.

Unfortunately at this point the project will fail to build. Open Pinmarker.xcworkspace and select the Pinmarker project. Under Build Settings, set **Build Active Architecture Only** to **NO**. Then select the Pods project and make sure Pods is selected in the editor pane under PROJECT. Again, set **Build Active Architecture Only** to **NO**. The project should now build successfully. If anyone knows how to fix this problem once and for all, please let me know!

## Open Source

I decided to open source this app so I could easily show the code to potential employers, friends, and curious folks. Additionally, the extensibility features coming in iOS 8 will make the workflows of this app obsolete. Death to bookmarklets! All hail App Extensions! Although I may continue to fiddle with this project, I am much more interested in exploring the possibilities of Action and Share Extentions on both iOS and OS X.

## Miscellaneous

This source code is released under the MIT License.

![Pinmarker Screenshot](https://raw.githubusercontent.com/kilovolt42/Pinmarker/master/screenshot.png)