import { createServer } from "node:http";
import { createRiveHostApp } from "./app.mjs";
import { loadConfig } from "./config.mjs";

const config = loadConfig();
const app = await createRiveHostApp(config);
const server = createServer(app.handler);

server.requestTimeout = 600_000;
server.headersTimeout = 15_000;
server.keepAliveTimeout = 5_000;

server.listen(config.port, config.host, () => {
  console.log(`Rive Host API 正在监听 http://${config.host}:${config.port}`);
});

function shutdown(signal) {
  console.log(`收到 ${signal}，停止接收新请求`);
  server.close((error) => {
    if (error) {
      console.error(error);
      process.exitCode = 1;
    }
  });
}

process.once("SIGTERM", () => shutdown("SIGTERM"));
process.once("SIGINT", () => shutdown("SIGINT"));
