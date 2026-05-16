package com.conduit.article;

import java.security.SecureRandom;
import java.text.Normalizer;
import java.util.regex.Pattern;
import org.springframework.stereotype.Component;

/**
 * Conduit-spec slug: kebab-case(title), fallback "untitled" for non-ascii, plus 6-char nanoid
 * suffix on collision. SecureRandom-backed alphabet 36ch (a-z + 0-9).
 */
@Component
public final class SlugGenerator {

    private static final Pattern NON_ASCII = Pattern.compile("[^a-z0-9]+");
    private static final char[] ALPHABET = "abcdefghijklmnopqrstuvwxyz0123456789".toCharArray();
    private static final SecureRandom RNG = new SecureRandom();

    public String slugify(String title) {
        if (title == null || title.isBlank()) return "untitled-" + suffix();
        String normalized = Normalizer.normalize(title.toLowerCase(), Normalizer.Form.NFD);
        String stripped = normalized.replaceAll("\\p{M}+", "");
        String kebab = NON_ASCII.matcher(stripped).replaceAll("-").replaceAll("^-+|-+$", "");
        if (kebab.isEmpty()) return "untitled-" + suffix();
        return kebab.length() > 240 ? kebab.substring(0, 240) : kebab;
    }

    public String withSuffix(String slug) {
        return slug + "-" + suffix();
    }

    private String suffix() {
        char[] chars = new char[6];
        for (int i = 0; i < 6; i++) chars[i] = ALPHABET[RNG.nextInt(ALPHABET.length)];
        return new String(chars);
    }
}
