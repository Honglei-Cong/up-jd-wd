#!/bin/bash

ORG_BASE=jd
NUM_ORGS=1

mkdir -p tmp/crypto-config/orderer/${ORG_BASE}.ca/
cp -r crypto-config/orderer/${ORG_BASE}.ca/msp tmp/crypto-config/orderer/${ORG_BASE}.ca/

i=1
while test $i -le $NUM_ORGS
do
	mkdir -p tmp/crypto-config/peerOrganizations/org${i}.${ORG_BASE}.ca/
	cp -r crypto-config/peerOrganizations/org${i}.${ORG_BASE}.ca/msp tmp/crypto-config/peerOrganizations/org${i}.${ORG_BASE}.ca/
	i=$((i+1))
done

cd tmp; tar czf ${ORG_BASE}_msp.tgz crypto-config; cd ..
mv tmp/${ORG_BASE}_msp.tgz .
echo "Done. peer msp files saved as ${ORG_BASE}_msp.tgz"
rm -rf tmp

