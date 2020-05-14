#!/bin/bash
#
# This script decompresses all tarballs
# from a downloaded 'linux-source-****.src.rpm
# in /usr/src/rpmbuild/.
# 
# All Suse Vendor patches are applied, afterward.
#

kern_ver="4.4"
kern_src="/usr/src/linux-${kern_ver}"
src_dir="/usr/src/packages/SOURCES/"

# Unpack all tarballs
cd "${src_dir}" || exit
for bz2 in ./*.bz2
  do
  tar xvfj "${bz2}"
done

for xz in ./*.xz
  do
  tar xvJf "${xz}"
done

# Clean old source, move new kernel source to /usr/src
  echo -e "\nCleaning old source files and directories\n"
  rm -rf /usr/src/linux-*
  rm -rf /usr/src/linux
  mv ${src_dir}/linux-${kern_ver} /usr/src
  ln -sf "${kern_src}" /usr/src/linux
