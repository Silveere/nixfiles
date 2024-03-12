# backports
This is a nixpkgs overlay that contains temporary fixes for build failures or
other issues, usually backported from the nixpkgs master branch. Each package
defined in this overlay shall automatically disable itself once the upstream
package has been updated.
