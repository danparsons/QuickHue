QuickHue
========

QuickHue is an OS X menu bar utility for controlling the Philips Hue lighting system. It allows you to capture the current state of your Hue system into a preset and then quickly apply that preset at a later time. In this way, you can create multiple presets for different states and quickly switch between them.

For example, I have an "Energize" preset which sets all lamps to a very cool color temperature, an "Evening" preset which sets a warm color temperature, a "Relax" preset which sets a warm color temperature and low brightness. You can make presets of whatever you want and name them whatever you want.

![Menu screenshot](https://raw.github.com/danparsons/QuickHue/master/Screenshots/menu.png)

![Prefs screenshot](https://raw.github.com/danparsons/QuickHue/master/Screenshots/prefs.png)


Demonstration video: http://www.youtube.com/watch?v=zHUVcE28W9k

Download
========
Prebuilt QuickHue.app available here:
https://github.com/danparsons/QuickHue/raw/master/QuickHue.zip

Installation Through Homebrew
=============================

QuickHue is available through
[homebrew](https://github.com/mxcl/homebrew) when [homebrew
cask](https://github.com/phinze/homebrew-cask) is installed.  QuickHue
can be installed with this command:

`brew cask install quickhue`

Features
========
* Quickly change entire Hue state from OS X menu bar
* Supports an infinite number of Hue lamps (effectively limited by the maximum 50 lamps supported by the Hue controller)
* Autodiscovery of Hue controller
* Completely asynchronous - the Hue API requires separate requests for each lamp which some control software implement in a blocking, serial fashion. QuickHue uses the [DPHue library](https://github.com/danparsons/DPHue), which executes multiple requests simultaneously and asynchronously, effecting rapid and reliable state changes.


Caveats
=======
* QuickHue doesn't allow you to edit presets. It can only copy the current state of your Hue system to a preset. For actually editing the current state of your Hue system, you must use the Hue iOS / Android apps. I don't personally edit presets much; I created the few I wanted when I first set the system up, using the iOS app. But I switch between them frequently and was annoyed at having to pull my iPhone out of my pocket every time I wanted to change presets. I may add preset editing in the future. The DPHue library I wrote already has the necessary support.
* The Hue controller can only handle about 30 requests in rapid succession before it starts rate limiting, which it does by responding to all requests with HTTP 503. Additionally, each lamp requires a separate request. This means that if you change presets too quickly, lamps may take a while to change, and the Hue controller may start ignoring you. So if you try to apply a preset and it doesn't work, wait a little bit and try again.
* QuickHue very likely requires OS X 10.8 Mountain Lion.

Building
========
Want to build QuickHue? First, install Xcode via the Mac App Store, then run these commands in your terminal:

1. Install CocoaPods if you haven't already: sudo gem install cocoapods; pod setup
2. Clone the QuickHue repository: git clone https://github.com/danparsons/QuickHue
3. Resolve QuickHue's CocoaPod dependencies: cd QuickHue; pod install
4. Open the QuickHue Xcode Workspace document (NOT the Xcode project): open QuickHue.xcworkspace
5. Change the build target to QuickHue: In Xcode, to the right of the Stop button, click the dropdown and choose QuickHue.
6. Click Run.

That's it!
