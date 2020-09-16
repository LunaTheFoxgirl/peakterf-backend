module api;
public import api.data;
import vibe.web.rest;
import vibe.web.auth;
import vibe.http.common;
import vibe.http.server;
import vibe.inet.webform;
import config;
import std.exception;

/**
    Authentication info
*/
static struct AuthInfo {
    /**
        Auth token
    */
    string authToken;

    /**
        Returns true if the connecting authentication token is the bot secret
    */
    bool isBot() {
        return authToken == CONFIG.botSecret; 
    }
}

/**
    API interface for PeakTerfAPI
*/
@requiresAuth
interface IPeakTerfAPI {

    /**
        Authenticate requests
    */
    @noRoute
    @safe
    final AuthInfo authenticate(scope HTTPServerRequest req, scope HTTPServerResponse res) {
        
        // If auth token was presented then we can set auth info
        if (req.headers["auth"] == CONFIG.botSecret)
            return AuthInfo(req.headers["auth"]);

        // Invalid auth
		throw new HTTPStatusException(HTTPStatus.unauthorized);
    }

    /**
        GET /api/v1/posts
        page: which "page" to get
        tags: which tags to include

        Returns list of max 20 posts from the database
    */
    @queryParam("page", "page")
    @queryParam("tags", "tags")
    @noAuth
    Post[] getPosts(int page = 0, string[] tags = null);

    /**
        POST /api/v1/image
        id: the id of the image
        tags: list of tags
        alt: alt text
        phash: perceptual hash

        Returns nothing or an error if something's wrong
    */
    @path("img")
    @auth(Role.bot)
    @method(HTTPMethod.POST)
    @bodyParam("imgid", "id")
    @bodyParam("tags", "tags")
    @bodyParam("alt", "alt")
    string setImg(string imgid, string[] tags, string alt);

    /**
        Uploads image and returns its ID
    */
    @path("upload")
    @auth(Role.bot)
    @method(HTTPMethod.POST)
    @before!handleFileGet("file")
    string upload(FilePart file);
}

/**
    Handle getting the file
*/
static FilePart handleFileGet(HTTPServerRequest req, HTTPServerResponse res) {
    import std.path : extension;

    // Make sure we have a part called "img"
    enforce("img" in req.files, "No image supplied!");

    // Get it, make sure its file type is ".jpg"
    FilePart imgFile = req.files["img"];
    enforce(imgFile.filename.name.extension == ".jpg", "Invalid file type!");

    return imgFile;
}

/**
    API implementation for PeakTerfAPI
*/
@requiresAuth
class PeakTerfAPI : IPeakTerfAPI {

    /**
        GET /api/v1/posts
        page: which "page" to get
        tags: which tags to include

        Returns list of max 20 posts from the database
    */
    @safe
    Post[] getPosts(int page = 0, string[] tags = null) {
        Post[] posts;

        // Get a cursor over posts with the specified tags
        auto cursor = Post.search(page, 20, tags);

        // Add each post the cursor found to the list
        foreach(post; cursor.result) posts ~= post;

        // Return the found posts, this result may have anywhere from 0 to 20 indicies
        return posts;
    }

    /**
        Set image data
    */
    @safe
    string setImg(string id, string[] tags, string alt) {
        Post post = Post.updateOrCreate(id, tags, alt);
        return post._id;
    }

    /**
        Upload image
    */
    @safe
    string upload(FilePart file) {
        import std.file : copy;
        import std.path : buildPath, setExtension;

        // Create a new ID for the file
        string id = createID();

        // Move the file from the temporary download directory to its permanent place
        copy(file.tempPath.toString, buildPath(".", CONFIG.imgSaveLocation, id).setExtension("jpg"));

        // Return the ID of the file
        return id;
    }
}