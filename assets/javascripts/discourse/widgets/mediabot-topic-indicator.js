import { createWidget } from "discourse/widgets/widget";
import { h } from "virtual-dom";

createWidget("mediabot-topic-indicator", {
  tagName: "span.mediabot-topic-indicator",
  
  defaultState() {
    return {
      loading: false,
      error: null
    };
  },
  
  html(attrs, state) {
    if (state.loading) {
      return h("span.mediabot-icon.loading", {
        attributes: {
          title: I18n.t("mediabot.loading")
        }
      }, "⌛");
    }
    
    if (state.error) {
      return h("span.mediabot-icon.error", {
        attributes: {
          title: state.error
        }
      }, "⚠️");
    }
    
    return h("span.mediabot-icon", {
      attributes: {
        title: I18n.t("mediabot.topic_has_media")
      }
    }, "🎬");
  }
}); 