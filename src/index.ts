import { app, prisma, router } from "./server";
import { NOT_FOUND } from "./constants";

const { PORT = 3030 } = process.env;

router.use(async (req, res) => {
  if (req.url === "/") {
    res.redirect("https://yyjlincoln.com");
    return;
  }
  const route = await prisma.urlMap.findFirst({ where: { shortUrl: req.url } });
  if (route) {
    res.redirect(route.url);
  } else {
    res.send(NOT_FOUND);
  }
});

app.use(router);

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
