list=$(for n in 20d 20e 20f 210 211 212 213 214 215 216; do printf "%04x " "0x$n"; done)
for i in $list;
do
        echo "Now formatting disk $i"
        dasdfmt -y -b 4096 /dev/disk/by-path/ccw-0.0.$i
done

