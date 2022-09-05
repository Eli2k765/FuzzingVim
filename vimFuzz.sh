 #!/usr/bin/env bash

[[ $(id -u) -eq 0 ]] || { echo >&2 "Must be root to run script"; exit 1; }

echo "[+] Enabling Fuzzing"
echo core > /proc/sys/kernel/core_pattern
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
echo 0 > /proc/sys/kernel/randomize_va_space
swapoff -a

echo "[+] Please input the target binary: "
read target
echo "[+] What vuln are you looking for: HUAF, HBO, or Null?"
read vulnType

TMPDIR=/home/fuzz/Desktop/Fuzzing/$target/tmp
targetPath=$TMPDIR/$target
fuzzOut=$TMPDIR/fuzzOut
fuzzIn=/home/fuzz/Desktop/Fuzzing/$target/testcases/$vulnType/

echo -e "[+] Making ramdisk"
mkdir -p $TMPDIR
chown fuzz $TMPDIR
chmod 777 $TMPDIR
mount -t tmpfs -o size=2G tmpfs $TMPDIR
mkdir -p $targetPath/src
cd $targetPath/src

if [ -f "$target" ]; then
	cd ..
	make distclean
	sleep 1
	break
else
	cd $TMPDIR
	rm -rf $target
	echo -e "[+] Download"
	git clone https://github.com/vim/vim.git
	cd $target
	sleep 1
	break
fi

echo "[+] Compiling"
CC=afl-clang-fast CXX=afl-clang-fast++ ./configure --with-features=huge --enable-gui=none && make -j4 ; cd src/

echo -e "[+] Fuzzing"

if [-d $fuzzOut ]; then
    afl-fuzz -M Master -i - -o $fuzzOut ./$target -u NONE -X -Z -e -s -S @@ -c ':qa!' & afl-fuzz -S Slave1 -i - $fuzzIn -o $fuzzOut ./$target -u NONE -X -Z -e -s -S @@ -c ':qa!' & afl-fuzz -S Slave2 -i - $fuzzIn -o $fuzzOut ./$target -u NONE -X -Z -e -s -S @@ -c ':qa!' & afl-fuzz -S Slave3 -i - $fuzzIn -o $fuzzOut ./$target -u NONE -X -Z -e -s -S @@ -c ':qa!' & afl-fuzz -S Slave4 -i - $fuzzIn -o $fuzzOut ./$target -u NONE -X -Z -e -s -S @@ -c ':qa!' & afl-fuzz -S Slave5 -i - $fuzzIn -o $fuzzOut ./$target -u NONE -X -Z -e -s -S @@ -c ':qa!'
else
    afl-fuzz -M Master -i $fuzzIn -o $fuzzOut ./$target -u NONE -X -Z -e -s -S @@ -c ':qa!' & afl-fuzz -S Slave1 -i $fuzzIn -o $fuzzOut ./$target -u NONE -X -Z -e -s -S @@ -c ':qa!' & afl-fuzz -S Slave2 -i $fuzzIn -o $fuzzOut ./$target -u NONE -X -Z -e -s -S @@ -c ':qa!' & afl-fuzz -S Slave3 -i $fuzzIn -o $fuzzOut ./$target -u NONE -X -Z -e -s -S @@ -c ':qa!' & afl-fuzz -S Slave4 -i $fuzzIn -o $fuzzOut ./$target -u NONE -X -Z -e -s -S @@ -c ':qa!' & afl-fuzz -S Slave5 -i $fuzzIn -o $fuzzOut ./$target -u NONE -X -Z -e -s -S @@ -c ':qa!'
fi

chown -R fuzz $TMPDIR
chmod -R 777 $TMDIR
