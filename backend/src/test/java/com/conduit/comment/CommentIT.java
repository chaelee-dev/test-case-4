package com.conduit.comment;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.conduit.article.ArticleRepository;
import com.conduit.article.ArticleService;
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
class CommentIT {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private UserRepository userRepository;
    @Autowired private ArticleRepository articleRepository;
    @Autowired private CommentRepository commentRepository;
    @Autowired private ArticleService articleService;
    @Autowired private PasswordEncoder passwordEncoder;
    @Autowired private JwtService jwtService;

    private String aliceToken, bobToken;
    private String slug;

    @BeforeEach
    void seed() {
        commentRepository.deleteAll();
        articleRepository.deleteAll();
        userRepository.deleteAll();
        User alice = userRepository.save(
                new User("alice", "alice@example.com", passwordEncoder.encode("password")));
        User bob = userRepository.save(
                new User("bob", "bob@example.com", passwordEncoder.encode("password")));
        aliceToken = jwtService.create(alice.getId());
        bobToken = jwtService.create(bob.getId());
        slug = articleService.create(alice.getId(), "Alice Post", "intro", "body", List.of()).slug();
    }

    private String body(String text) throws Exception {
        return objectMapper.writeValueAsString(Map.of("comment", Map.of("body", text)));
    }

    @Test
    void listEmptyReturns200() throws Exception {
        mockMvc.perform(get("/api/articles/" + slug + "/comments"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.comments").isArray());
    }

    @Test
    void createAndList() throws Exception {
        mockMvc.perform(
                        post("/api/articles/" + slug + "/comments")
                                .header("Authorization", "Token " + bobToken)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body("nice post")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.comment.body").value("nice post"))
                .andExpect(jsonPath("$.comment.author.username").value("bob"));

        mockMvc.perform(get("/api/articles/" + slug + "/comments"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.comments.length()").value(1));
    }

    @Test
    void blankBodyReturns422() throws Exception {
        mockMvc.perform(
                        post("/api/articles/" + slug + "/comments")
                                .header("Authorization", "Token " + bobToken)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body("")))
                .andExpect(status().isUnprocessableEntity());
    }

    @SuppressWarnings("unchecked")
    private long createComment(String token) throws Exception {
        String response =
                mockMvc.perform(
                                post("/api/articles/" + slug + "/comments")
                                        .header("Authorization", "Token " + token)
                                        .contentType(MediaType.APPLICATION_JSON)
                                        .content(body("nice post")))
                        .andReturn()
                        .getResponse()
                        .getContentAsString();
        Map<String, Object> root = objectMapper.readValue(response, Map.class);
        Map<String, Object> comment = (Map<String, Object>) root.get("comment");
        return ((Number) comment.get("id")).longValue();
    }

    @Test
    void deleteByOwnerSucceeds() throws Exception {
        long id = createComment(bobToken);

        mockMvc.perform(
                        delete("/api/articles/" + slug + "/comments/" + id)
                                .header("Authorization", "Token " + bobToken))
                .andExpect(status().isNoContent());
    }

    @Test
    void deleteByNonOwnerReturns403() throws Exception {
        long id = createComment(bobToken);

        mockMvc.perform(
                        delete("/api/articles/" + slug + "/comments/" + id)
                                .header("Authorization", "Token " + aliceToken))
                .andExpect(status().isForbidden());
    }

    @Test
    void anonymousCreateReturns401() throws Exception {
        mockMvc.perform(
                        post("/api/articles/" + slug + "/comments")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body("x")))
                .andExpect(status().isUnauthorized());
    }
}
