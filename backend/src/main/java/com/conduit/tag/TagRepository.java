package com.conduit.tag;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface TagRepository extends JpaRepository<Tag, Long> {
    Optional<Tag> findByName(String name);

    List<Tag> findByNameIn(List<String> names);

    /**
     * Top tags by usage count. Uses LEFT JOIN so tags without articles are still surfaced.
     * Wired against article_tags join table (created in V5__article_tag.sql / I-11 entity mapping).
     */
    @Query(
            value =
                    "SELECT t.name FROM tags t LEFT JOIN article_tags at ON at.tag_id = t.id "
                            + "GROUP BY t.id, t.name ORDER BY COUNT(at.tag_id) DESC, t.name ASC LIMIT 20",
            nativeQuery = true)
    List<String> findPopularTopTwenty();
}
