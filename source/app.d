module app;
import db;
import config;
import api;
import vibe.vibe;

/**
	Registers the Linux MemoryError handler so we get convenient errors if we crash.
*/
void registerLinuxCrashHandler() {
	import etc.linux.memoryerror;
	static if (is(typeof(registerMemoryErrorHandler)))
		registerMemoryErrorHandler();
}

void main()
{
	// Basic setup stuff
	registerLinuxCrashHandler();
	URLRouter router = new URLRouter;

	// Initialize config and database
	debug setLogLevel(LogLevel.debug_);
	logInfo("Initializing config and database...");
	loadConfig();
	initDatabase();
	logInfo("Initialized!");

	// Register our API
	router.registerRestInterface!IPeakTerfAPI(new PeakTerfAPI, "/api/v1");

	if (CONFIG.beCDN) {
		auto fileSettings = new HTTPFileServerSettings;
		fileSettings.serverPathPrefix = "/static";
		router.any("/static/*", serveStaticFiles("static/", fileSettings));
	}

	// Launch the server
	logInfo("Launching server...");
	listenHTTP(CONFIG.bindAddress, router);
	runApplication();
}
