using Vala.Collections;
using Vala.Distributed;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/distributed/snowflake/testBasic", testBasic);
    Test.add_func ("/distributed/snowflake/testMonotonicUnique", testMonotonicUnique);
    Test.add_func ("/distributed/snowflake/testWithEpoch", testWithEpoch);
    Test.add_func ("/distributed/snowflake/testNextString", testNextString);

    Test.run ();
}

void testBasic () {
    var generator = new Snowflake (7);
    int64 id = generator.nextId ();

    assert (id > 0);
    assert (generator.nodeIdOf (id) == 7);
    assert (generator.sequenceOf (id) >= 0);

    int64 timestamp = generator.timestampMillis (id);
    int64 now = GLib.get_real_time () / 1000L;
    assert (timestamp <= now + 1000L);
    assert (timestamp >= now - 60000L);

    SnowflakeParts parts = generator.parse (id);
    assert (parts.timestampMillis () == timestamp);
    assert (parts.nodeId () == 7);
    assert (parts.sequence () == generator.sequenceOf (id));
}

void testMonotonicUnique () {
    var generator = new Snowflake (1);
    var seen = new HashSet<string> (GLib.str_hash, GLib.str_equal);

    int64 previous = -1L;
    for (int i = 0; i < 3000; i++) {
        int64 current = generator.nextId ();
        assert (current > previous);

        string key = current.to_string ();
        assert (seen.add (key) == true);
        previous = current;
    }

    assert ((int) seen.size () == 3000);
}

void testWithEpoch () {
    Vala.Time.DateTime epoch = Vala.Time.DateTime.of (2024, 1, 1, 0, 0, 0);
    var generator = new Snowflake (9).withEpoch (epoch);
    int64 id = generator.nextId ();

    int64 timestamp = generator.timestampMillis (id);
    int64 epochMillis = epoch.toUnixTimestamp () * 1000L;
    assert (timestamp >= epochMillis);
    assert (generator.nodeIdOf (id) == 9);
}

void testNextString () {
    var generator = new Snowflake (3);
    string idText = generator.nextString ();
    int64 id = int64.parse (idText);

    assert (idText.length > 0);
    assert (id > 0);
    assert (generator.nodeIdOf (id) == 3);
}
