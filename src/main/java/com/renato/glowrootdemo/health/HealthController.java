package com.renato.glowrootdemo.health;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

import com.renato.glowrootdemo.user.UserRepository;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {

    private final UserRepository userRepository;

    public HealthController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @GetMapping("/health")
    public Map<String, Object> health() {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("status", "UP");
        result.put("timestamp", Instant.now().toString());

        try {
            long count = userRepository.count();
            Map<String, Object> db = new LinkedHashMap<>();
            db.put("status", "UP");
            db.put("usersCount", count);
            result.put("database", db);
        } catch (Exception e) {
            Map<String, Object> db = new LinkedHashMap<>();
            db.put("status", "DOWN");
            db.put("error", e.getMessage());
            result.put("database", db);
        }

        return result;
    }
}


