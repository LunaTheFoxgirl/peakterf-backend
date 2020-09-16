module api.data;
import db;
import config;
import std.path;
import std.file;
import std.exception;
import std.format;
import std.datetime;

/**
    A post in the DB
*/
@safe
struct Post {
    /**
        ID of post
    */
    string _id;

    /**
        Link to image
    */
    string img;

    /**
        Tags
    */
    string[] tags;

    /**
        Alt text
    */
    string alt;

    /**
        UNIX timestamp for data changes
        Changing data about the image will update the timestamp
    */
    long timestamp;

    /**
        Searches for posts based on tag list
        if list is empty then all tags will be included
    */
    @safe
    static SearchResult!Post search(int page, int count, string[] tags) {
        Bson query;

        // Compute the query
        if (tags.length > 0) {
            query = bson([
                "tags": bson(["$in": tags.toBsonArray])
            ]);
        } else {
            query = Bson.emptyObject;
        }

        ulong pcount = DATABASE["peakterf.posts"].count(query);
        ulong qpage = count*page;
        auto cursor = DATABASE["peakterf.posts"].find!Post(query, null);

        // Return a cursor over the search result
        return SearchResult!Post(
            pcount,
            cursor.sort(["timestamp": -1]).skip(cast(int)qpage).limit(count)
        );
    }

    /**
        Updates or creates a databaese entry for a file id
    */
    @safe
    static Post updateOrCreate(string id, string[] tags, string alt) {
        
        // Get image network and local path and make sure it exists
        immutable(string) imgPath = "%s/%s.jpg".format(CONFIG.imgEndpoint, id);
        immutable(string) imgFile = buildPath(CONFIG.imgSaveLocation, id).setExtension("jpg");
        enforce(exists(imgFile), "Could not find file matching the ID");
        
        // Set post data
        Post post;
        post._id = id;
        post.img = imgPath;
        post.alt = alt;
        post.tags = tags;
        post.timestamp = Clock.currStdTime();
        
        // Try to find and update entry
        ulong c = DATABASE["peakterf.posts"].count(bson(["_id": bson(post._id)]));
        if (c > 0) {

            // Entry with matching ID was found, update it
            DATABASE["peakterf.posts"].update(bson(["_id": bson(post._id)]), post);
            return post;
        }

        // Was not found insert new
        DATABASE["peakterf.posts"].insert!Post(post);
        return post;
    }
}

/**
    Creates a new ID
*/
@trusted
string createID(int len = 16) {
    import std.base64 : Base64URLNoPadding;
    import vibe.crypto.cryptorand : secureRNG;

    // Generate an ID byte array
    auto rng = secureRNG();
    ubyte[] idstream = new ubyte[len];
    rng.read(idstream);

    // Encode the id byte stream to no-padding Base64
    ulong length = Base64URLNoPadding.encodeLength(idstream.length);
    char[] b64Arr = new char[length];
    string b64Str = cast(string)Base64URLNoPadding.encode(idstream, b64Arr);

    // Return the final slice of the encoded id
    return b64Str;
}