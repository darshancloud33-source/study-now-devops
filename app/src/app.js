const express = require("express");

function createApp(db) {
  const app = express();

  app.use(express.json({ limit: "100kb" }));

  // Liveness: confirms that the Node.js process is running.
  app.get("/health", (req, res) => {
    res.status(200).json({
      status: "healthy",
      service: "study-now-api"
    });
  });

  // Readiness: confirms that MongoDB is reachable.
  app.get("/ready", async (req, res) => {
    try {
      if (!db) {
        throw new Error("Database connection unavailable");
      }

      await db.command({ ping: 1 });

      res.status(200).json({
        status: "ready",
        database: "connected"
      });
    } catch (error) {
      res.status(503).json({
        status: "not_ready",
        database: "unavailable"
      });
    }
  });

  // Create a demonstration student record.
  app.post("/api/students", async (req, res) => {
    try {
      const { referenceId, name } = req.body;

      if (
        typeof referenceId !== "string" ||
        typeof name !== "string" ||
        !referenceId.trim() ||
        !name.trim()
      ) {
        return res.status(400).json({
          error: "referenceId and name are required"
        });
      }

      const result = await db.collection("students").insertOne({
        referenceId: referenceId.trim(),
        name: name.trim(),
        createdAt: new Date()
      });

      return res.status(201).json({
        message: "Student record created",
        id: String(result.insertedId)
      });
    } catch (error) {
      return res.status(500).json({
        error: "Unable to create student record"
      });
    }
  });

  // Retrieve demonstration student records.
  app.get("/api/students", async (req, res) => {
    try {
      const students = await db.collection("students")
        .find({}, { projection: { referenceId: 1, name: 1, createdAt: 1 } })
        .limit(50)
        .toArray();

      return res.status(200).json({
        count: students.length,
        students
      });
    } catch (error) {
      return res.status(500).json({
        error: "Unable to retrieve student records"
      });
    }
  });

  return app;
}

module.exports = { createApp };
