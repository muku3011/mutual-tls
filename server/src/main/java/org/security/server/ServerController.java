package org.security.server;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;


@RestController
public class ServerController {

    @GetMapping("/check")
    @ResponseBody
    public ResponseEntity<String> checkClient() {
        return ResponseEntity.ok("Server is up and running");
    }
}
