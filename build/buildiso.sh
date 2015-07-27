#!/bin/sh

ISODIR=../iso

#0: Prepare files
# mkdir -p ../iso
# cp ../centos7/.discinfo ../iso
# cp ../centos7/.treeinfo ../iso
# cp -r ../centos7/Packages ../iso
# cp -r ../centos7/images ../iso
# cp -r ../centos7/isolinux ../iso
# cp -r ../centos7/LiveOS ../iso

# OS packages
rm -rf $ISODIR/repodata/
/bin/cp comps.xml $ISODIR
createrepo -g comps.xml $ISODIR

# logstash packages
createrepo $ISODIR
cp -r logstash $ISODIR
cp configuration.sh $ISODIR
cp config_network.sh $ISODIR

mkdir -p $ISODIR/ks
/bin/cp ks.cfg $ISODIR/ks
/bin/cp isolinux.cfg $ISODIR/isolinux

mkisofs -o logserver.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -R -J -V "logstash_install" -v -T $ISODIR
