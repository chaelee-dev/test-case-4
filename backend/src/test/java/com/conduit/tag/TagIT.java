package com.conduit.tag;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class TagIT {

    @Autowired private MockMvc mockMvc;
    @Autowired private TagRepository tagRepository;
    @Autowired private TagService tagService;

    @BeforeEach
    void clean() {
        tagRepository.deleteAll();
    }

    @Test
    void emptyListReturns200() throws Exception {
        mockMvc.perform(get("/api/tags"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.tags").isArray());
    }

    @Test
    void upsertIsIdempotent() {
        List<Tag> first = tagService.upsertAll(List.of("react", "java"));
        List<Tag> again = tagService.upsertAll(List.of("react", "java"));
        assertThat(first).hasSize(2);
        assertThat(again).extracting(Tag::getId).containsExactlyElementsOf(first.stream().map(Tag::getId).toList());
    }

    @Test
    void upsertSkipsBlanksAndDuplicates() {
        List<Tag> tags = tagService.upsertAll(List.of(" react ", "", "react", "java"));
        assertThat(tags).extracting(Tag::getName).containsExactly("react", "java");
    }
}
