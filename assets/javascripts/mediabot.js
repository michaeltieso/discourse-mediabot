import { withPluginApi } from "discourse/lib/plugin-api";

function initializeMediaBot(api) {
  api.modifyClass("controller:admin-plugins", {
    actions: {
      clearMediaBotMetrics() {
        return this.send("clearMetrics");
      },
      clearMediaBotErrors() {
        return this.send("clearErrors");
      },
      testMediaBotApi() {
        return this.send("testApi");
      }
    }
  });
}

export default {
  name: "discourse-mediabot",
  initialize() {
    withPluginApi("0.8.31", initializeMediaBot);
  }
}; 