package com.conduit.markdown;

import org.commonmark.parser.Parser;
import org.commonmark.renderer.html.HtmlRenderer;
import org.jsoup.Jsoup;
import org.jsoup.safety.Safelist;
import org.springframework.stereotype.Service;

/**
 * Renders user-supplied markdown into safe HTML, defending against R-N-03 (XSS).
 *
 * <p>Two-pass: commonmark builds HTML, jsoup Safelist.relaxed() strips script / iframe / on* /
 * javascript: URIs. Caller stores raw markdown; render is on read.
 */
@Service
public class MarkdownService {

    private final Parser parser = Parser.builder().build();
    private final HtmlRenderer renderer = HtmlRenderer.builder().build();
    private final Safelist safelist =
            Safelist.relaxed()
                    .addProtocols("a", "href", "http", "https", "mailto")
                    .addProtocols("img", "src", "http", "https");

    public String render(String markdown) {
        if (markdown == null || markdown.isEmpty()) return "";
        String rendered = renderer.render(parser.parse(markdown));
        return Jsoup.clean(rendered, safelist);
    }
}
