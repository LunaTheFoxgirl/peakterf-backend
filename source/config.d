module config;
import vibe.data.json;
import std.file : readText;

/**
    Global configuration instance
*/
ServerConfig CONFIG;

/**
    Server config
*/
@safe
struct ServerConfig {
    /**
        Database connection string
    */
    string connectionString;

    /**
        The secret a bot can use to submit images
    */
    string botSecret;

    /**
        Address to bind to
    */
    string bindAddress;

    /**
        Endpoint for images
    */
    string imgEndpoint;

    /**
        Save location for images
    */
    string imgSaveLocation;

    /**
        If the server should handle serving image files
    */
    @optional
    bool beCDN;
}

void loadConfig() {
    CONFIG = deserializeJson!ServerConfig(parseJsonString(readText("config.json")));
}