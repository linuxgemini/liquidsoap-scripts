# liquidsoap-scripts

Liquidsoap scripts I'm writing to try the language out.

Mainly, this repo will be about re-streaming from other sources or generating test media.

## Requirements

### System

I'm currently running everything on a beefy Debian 12/bookworm VM with the following:
  - [`deb-multimedia` repository](https://www.deb-multimedia.org/) (just `bookworm` one) for FFmpeg and related libraries.
    * To avoid complications, I pinned the repository with a higher priority. To achieve this, you can add a file to `/etc/apt/preferences.d/` like `/etc/apt/preferences.d/99prefer-dmo` and add this config:

      ```
      Package: *
      Pin: release o=Unofficial Multimedia Packages,n=bookworm
      Pin-Priority: 910
      ```

  - Debian's own `bookworm-backports` repository pinned with a higher priority for keeping everything else at the Bleeding Edge™️:
    * To achieve this, you can add a file to `/etc/apt/preferences.d/` like `/etc/apt/preferences.d/99prefer-backports` and add this config:

      ```
      Package: *
      Pin: release o=Debian Backports,n=bookworm-backports
      Pin-Priority: 900
      
      Package: *
      Pin: release o=Debian Backports,n=bookworm-backports-debug
      Pin-Priority: 900
      ```

    * Then run `apt update` following with `apt dist-upgrade` as root.
    * Reboot.
  - Liquidsoap `.deb` files from [Liquidsoap Rolling Release 2.3.x](https://github.com/savonet/liquidsoap/releases/tag/rolling-release-v2.3.x)
    * Minimal packages are _not_ used.

### Streaming target

You also need a platform to stream to.

### Drawing the rest of the fucking owl

Remaining steps:
  - Clone this repository:
    * `git clone https://github.com/linuxgemini/liquidsoap-scripts.git`
  - Change current working directory to the repository folder:
    * `cd liquidsoap-scripts`
  - Create a `secrets` folder:
    * `mkdir secrets`
  - Configure your streaming target, this is left as an exercise for the reader.
  - Run any one of the scripts, for example:
    * `./testcard.liq`
