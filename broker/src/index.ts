import express, { Express, Request, Response } from "express";
import { v4 as uuidv4 } from "uuid";
import dotenv from "dotenv";
import RedisClient from "./redis";
import logger from "./logger";
import { IntentEndpointSchema } from "./zod";
import { SolveEndpointSchema } from "./zod";

dotenv.config();

const app: Express = express();
// Middleware to parse JSON bodies
app.use(express.json());

// Set port
const port = process.env.PORT || 3000;

// Instantiate a redis
const redis = RedisClient.getInstance();

function createIntentKey(inputToken: string, outputToken: string) {
  const uuid = uuidv4();
  return `swap_intent:${inputToken}:${outputToken}:${uuid}`;
}

function createSolveKey(intentKey: string) {
  const uuid = uuidv4();
  return `swap_solve:${intentKey}:${uuid}`;
}

app.get("/health", (req: Request, res: Response) => {
  logger.log("info", "Health check");
  res.send("OK");
});

app.post("/v1/intent", (req: Request, res: Response) => {
  const { intent } = req.body;
  const parsedIntent = IntentEndpointSchema.parse(intent);
  const intentKey = createIntentKey(
    parsedIntent.tokenIn,
    parsedIntent.tokenOut
  );
  redis.set(intentKey, JSON.stringify(parsedIntent));
  res.send({ message: "Intent created", intentKey });
});

app.post("/v1/solve", (req: Request, res: Response) => {
  const { solve } = req.body;
  const parsedSolve = SolveEndpointSchema.parse(solve);
  const solveKey = createSolveKey(parsedSolve?.intentKey);
  redis.set(solveKey, JSON.stringify(parsedSolve));
  res.send({ message: "Solve created", solveKey });
});

app.listen(port, () => {
  logger.info(`[server]: Server is running at http://localhost:${port}`);
});
