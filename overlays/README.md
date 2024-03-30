# Overlays
This directory contains nixpkgs overlays which each serve some specific purpose.

## backports
This overlay defines programs that should be unconditionally backported from
nixpkgs-unstable. Packages backported in this overlay will be built using
inputs from the current system when possible, as to not unnecessarily increase
the closure size. This may result in unexpected breakages, as packages in
nixpkgs-unstable are built and tested against other such packages.


## mitigations
This overlay contains temporary fixes for build failures or other issues,
usually backported from the nixpkgs master branch. Each package defined in this
overlay shall automatically disable itself once a certain condition is met,
such as the upstream package being updated or the nixpkgs modification date
passing a certain time.

This is in place because I am extremely forgetful; I will almost certainly
forget to undo a temporary fix later, so this takes care of it for me.
