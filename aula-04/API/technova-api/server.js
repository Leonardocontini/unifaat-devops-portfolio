const express = require("express");

const app = express();

const PORT = 3000;

app.use(express.json());


app.get("/", (req, res) => {
    res.json({
        message: "API TechNova funcionando!",
        status: "online"
    });
});


app.get("/health", (req, res) => {
    res.status(200).json({
        status: "healthy"
    });
});


app.get("/api/info", (req, res) => {
    res.json({
        project: "TechNova",
        environment: "development",
        server: "Node.js"
    });
});


app.listen(PORT, "0.0.0.0", () => {
    console.log(`API rodando na porta ${PORT}`);
});