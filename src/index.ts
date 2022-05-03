import { app } from "./server";

const { PORT = 3030 } = process.env;

app.get("/", (req, res) => {
  res.status(200).send({
    message: "Hello World",
  });
});

app.listen(PORT, () => {
  console.log(`Listening on http://localhost:${PORT}`);
});
