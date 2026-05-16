package com.conduit.article;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.conduit.auth.JwtService;
import com.conduit.user.User;
import com.conduit.user.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ArticleDetailIT {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private UserRepository userRepository;
    @Autowired private ArticleRepository articleRepository;
    @Autowired private ArticleService articleService;
    @Autowired private PasswordEncoder passwordEncoder;
    @Autowired private JwtService jwtService;

    private String aliceToken, bobToken;
    private String slug;

    @BeforeEach
    void seed() {
        articleRepository.deleteAll();
        userRepository.deleteAll();
        User alice = userRepository.save(
                new User("alice", "alice@example.com", passwordEncoder.encode("password")));
        User bob = userRepository.save(
                new User("bob", "bob@example.com", passwordEncoder.encode("password")));
        aliceToken = jwtService.create(alice.getId());
        bobToken = jwtService.create(bob.getId());
        slug = articleService
                .create(alice.getId(), "Hello", "intro", "body", List.of("react"))
                .slug();
    }

    @Test
    void getBySlugReturnsArticle() throws Exception {
        mockMvc.perform(get("/api/articles/" + slug))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.article.title").value("Hello"));
    }

    @Test
    void getMissingReturns404() throws Exception {
        mockMvc.perform(get("/api/articles/no-such-slug"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errors.article[0]").value("not found"));
    }

    @Test
    void updateByAuthorChangesTitleAndSlug() throws Exception {
        String body = objectMapper.writeValueAsString(Map.of("article", Map.of("title", "New Title")));
        mockMvc.perform(
                        put("/api/articles/" + slug)
                                .header("Authorization", "Token " + aliceToken)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.article.title").value("New Title"))
                .andExpect(jsonPath("$.article.slug").value("new-title"));
    }

    @Test
    void updateByNonAuthorReturns403() throws Exception {
        String body = objectMapper.writeValueAsString(Map.of("article", Map.of("title", "Hack")));
        mockMvc.perform(
                        put("/api/articles/" + slug)
                                .header("Authorization", "Token " + bobToken)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.errors.article[0]").value("forbidden"));
    }

    @Test
    void deleteByAuthorRemoves() throws Exception {
        mockMvc.perform(delete("/api/articles/" + slug).header("Authorization", "Token " + aliceToken))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/articles/" + slug)).andExpect(status().isNotFound());
    }

    @Test
    void deleteByNonAuthorReturns403() throws Exception {
        mockMvc.perform(delete("/api/articles/" + slug).header("Authorization", "Token " + bobToken))
                .andExpect(status().isForbidden());
    }
}
