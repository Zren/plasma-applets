## v2 - January 22 2017

* Use `apt full-upgrade` instead of `apt upgrade`
* Use a different sound effect when there's packages to autoremove.
* Check for notify-send first and help the user install it. Kubuntu comes preinstalled with this, but KDE Neon doesn't.

## v1 - September 22 2017

* First public release
* If no updates known, run a script in Konsole that calls `sudo apt update`, then run the upgrade script.
* If there are known updates, run a script in Konsole that calls `sudo apt upgrade`.
* Plays sounds effects and notifications on error/completion.
* Requires `libnotify-bin` (aka `notify send`) to show notications.
