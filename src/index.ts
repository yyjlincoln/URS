import { app, prisma } from "./server";

const { PORT = 3030 } = process.env;

app.get("/", (req, res) => {
  res.status(302).header("location", "https://www.google.com").send();
});

async function main() {
  app.listen(PORT, () => {
    console.log(`Listening on http://localhost:${PORT}`);
  });
}

prisma.$connect();
main()
  .catch((e) => {
    throw e;
  })
  .finally(async () => {
    prisma.$disconnect();
  });
