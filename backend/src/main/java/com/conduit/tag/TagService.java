package com.conduit.tag;

import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TagService {

    private final TagRepository repository;

    public TagService(TagRepository repository) {
        this.repository = repository;
    }

    /** Upserts tag rows by name and returns the corresponding entities (order preserved per input). */
    @Transactional
    public List<Tag> upsertAll(List<String> names) {
        if (names == null || names.isEmpty()) return List.of();
        Set<String> unique = new HashSet<>();
        List<String> ordered = names.stream().map(String::trim).filter(s -> !s.isEmpty()).filter(unique::add).toList();
        if (ordered.isEmpty()) return List.of();
        Map<String, Tag> existing =
                repository.findByNameIn(ordered).stream().collect(Collectors.toMap(Tag::getName, t -> t));
        Map<String, Tag> resolved = new HashMap<>(existing);
        for (String n : ordered) {
            resolved.computeIfAbsent(n, name -> repository.save(new Tag(name)));
        }
        return ordered.stream().map(resolved::get).toList();
    }

    @Transactional(readOnly = true)
    public List<String> listPopular() {
        return repository.findPopularTopTwenty();
    }
}
