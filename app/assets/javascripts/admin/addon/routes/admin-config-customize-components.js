import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class AdminConfigThemesAndComponentsComponentsRoute extends DiscourseRoute {
  async model() {
    const components = await this.store.findAll("theme");
    return components.reject((t) => !t.component);
  }

  titleToken() {
    return i18n("admin.config_areas.themes_and_components.components.title");
  }
}
