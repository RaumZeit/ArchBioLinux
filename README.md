# PKGBUILDs directory for the ArchBio Linux image

This repo contains some ArchLinux PKGBUILDs that I maintain, and some I don't.
The main purpose of these PKGBUILDs is to keep ArchBioLinux
(https://www.tbi.univie.ac.at/~ronny/archbio.html) more or less up-to-date

### make_packages.sh

The repo contains a bash script, make_packages.sh, to generate binary packages for x86_64 and i686.
To avoid rebuilding of already existing packages I utilize a PKGBUILD parser script which I took
from Abdó Roig-Maranges' arch-build toolkit (https://github.com/aroig/arch-build)

