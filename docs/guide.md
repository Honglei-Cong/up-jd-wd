## Download docker

docker pull hyperledger/fabric-peer:x86_64-1.0.0-alpha2

docker pull hyperledger/fabric-orderer:x86_64-1.0.0-alpha2

docker pull hyperledger/fabric-ccenv:x86_64-1.0.0-alpha2

docker pull hyperledger/fabric-ca:x86_64-1.0.0-alpha2

docker tag docker.io/hyperledger/fabric-ca:x86_64-1.0.0-alpha2 hyperledger/fabric-ca:latest

docker tag docker.io/hyperledger/fabric-peer:x86_64-1.0.0-alpha2 hyperledger/fabric-peer:latest

docker tag docker.io/hyperledger/fabric-orderer:x86_64-1.0.0-alpha2 hyperledger/fabric-orderer:latest

docker tag docker.io/hyperledger/fabric-ccenv:x86_64-1.0.0-alpha2 hyperledger/fabric-ccenv:latest

## Start Fabric Root CA

cd root-ca-setup

cp fabric-ca-server-config.yaml fabric-ca-server

docker-compose up -d

By default, Fabric Root CA provides service with port 7054.  If need update, change docker-compose.yaml.
RootCA server ip address/port should be provided to other parties.


## Start Fabric Intermediate CA

All parties start their Intermediate CA servers.

1. update csr-cn in fabric-ca-server-config.yaml, to define your own CSR-CN

```
188 csr:
189    cn: MY-Inter-CA1    <-- change to your own CSN-CN
```

2. remote ununsed services in docker-compose.yaml

3. update username/password/Root-CA-IP in docker-compose.yaml

4. copy fabric-ca-server-config.yaml to Intermediate-CA config directory

```
    cp fabric-ca-server-config.yaml fabric-ca-server-wanda/
```

5. start Intermediate-CA server

```
docker-compose up -d
```

## Generate Certs

1. change to your docker directory, eg up-docker

2. update generateCerts.sh

>
a. update INTER_CA_DOCKER
b. update ORG_BASE
c. update SERVER_CA_PORT

3. execute generateCert.sh

4. check generated certs in ./crypto-config

## Collect Configurations and Certs

All parties should provide the following informations:

>
1. Orderer MSP, including MSPID and orderer certs
2. Org MSP, including MSPID and org certs
3. Orderer IP addresses
4. Anchor peer IP addresses


## Configure Orderers and Orgs

Configure all orderers and Orgs to configtx.yaml. example-configtx.yaml as an example.

Put certs of orderers and orgs to cryto-config. example-crypto-config.txt shows the structure of crypto-config.


## Generate Genesis Block

If Org MSPID changed in configtx.yaml, please update generateArtifacts.sh accordingly.

Execute generateArtifacts.sh, genesis blocks are generated in channel-artifacts.

The directory channel-artifacts should be shared among all parties.

## Update docker-compose file

Update docker-compose.yaml if MSPID of peers changed.

## Start Fabric

`docker-compose up -d` to start fabric dockers.

cli docker will execute test script automatically.

