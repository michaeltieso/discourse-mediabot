import Controller from "@ember/controller";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default Controller.extend({
  services: [
    { id: "tmdb", name: "TMDb" },
    { id: "tvdb", name: "TVDb" }
  ],
  
  testService: "tmdb",
  testTitle: "",
  testResult: null,
  
  @action
  saveSettings() {
    ajax("/admin/plugins/mediabot/settings", {
      type: "PUT",
      data: {
        settings: this.model.settings
      }
    })
      .then(() => {
        this.flash(I18n.t("mediabot.admin.save_success"), "success");
      })
      .catch(popupAjaxError);
  },
  
  @action
  clearMetrics() {
    if (!confirm(I18n.t("mediabot.admin.metrics.clear_confirm"))) {
      return;
    }
    
    ajax("/admin/plugins/mediabot/clear_metrics", {
      type: "POST"
    })
      .then(() => {
        this.flash(I18n.t("mediabot.admin.metrics.clear_success"), "success");
        this.send("refreshModel");
      })
      .catch(popupAjaxError);
  },
  
  @action
  clearErrors() {
    if (!confirm(I18n.t("mediabot.admin.errors.clear_confirm"))) {
      return;
    }
    
    ajax("/admin/plugins/mediabot/clear_errors", {
      type: "POST"
    })
      .then(() => {
        this.flash(I18n.t("mediabot.admin.errors.clear_success"), "success");
        this.send("refreshModel");
      })
      .catch(popupAjaxError);
  },
  
  @action
  testApi() {
    if (!this.testTitle) {
      this.flash(I18n.t("mediabot.admin.test.title_required"), "error");
      return;
    }
    
    ajax("/admin/plugins/mediabot/test_api", {
      type: "POST",
      data: {
        service: this.testService,
        title: this.testTitle
      }
    })
      .then(result => {
        this.set("testResult", result);
      })
      .catch(error => {
        this.set("testResult", {
          success: false,
          error: error.jqXHR.responseJSON.error
        });
      });
  }
}); 