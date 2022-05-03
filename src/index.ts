import { app } from "./server";

const { PORT = 3030 } = process.env;

app.get("/", (req, res) => {
  res.status(302).header("location", "https://www.google.com").send();
});

app.listen(PORT, () => {
  console.log(`Listening on http://localhost:${PORT}`);
});
