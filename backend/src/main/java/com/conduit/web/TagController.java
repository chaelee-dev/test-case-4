package com.conduit.web;

import com.conduit.tag.TagService;
import java.util.List;
import java.util.Map;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class TagController {

    private final TagService tagService;

    public TagController(TagService tagService) {
        this.tagService = tagService;
    }

    @GetMapping("/api/tags")
    public ResponseEntity<Map<String, List<String>>> listTags() {
        return ResponseEntity.ok(Map.of("tags", tagService.listPopular()));
    }
}
