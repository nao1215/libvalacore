using Vala.Collections;
using Vala.Distributed;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/distributed/snowflake/testBasic", testBasic);
    Test.add_func ("/distributed/snowflake/testMonotonicUnique", testMonotonicUnique);
    Test.add_func ("/distributed/snowflake/testWithEpoch", testWithEpoch);
    Test.add_func ("/distributed/snowflake/testNextString", testNextString);
    Test.add_func ("/distributed/snowflake/testInvalidArguments", testInvalidArguments);

    Test.run ();
}

Vala.Time.DateTime createDateTime (int year,
                                   int month,
                                   int day,
                                   int hour,
                                   int min,
                                   int sec) {
    try {
        return Vala.Time.DateTime.of (year, month, day, hour, min, sec);
    } catch (Vala.Time.DateTimeError e) {
        assert_not_reached ();
    }
}

Snowflake createGenerator (int node_id) {
    var created = Snowflake.of (node_id);
    assert (created.isOk ());
    return created.unwrap ();
}

void testBasic () {
    var generator = createGenerator (7);
    var idResult = generator.nextId ();
    assert (idResult.isOk ());
    int64 id = idResult.unwrap ();

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
    var generator = createGenerator (1);
    var seen = new HashSet<string> (GLib.str_hash, GLib.str_equal);

    int64 previous = -1L;
    for (int i = 0; i < 3000; i++) {
        var currentResult = generator.nextId ();
        assert (currentResult.isOk ());
        int64 current = currentResult.unwrap ();
        assert (current > previous);

        string key = current.to_string ();
        assert (seen.add (key) == true);
        previous = current;
    }

    assert ((int) seen.size () == 3000);
}

void testWithEpoch () {
    Vala.Time.DateTime epoch = createDateTime (2024, 1, 1, 0, 0, 0);
    var generator = createGenerator (9).withEpoch (epoch);
    var idResult = generator.nextId ();
    assert (idResult.isOk ());
    int64 id = idResult.unwrap ();

    int64 timestamp = generator.timestampMillis (id);
    int64 epochMillis = epoch.toUnixTimestamp () * 1000L;
    assert (timestamp >= epochMillis);
    assert (generator.nodeIdOf (id) == 9);
}

void testNextString () {
    var generator = createGenerator (3);
    var textResult = generator.nextString ();
    assert (textResult.isOk ());
    string idText = textResult.unwrap ();
    int64 id = int64.parse (idText);

    assert (idText.length > 0);
    assert (id > 0);
    assert (generator.nodeIdOf (id) == 3);
}

void testInvalidArguments () {
    var invalidNode = Snowflake.of (-1);
    assert (invalidNode.isError ());
    assert (invalidNode.unwrapError () is SnowflakeError.INVALID_ARGUMENT);

    Vala.Time.DateTime future = createDateTime (3000, 1, 1, 0, 0, 0);
    Snowflake clockGenerator = createGenerator (1).withEpoch (future);
    var clockResult = clockGenerator.nextId ();
    assert (clockResult.isError ());
    assert (clockResult.unwrapError () is SnowflakeError.CLOCK_BEFORE_EPOCH);

    Vala.Time.DateTime oldEpoch = createDateTime (1900, 1, 1, 0, 0, 0);
    Snowflake overflowGenerator = createGenerator (1).withEpoch (oldEpoch);
    var overflowResult = overflowGenerator.nextId ();
    assert (overflowResult.isError ());
    assert (overflowResult.unwrapError () is SnowflakeError.TIMESTAMP_OVERFLOW);
}
