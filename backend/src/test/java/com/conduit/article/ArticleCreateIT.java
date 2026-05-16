package com.conduit.article;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.conduit.auth.JwtService;
import com.conduit.tag.TagRepository;
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
class ArticleCreateIT {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private UserRepository userRepository;
    @Autowired private ArticleRepository articleRepository;
    @Autowired private TagRepository tagRepository;
    @Autowired private PasswordEncoder passwordEncoder;
    @Autowired private JwtService jwtService;

    private String token;

    @BeforeEach
    void seed() {
        articleRepository.deleteAll();
        tagRepository.deleteAll();
        userRepository.deleteAll();
        User u = userRepository.save(
                new User("alice", "alice@example.com", passwordEncoder.encode("password")));
        token = jwtService.create(u.getId());
    }

    private String body(String title, String description, String articleBody, List<String> tags)
            throws Exception {
        var article = new java.util.HashMap<String, Object>();
        article.put("title", title);
        article.put("description", description);
        article.put("body", articleBody);
        if (tags != null) article.put("tagList", tags);
        return objectMapper.writeValueAsString(Map.of("article", article));
    }

    @Test
    void createReturns201WithSlugAndTags() throws Exception {
        mockMvc.perform(
                        post("/api/articles")
                                .header("Authorization", "Token " + token)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body("Hello World", "intro", "body text", List.of("react", "java"))))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.article.slug").value("hello-world"))
                .andExpect(jsonPath("$.article.title").value("Hello World"))
                .andExpect(jsonPath("$.article.tagList[0]").value("java"))
                .andExpect(jsonPath("$.article.tagList[1]").value("react"))
                .andExpect(jsonPath("$.article.author.username").value("alice"))
                .andExpect(jsonPath("$.article.favorited").value(false))
                .andExpect(jsonPath("$.article.favoritesCount").value(0));
    }

    @Test
    void duplicateTitleGetsSuffix() throws Exception {
        mockMvc.perform(
                        post("/api/articles")
                                .header("Authorization", "Token " + token)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body("Hello World", "first", "first body", null)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.article.slug").value("hello-world"));

        mockMvc.perform(
                        post("/api/articles")
                                .header("Authorization", "Token " + token)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body("Hello World", "second", "second body", null)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.article.slug").value(org.hamcrest.Matchers.matchesPattern("^hello-world-[a-z0-9]{6}$")));
    }

    @Test
    void missingTitleReturns422() throws Exception {
        mockMvc.perform(
                        post("/api/articles")
                                .header("Authorization", "Token " + token)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body("", "desc", "body", null)))
                .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void anonymousReturns401() throws Exception {
        mockMvc.perform(
                        post("/api/articles")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body("title", "desc", "body", null)))
                .andExpect(status().isUnauthorized());
    }
}
