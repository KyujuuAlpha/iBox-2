iBox 2.6.8 -- BETA
====

Bochs for iOS, ALL credit goes to ColemanCDA for the base of iBox, Baddaboo for updating iBox with 64-Bit support, and the team behind Bochs. There is non-jailbroken device support. Use dev branch to toy with Voodoo 3d, linux should also be supported although colors may be wack. 

If you are trying to run it on a simulator, it may not work due to the SDL library being built for the ARM architecture.  Try running it from an iOS Device instead.

FOR SPEED (Warning: WILL warm up your device):
* set IPS to 4,000,000
* update freq at 30 with VBE/None

====

Changes:
* Updated to iOS 10 and Swift 3
* Updated to Bochs 2.6.8
* **Clunky** on-screen keyboard
   * NOTE: Shift is toggle, ~~visual indicator is planned~~
* Shake to hide keyboard, shake again to show
* SDL 2.0 sound support
* Networking in Beta stages
* Support for up to 2GB RAM allocation
* Floppy Disk integration
* Cirrus support <-- SVGA is REALLY buggy, not recommended

====

iBox -- https://github.com/colemancda/iBox - Bochs -- http://bochs.sourceforge.net - SDL 2.0 -- https://www.libsdl.org


