# backports
This is a nixpkgs overlay that contains temporary fixes for build failures or
other issues, usually backported from the nixpkgs master branch. Each package
defined in this overlay shall automatically disable itself once a certain
condition is met, such as the upstream package being updated or the nixpkgs
modification date passing a certain time.

This is in place because I am extremely forgetful; I will almost certainly
forget to undo a temporary fix later, so this takes care of it for me.
