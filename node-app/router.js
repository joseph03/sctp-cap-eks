const express = require("express");
const router = express.Router();

router.get("/", (req, res) => {
  res.send("Welcome to /webapp");
});

router.get("/status", (req, res) => {
  res.json({ status: "ok" });
});

module.exports = router;
