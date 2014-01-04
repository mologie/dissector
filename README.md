Dissector
=========

Use [Spark Inspector](http://sparkinspector.com/) and [Reveal](http://revealapp.com/) with any application on jailbroken iOS devices.

A prebuilt version of Dissector is available on the [Mologie Cydia Repository](http://cydia.mologie.com/). In order to see the package, tell Cydia that you are a hacker. Open Cydia's package filter menu by tapping the Manage tab followed by Settings in the top left corner.

## Compilation
Prior to compiling this tweak, Xcode 5, its command line tools and the iOS 7 SDK must be installed. The following will download Dissector's source code, download its dependencies, and build a package which can be installed on a jailbroken iOS device.
```sh
git clone https://github.com/mologie/dissector
cd dissector
./bootstrap.sh
make
make package
```

Use the `install-on-device.sh` script or issue `make DEBUG=1` for building binaries which log debug messages to the iOS device's console.

## Testing
Please note that this repository does not contain the required debugger runtimes. Spark Inspector's (name it SparkInspector.dylib) and Reveal's (name it Reveal.dylib) dylibs have to be manually downloaded and placed into `/Library/Dissector/Runtime` on your iOS device when compiling from source.

You can also install the debugger runtime libraries from the Mologie Cydia Repository by telling Cydia that you are a developer. The packages are named `Spark Inspector Runtime` and `Reveal Runtime` and are updated automatically as updates are released by their authors.

In order to create a debug build of Dissector and install it on your device, run `./install-on-device.sh device-hostname`. OpenSSH is required. For your own sanity, please setup keyless authentication first.

## License
This tweak is licensed under the GPLv3. Spark Inspector's and Reveal's framework use proprietary licenses available on their websites.
