defmodule Haul.Content.MarkdownTest do
  use ExUnit.Case, async: true

  alias Haul.Content.Markdown

  describe "render_html/1" do
    test "renders basic markdown to HTML" do
      assert Markdown.render_html("# Hello") =~ "<h1>"
      assert Markdown.render_html("# Hello") =~ "Hello"
    end

    test "renders paragraphs" do
      assert Markdown.render_html("Some text") =~ "<p>Some text</p>"
    end

    test "renders bold and italic" do
      html = Markdown.render_html("**bold** and *italic*")
      assert html =~ "<strong>bold</strong>"
      assert html =~ "<em>italic</em>"
    end

    test "renders tables (extension)" do
      md = """
      | A | B |
      |---|---|
      | 1 | 2 |
      """

      html = Markdown.render_html(md)
      assert html =~ "<table>"
      assert html =~ "<td>"
    end

    test "renders strikethrough (extension)" do
      html = Markdown.render_html("~~deleted~~")
      assert html =~ "<del>deleted</del>"
    end

    test "renders links" do
      html = Markdown.render_html("[link](https://example.com)")
      assert html =~ "<a"
      assert html =~ "https://example.com"
    end

    test "renders code blocks" do
      html = Markdown.render_html("```\ncode\n```")
      assert html =~ "code"
      assert html =~ "<pre"
    end
  end

  describe "parse_frontmatter!/1" do
    test "parses valid frontmatter" do
      content = "---\ntitle: Hello\nslug: hello\n---\nBody content here"
      {frontmatter, body} = Markdown.parse_frontmatter!(content)

      assert frontmatter["title"] == "Hello"
      assert frontmatter["slug"] == "hello"
      assert body == "Body content here"
    end

    test "trims body whitespace" do
      content = "---\ntitle: Test\n---\n  Body  \n\n"
      {_frontmatter, body} = Markdown.parse_frontmatter!(content)
      assert body == "Body"
    end

    test "handles multiline body" do
      content = "---\ntitle: Test\n---\nLine 1\nLine 2\nLine 3"
      {_frontmatter, body} = Markdown.parse_frontmatter!(content)
      assert body =~ "Line 1"
      assert body =~ "Line 3"
    end

    test "raises on missing frontmatter" do
      assert_raise RuntimeError, ~r/Invalid frontmatter/, fn ->
        Markdown.parse_frontmatter!("No frontmatter here")
      end
    end

    test "raises on malformed frontmatter" do
      assert_raise RuntimeError, ~r/Invalid frontmatter/, fn ->
        Markdown.parse_frontmatter!("---\ntitle: Test\nNo closing delimiter")
      end
    end
  end

  describe "strip_frontmatter/1" do
    test "strips frontmatter and returns body" do
      content = "---\ntitle: Hello\n---\nBody content"
      assert Markdown.strip_frontmatter(content) == "Body content"
    end

    test "returns content unchanged when no frontmatter" do
      assert Markdown.strip_frontmatter("Just content") == "Just content"
    end

    test "trims the result" do
      content = "---\ntitle: X\n---\n  Body  "
      assert Markdown.strip_frontmatter(content) == "Body"
    end

    test "handles empty body after frontmatter" do
      content = "---\ntitle: X\n---\n"
      assert Markdown.strip_frontmatter(content) == ""
    end
  end

  describe "parse_version/1" do
    test "extracts version from frontmatter" do
      content = "---\nversion: 1.2.3\ntitle: Test\n---\nBody"
      assert {:ok, "1.2.3"} = Markdown.parse_version(content)
    end

    test "trims version whitespace" do
      content = "---\nversion:   2.0  \n---\nBody"
      assert {:ok, "2.0"} = Markdown.parse_version(content)
    end

    test "returns error when no version field" do
      content = "---\ntitle: Test\n---\nBody"
      assert {:error, :no_version} = Markdown.parse_version(content)
    end

    test "returns error when no frontmatter" do
      assert {:error, :no_frontmatter} = Markdown.parse_version("Just content")
    end
  end
end
