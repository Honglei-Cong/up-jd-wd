#!/bin/bash

PATH=$PATH:`pwd`/bin
INTER_CA_DOCKER=wanda-inter-ca
ORG_BASE=wanda
CA_USER=admin
CA_PASSWD=adminpw
NUM_ORGS=1
NUM_PEERS_PER_ORG=2
SERVER_CA_PORT=7057

# clean ca-server/ca-client config
rm -rf _server-certs && mkdir _server-certs 
docker cp $INTER_CA_DOCKER:/etc/hyperledger/fabric-ca-server/ca-cert.pem _server-certs
docker cp $INTER_CA_DOCKER:/etc/hyperledger/fabric-ca-server/ca-chain.pem _server-certs

if [ -e fabric-ca-client ] ; then
	echo
	echo "Error: fabric-ca-client existed. please remove it first."
	echo
	exit 1
fi

mkdir fabric-ca-client && cp client-config.yaml fabric-ca-client/fabric-ca-client-config.yaml

#sleep 2

CA_ROOT=`pwd`
rm -rf crypto-config 

#orderer
mkdir -p crypto-config/orderer/${ORG_BASE}.ca
cd crypto-config/orderer/${ORG_BASE}.ca
ORG_CA_ROOT=`pwd`
mkdir ca msp orderers users

#orderer-ca
cp $CA_ROOT/_server-certs/ca-cert.pem ca/ca.${ORG_BASE}.cert.pem
cp $CA_ROOT/_server-certs/ca-chain.pem ca/ca.root.${ORG_BASE}.cert.pem

#orderer-users
cd $ORG_CA_ROOT
mkdir -p users/Admin@${ORG_BASE}.ca/msp
cd users/Admin@${ORG_BASE}.ca/msp
mkdir admincerts cacerts keystore signcerts
ORG_ADMIN_ROOT=`pwd`
cd $CA_ROOT && fabric-ca-client enroll -u http://$CA_USER:$CA_PASSWD@localhost:$SERVER_CA_PORT -c fabric-ca-client/fabric-ca-client-config.yaml --id.name Admin.${ORG_BASE}.ca
cd $ORG_ADMIN_ROOT
mv $CA_ROOT/fabric-ca-client/msp/keystore/key.pem keystore/admin.${ORG_BASE}.key
mv $CA_ROOT/fabric-ca-client/msp/signcerts/cert.pem signcerts/admin.${ORG_BASE}.cert.pem
cp $ORG_CA_ROOT/ca/ca.${ORG_BASE}.cert.pem admincerts/
cp $ORG_CA_ROOT/ca/ca.${ORG_BASE}.cert.pem cacerts/
cp $ORG_CA_ROOT/ca/ca.root.${ORG_BASE}.cert.pem cacerts/


#orderer-msp
cd $ORG_CA_ROOT
mkdir -p msp
cd msp
mkdir admincerts cacerts keystore signcerts
cp $ORG_ADMIN_ROOT/signcerts/admin.${ORG_BASE}.cert.pem admincerts/
cp $ORG_CA_ROOT/ca/ca.${ORG_BASE}.cert.pem cacerts/
cp $ORG_CA_ROOT/ca/ca.root.${ORG_BASE}.cert.pem cacerts/
cp $ORG_CA_ROOT/ca/ca.${ORG_BASE}.cert.pem signcerts/

#orderer-orderers
cd $ORG_CA_ROOT
mkdir -p orderers/orderer.${ORG_BASE}.ca/msp
cd orderers/orderer.${ORG_BASE}.ca/msp
mkdir admincerts cacerts keystore signcerts
_PWD=`pwd`
cd $CA_ROOT && fabric-ca-client enroll -u http://$CA_USER:$CA_PASSWD@localhost:$SERVER_CA_PORT -c fabric-ca-client/fabric-ca-client-config.yaml --csr.cn orderer.${ORG_BASE}.ca
cd $_PWD
mv $CA_ROOT/fabric-ca-client/msp/keystore/key.pem keystore/orderer.${ORG_BASE}.key
mv $CA_ROOT/fabric-ca-client/msp/signcerts/cert.pem signcerts/orderer.${ORG_BASE}.cert.pem
cp $ORG_CA_ROOT/ca/ca.${ORG_BASE}.cert.pem cacerts/
cp $ORG_CA_ROOT/ca/ca.root.${ORG_BASE}.cert.pem cacerts/
cp $ORG_ADMIN_ROOT/signcerts/admin.${ORG_BASE}.cert.pem admincerts/


function generatePeer() {
	ORG_ID=$1
	PEER_ID=$2

	cd $ORG_CA_ROOT
	mkdir -p peers/peer${PEER_ID}.org${ORG_ID}.${ORG_BASE}.ca/msp
	cd peers/peer${PEER_ID}.org${ORG_ID}.${ORG_BASE}.ca/msp
	mkdir admincerts cacerts keystore signcerts
	_PWD=`pwd`
	cd $CA_ROOT && fabric-ca-client enroll -u http://$CA_USER:$CA_PASSWD@localhost:$SERVER_CA_PORT -c fabric-ca-client/fabric-ca-client-config.yaml --csr.cn peer${PEER_ID}.org${ORG_ID}.${ORG_BASE}.ca
	cd $_PWD
	mv $CA_ROOT/fabric-ca-client/msp/keystore/key.pem keystore/peer${PEER_ID}.org${ORG_ID}.${ORG_BASE}.key
	mv $CA_ROOT/fabric-ca-client/msp/signcerts/cert.pem signcerts/peer${PEER_ID}.org${ORG_ID}.${ORG_BASE}.cert.pem
	cp $ORG_CA_ROOT/ca/ca.org${ORG_ID}.${ORG_BASE}.cert.pem cacerts/
	cp $ORG_CA_ROOT/ca/ca.root.org${ORG_ID}.${ORG_BASE}.cert.pem cacerts/
	cp $ORG_ADMIN_ROOT/signcerts/admin.org${ORG_ID}.${ORG_BASE}.cert.pem admincerts/
}

function generateOrg() {
	ORG_ID=$1
	# org-root
	cd $CA_ROOT/crypto-config
	mkdir -p peerOrganizations/org${ORG_ID}.${ORG_BASE}.ca
	cd peerOrganizations/org${ORG_ID}.${ORG_BASE}.ca
	ORG_CA_ROOT=`pwd`
	mkdir ca msp peers users

	# org-ca
	cp $CA_ROOT/_server-certs/ca-cert.pem ca/ca.org${ORG_ID}.${ORG_BASE}.cert.pem
	cp $CA_ROOT/_server-certs/ca-chain.pem ca/ca.root.org${ORG_ID}.${ORG_BASE}.cert.pem

	#peers-admin
	cd $ORG_CA_ROOT
	mkdir -p users/Admin@org${ORG_ID}.${ORG_BASE}.ca/msp
	cd users/Admin@org${ORG_ID}.${ORG_BASE}.ca/msp
	mkdir admincerts cacerts keystore signcerts
	ORG_ADMIN_ROOT=`pwd`
	cd $CA_ROOT && fabric-ca-client enroll -u http://$CA_USER:$CA_PASSWD@localhost:$SERVER_CA_PORT -c fabric-ca-client/fabric-ca-client-config.yaml --csr.cn Admin.org${ORG_ID}.${ORG_BASE}.ca
	cd $ORG_ADMIN_ROOT
	mv $CA_ROOT/fabric-ca-client/msp/keystore/key.pem keystore/admin.org${ORG_ID}.${ORG_BASE}.key
	mv $CA_ROOT/fabric-ca-client/msp/signcerts/cert.pem signcerts/admin.org${ORG_ID}.${ORG_BASE}.cert.pem
	cp $ORG_CA_ROOT/ca/ca.org${ORG_ID}.${ORG_BASE}.cert.pem admincerts/
	cp $ORG_CA_ROOT/ca/ca.org${ORG_ID}.${ORG_BASE}.cert.pem cacerts/
	cp $ORG_CA_ROOT/ca/ca.root.org${ORG_ID}.${ORG_BASE}.cert.pem cacerts/

	# org-msp
	cd $ORG_CA_ROOT
	mkdir -p msp
	cd msp
	mkdir admincerts cacerts keystore signcerts
	cp $ORG_ADMIN_ROOT/signcerts/admin.org${ORG_ID}.${ORG_BASE}.cert.pem admincerts/
	cp $ORG_CA_ROOT/ca/ca.org${ORG_ID}.${ORG_BASE}.cert.pem cacerts/
	cp $ORG_CA_ROOT/ca/ca.root.org${ORG_ID}.${ORG_BASE}.cert.pem cacerts/
	cp $ORG_CA_ROOT/ca/ca.org${ORG_ID}.${ORG_BASE}.cert.pem signcerts/

	# org-peers
	i=0
	while test $i -lt $NUM_PEERS_PER_ORG
	do
		generatePeer $ORG_ID $i
		i=$((i+1))
	done
}

#orgs
oi=1
while test $oi -le $NUM_ORGS
do
	generateOrg $oi
	oi=$((oi+1))
done

cd $CA_ROOT
rm -rf _server-certs fabric-ca-client 

