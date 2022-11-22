#!/usr/bin/env bash

#Vim

[[ $(id -u) -eq 0 ]] || { echo >&2 "Must be root to run script"; exit 1; }

#Enable fuzzing
echo core > /proc/sys/kernel/core_pattern
echo 0 > /proc/sys/kernel/randomize_va_space
swapoff -a

#Variables
target=vim #change
tmpDir=/home/$SUDO_USER/Desktop/Fuzzing/$target/tmp
targetDir=$tmpDir/$target
fuzzOut=$tmpDir/fuzzOut
currentDir=$(pwd)
fuzzIn=$currentDir/testcases/


#Use RAM for storage
mkdir -p $tmpDir
chown $SUDO_USER $tmpDir
chmod 777 $tmpDir
mount -t tmpfs -o size=4G tmpfs $tmpDir

mkdir -p $targetDir

#Download here
cd $targetDir
if [ -d vim ]; then
    cd vim
    make distclean
else
    git clone https://github.com/vim/vim.git
    cd vim
fi

#Compile here
CC=afl-clang-fast CXX=afl-clang-fast++ ./configure --with-features=huge --enable-gui=none ; make -j4 ; cd src


#Fuzz
cd $targetDir/vim/src

if [ -d $fuzzOut ]; then
    afl-fuzz -M Master -i - -o $fuzzOut ./$target -u NONE -X -Z -e -s -S @@ -c ':qa!' & afl-fuzz -S Slave -i - $fuzzIn -o $fuzzOut ./$target -u NONE -X -Z -e -s -S @@ -c ':qa!'
else
    afl-fuzz -M Master -i $fuzzIn -o $fuzzOut ./$target -u NONE -X -Z -e -s -S @@ -c ':qa!' & afl-fuzz -S Slave -i $fuzzIn -o $fuzzOut ./$target -u NONE -X -Z -e -s -S @@ -c ':qa!'
fi

chown -R $SUDO_USER $tmpDir
chmod -R 777 $tmpDir
