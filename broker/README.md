# Based Accounts - broker

This is the "broker" service for the intents based layer of the Ethereum account connector. It is responsible for managing the intents and the communication between the intents and the Ethereum account connector. The broker services main purpose is to allow a prospective swapper to submit intents, allow solvers to submit solutions and to rank them according to swap efficiency.

## How to run 
```bash

pnpm install
docker-compose up # Runs redis for persistence 
pnpm run dev
```

## Schema
The broker supports the following operations:

`/v1/intent` - POST - Submit an intent to the broker. The intent is stored in the broker and is available for solvers to solve. The intent is stored in a redis database.

`/v1/solution` - POST - Submit a solution to the broker. The solution is stored in the broker and is available for the submitter to claim the reward. The solution is stored in a redis database.

`/v1/get_intents` - GET - Get all intents that are currently stored in the broker. The intents are stored in a redis database.

## Useful curls
Add an intent

```bash
curl -X POST http://localhost:3000/v1/intent \
-H "Content-Type: application/json" \
-d '{
    "intent": {
        "tokenIn": "0xd07379a755A8f11B57610154861D694b2A0f615a",
        "tokenOut": "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
        "amountIn": "1000000000000000000",
        "minOut": "900000000000000000"
    }
}'
```


Add a solve
```bash
curl -X POST http://localhost:3000/v1/intent \
-H "Content-Type: application/json" \
-d '{
    "intent": {
        "tokenIn": "0xd07379a755A8f11B57610154861D694b2A0f615a",
        "tokenOut": "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
        "amountIn": "1000000000000000000",
        "minOut": "900000000000000000"
    }
}'
```
