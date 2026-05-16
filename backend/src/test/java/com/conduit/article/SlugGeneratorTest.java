package com.conduit.article;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class SlugGeneratorTest {

    private final SlugGenerator slugger = new SlugGenerator();

    @Test
    void simpleTitle() {
        assertThat(slugger.slugify("Hello World")).isEqualTo("hello-world");
    }

    @Test
    void mixedCaseAndPunctuation() {
        assertThat(slugger.slugify("How to Train Your Dragon: A Tale!"))
                .isEqualTo("how-to-train-your-dragon-a-tale");
    }

    @Test
    void unicodeStripped() {
        assertThat(slugger.slugify("naïve café"))
                .matches("naive-cafe|naive-cafe-?.*"); // diacritics removed
    }

    @Test
    void emojiOnlyFallsBackToUntitled() {
        assertThat(slugger.slugify("🤔🤔🤔")).startsWith("untitled-");
    }

    @Test
    void blankFallsBackToUntitled() {
        assertThat(slugger.slugify("")).startsWith("untitled-");
        assertThat(slugger.slugify(null)).startsWith("untitled-");
    }

    @Test
    void withSuffixAppendsSixCharNanoid() {
        String base = "hello-world";
        String withSuffix = slugger.withSuffix(base);
        assertThat(withSuffix).matches("^hello-world-[a-z0-9]{6}$");
    }
}
