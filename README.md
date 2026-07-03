# liquidsoap-scripts

Liquidsoap scripts I'm writing to try the language out.

Mainly, this repo will be about re-streaming from other sources or generating test media.

## Requirements

### System

I'm currently running everything on a beefy Debian 13/trixie VM with the following:
  - [`deb-multimedia` repository](https://www.deb-multimedia.org/) (just `trixie` one) for FFmpeg and related libraries.
    * To avoid complications, I pinned the repository with a higher priority. To achieve this, you can add a file to `/etc/apt/preferences.d/` like `/etc/apt/preferences.d/99prefer-dmo` and add this config:

      ```
      Package: *
      Pin: release o=Unofficial Multimedia Packages,n=trixie
      Pin-Priority: 910
      ```

  - Debian's own `trixie-backports` repository pinned with a higher priority for keeping everything else at the Bleeding Edge™️:
    * To achieve this, you can add a file to `/etc/apt/preferences.d/` like `/etc/apt/preferences.d/99prefer-backports` and add this config:

      ```
      Package: *
      Pin: release o=Debian Backports,n=trixie-backports
      Pin-Priority: 900
      
      Package: *
      Pin: release o=Debian Backports,n=trixie-backports-debug
      Pin-Priority: 900
      ```

    * Then run `apt update` following with `apt dist-upgrade` as root.
    * Reboot.
  - Liquidsoap `.deb` files from [Liquidsoap v2.4.5](https://github.com/savonet/liquidsoap/releases/tag/v2.4.5)
    * `ocaml5.4.0` packages are chosen.
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
