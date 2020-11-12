package org.security.client;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

import java.util.logging.Logger;

@RestController
public class ClientController {

    private static final Logger logger = Logger.getAnonymousLogger();

    @GetMapping("/connect/server")
    @ResponseBody
    public ResponseEntity<String> checkClient() {
        RestTemplate restTemplate = new RestTemplate();
        String serverCheckUrl = "https://localhost:8000/check";
        logger.info("Calling server -->");
        return restTemplate.getForEntity(serverCheckUrl, String.class);
    }
}
