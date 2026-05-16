package com.conduit.markdown;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class MarkdownServiceTest {

    private final MarkdownService svc = new MarkdownService();

    @Test
    void plainMarkdownRendersBold() {
        assertThat(svc.render("**bold**")).contains("<strong>bold</strong>");
    }

    @Test
    void scriptTagStripped() {
        String out = svc.render("Hello <script>alert(1)</script> world");
        assertThat(out).doesNotContain("<script");
        assertThat(out).doesNotContain("alert(1)");
    }

    @Test
    void imgOnerrorStripped() {
        String out = svc.render("<img src=x onerror=alert(1)>");
        assertThat(out).doesNotContain("onerror");
    }

    @Test
    void iframeStripped() {
        String out = svc.render("<iframe src=\"javascript:alert(1)\"></iframe>");
        assertThat(out).doesNotContain("<iframe");
        assertThat(out).doesNotContain("javascript:");
    }

    @Test
    void javascriptLinkHrefStripped() {
        String out = svc.render("[click](javascript:alert(1))");
        assertThat(out).doesNotContain("javascript:");
    }

    @Test
    void svgOnloadStripped() {
        String out = svc.render("<svg onload=alert(1)>");
        assertThat(out).doesNotContain("<svg");
        assertThat(out).doesNotContain("onload");
    }

    @Test
    void dataUriHtmlPayloadStripped() {
        String out = svc.render("<a href=\"data:text/html,<script>alert(1)</script>\">x</a>");
        assertThat(out).doesNotContain("data:text/html");
        assertThat(out).doesNotContain("<script");
    }

    @Test
    void styleTagPayloadStripped() {
        String out = svc.render("<style>body { background: url(\"javascript:alert(1)\") }</style>");
        assertThat(out).doesNotContain("<style");
        assertThat(out).doesNotContain("javascript:");
    }

    @Test
    void objectTagStripped() {
        String out = svc.render("<object data=\"javascript:alert(1)\"></object>");
        assertThat(out).doesNotContain("<object");
        assertThat(out).doesNotContain("javascript:");
    }

    @Test
    void preservesAllowedLinkAndImage() {
        String out = svc.render("[link](https://example.com) ![img](https://example.com/x.png)");
        assertThat(out).contains("href=\"https://example.com\"");
        assertThat(out).contains("src=\"https://example.com/x.png\"");
    }
}
