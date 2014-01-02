Dissector
=========

Use Spark Inspector and Reveal with any application on jailbroken iOS devices.

Please note that this tweak is currently not available in compiled form. Spark Inspector's (name it SparkInspector.dylib) and Reveal's (name it Reveal.dylib) dylibs have to be manually downloaded and placed into `/Library/Dissector/Runtime`.

## Compilation
```sh
git clone https://github.com/mologie/dissector
cd dissector
./bootstrap.sh
make
make package
```

## Testing
In order to create a debug build of Dissector and install it on your device, run `./install-on-device.sh device-hostname`. OpenSSH is required. For your own sanity, please setup keyless authentication first.

## License
This tweak is licensed under the GPLv3. Spark Inspector's and Reveal's framework use proprietary licenses available on their websites.
