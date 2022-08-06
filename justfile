set dotenv-load

all: install update build test

install:
    forge install

update:
    forge update

build: clean
    forge build

test:
    forge test --force -vvv

clean:
    forge clean

gas-report:
    forge test --gas-report

flatten:
    forge flatten src/KoolKoalazNFT.sol

format:
    prettier --write src/**/*.sol \
    && prettier --write src/*.sol \
    && prettier --write test/**/*.sol \
    && prettier --write test/*.sol \
    && prettier --write script/**/*.sol \
    && prettier --write script/*.sol

deploy:
    forge script "script/KoolKoalazNFT.s.sol:Deploy" \
    --rpc-url $RPC_NODE_URL \
    --sender $OWNER_ADDRESS \
    --keystores $KEYSTORE_PATH \
    --broadcast \
    --with-gas-price 25000000000 \
    -vvvv
