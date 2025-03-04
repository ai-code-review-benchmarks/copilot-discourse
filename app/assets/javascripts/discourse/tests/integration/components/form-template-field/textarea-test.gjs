import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import Input from "discourse/components/form-template-field/input";
import Textarea from "discourse/components/form-template-field/textarea";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";

module(
  "Integration | Component | form-template-field | textarea",
  function (hooks) {
    setupRenderingTest(hooks);

    test("renders a textarea input", async function (assert) {
      await render(<template><Textarea /></template>);

      assert
        .dom(".form-template-field__textarea")
        .exists("a textarea input component exists");
    });

    test("renders a text input with attributes", async function (assert) {
      const self = this;

      const attributes = {
        label: "My text label",
        placeholder: "Enter text here",
      };
      this.set("attributes", attributes);

      await render(<template>
        <Textarea @attributes={{self.attributes}} />
      </template>);

      assert
        .dom(".form-template-field__textarea")
        .exists("a textarea input component exists");

      assert.dom(".form-template-field__label").hasText("My text label");
      assert
        .dom(".form-template-field__textarea")
        .hasAttribute("placeholder", "Enter text here");
    });

    test("doesn't render a label when attribute is missing", async function (assert) {
      const self = this;

      const attributes = {
        placeholder: "Enter text here",
      };
      this.set("attributes", attributes);

      await render(<template>
        <Textarea @attributes={{self.attributes}} />
      </template>);

      assert.dom(".form-template-field__label").doesNotExist();
    });

    test("renders a description if present", async function (assert) {
      const self = this;

      const attributes = {
        description: "Write your bio here",
      };
      this.set("attributes", attributes);

      await render(<template>
        <Input @attributes={{self.attributes}} />
      </template>);

      assert
        .dom(".form-template-field__description")
        .hasText("Write your bio here");
    });
  }
);
