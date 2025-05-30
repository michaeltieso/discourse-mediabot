import { withPluginApi } from "discourse/lib/plugin-api";

function initializeMediaBot(api) {
  // Admin interface modifications
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

  // Add plugin outlet for post content
  api.addPostMenuButton("mediabot", (attrs) => {
    return {
      action: "showMediaInfo",
      icon: "film",
      title: "mediabot.show_info",
      position: "first"
    };
  });

  // Add plugin outlet for topic list
  api.decorateWidget("topic-list-item-title:after", (helper) => {
    const topic = helper.attrs;
    if (topic.tags && topic.tags.includes("movie")) {
      return helper.attach("mediabot-topic-indicator", { topic });
    }
  });
}

export default {
  name: "discourse-mediabot",
  initialize() {
    withPluginApi("0.8.31", initializeMediaBot);
  }
}; 