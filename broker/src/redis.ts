import Redis from "ioredis";

class RedisClient {
  private static instance: Redis;

  private constructor() {
    // Initialize the Redis instance
    RedisClient.instance = new Redis({
      host: "localhost",
      port: 6379,
      // Add any other Redis configuration options here
    });
  }

  public static getInstance(): Redis {
    if (!RedisClient.instance) {
      new RedisClient();
    }
    return RedisClient.instance;
  }

  public static async set(key: string, value: string): Promise<void> {
    await RedisClient.instance.set(key, value);
  }

  public static async get(key: string): Promise<string | null> {
    return await RedisClient.instance.get(key);
  }
}

export default RedisClient;
