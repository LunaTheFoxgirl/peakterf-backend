module db;
import vibe.db.mongo.client;
public import vibe.db.mongo.database;
public import vibe.data.bson;
public import vibe.db.mongo.mongo;
import std.traits;
import config;

@trusted
Database DATABASE;

struct SearchResult(T) {
    import vibe.db.mongo.cursor : MongoCursor;

    /**
        Count of results
    */
    ulong count;

    /**
        The cursor result
    */
    MongoCursor!T result;
}

/**
    Bson object
*/
Bson bson(T)(T item) {
    return Bson(item);
}

/**
    Converts a D array to a Bson array
*/
Bson toBsonArray(T)(T[] arr) {
    Bson[] values;
    foreach(value; arr) {
        values ~= Bson(value);
    }
    return Bson(values);
}

@safe
class Database {
private:
    MongoClient client;

public:
    @safe
    MongoCollection opIndex(string index) {
        return client.getCollection(index);
    }

    @safe
    this(string connString) {
        this.client = connectMongoDB(connString);
    }
}

void initDatabase() {
    DATABASE = new Database(CONFIG.connectionString);
}