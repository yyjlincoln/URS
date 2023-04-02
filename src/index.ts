import { app, prisma } from "./server";
import { INACTIVE, NOT_FOUND } from "./constants";

const { PORT = 3030, CREATION_KEY } = process.env;

app.use(async (req, res, next) => {
  if (req.path === "/") {
    res.redirect("https://yyjlincoln.com");
    return;
  }
  if (req.path === "/create") {
    if (req.query.key !== CREATION_KEY) {
      res.status(403).send("Access is denied.");
      return;
    }
    next();
    return;
  }
  const route = await prisma.urlMap.findFirst({
    where: { shortUrl: req.path },
  });
  if (route) {
    if (!route.isActive) {
      res.send(INACTIVE);
      return;
    }
    res.redirect(route.url);
    await prisma.history.create({
      data: {
        shortUrl: route.shortUrl,
        url: route.url,
        isValid: true,
        createdAt: new Date(),
      },
    });
  } else {
    res.send(NOT_FOUND);
    await prisma.history.create({
      data: {
        shortUrl: req.path,
        url: "",
        isValid: false,
        createdAt: new Date(),
      },
    });
  }
});

app.get("/create", async (req, res) => {
  const values = { ...req.body, ...req.params, ...req.query };
  const { url, shortUrl } = values;
  if (!url || !shortUrl) {
    res
      .status(400)
      .send("Invalid request. Please include both url and shortUrl");
    return;
  }
  try {
    await prisma.urlMap.create({
      data: {
        url,
        shortUrl,
        createdAt: new Date(),
        isActive: true,
      },
    });
    res.send("Successfully created.");
  } catch (e) {
    res.status(400).send(`Error creating url: ${e}`);
  }
});

app.post("/create", (req, res) => {
  const values = { ...req.body, ...req.params, ...req.query };
  const { url, shortUrl } = values;
  if (!url || !shortUrl) {
    res.status(400).send("Invalid request");
    return;
  }
  prisma.urlMap.create({
    data: {
      url,
      shortUrl,
      createdAt: new Date(),
      isActive: true,
    },
  });
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
