const { MongoClient } = require("mongodb");
const { createApp } = require("./app");

const PORT = Number(process.env.PORT || 3000);
const MONGO_URI = process.env.MONGO_URI;

if (!MONGO_URI) {
  console.error("MONGO_URI environment variable is required");
  process.exit(1);
}

async function start() {
  const client = new MongoClient(MONGO_URI, {
    serverSelectionTimeoutMS: 5000
  });

  try {
    await client.connect();

    const db = client.db("study_now");

    const app = createApp(db);

    const server = app.listen(PORT, "0.0.0.0", () => {
      console.log(`Study Now API listening on port ${PORT}`);
    });

    async function shutdown(signal) {
      console.log(`${signal} received. Shutting down`);

      server.close(async () => {
        await client.close();
        process.exit(0);
      });

      setTimeout(() => process.exit(1), 10000).unref();
    }

    process.on("SIGTERM", () => shutdown("SIGTERM"));
    process.on("SIGINT", () => shutdown("SIGINT"));
  } catch (error) {
    console.error("Application startup failed:", error.message);
    await client.close();
    process.exit(1);
  }
}

start();
