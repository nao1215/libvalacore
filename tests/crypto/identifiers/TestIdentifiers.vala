using Vala.Crypto;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/crypto/identifiers/testUuidV4", testUuidV4);
    Test.add_func ("/crypto/identifiers/testUuidV7", testUuidV7);
    Test.add_func ("/crypto/identifiers/testUlidMonotonic", testUlidMonotonic);
    Test.add_func ("/crypto/identifiers/testKsuid", testKsuid);
    Test.add_func ("/crypto/identifiers/testRoundTrip", testRoundTrip);
    Test.add_func ("/crypto/identifiers/testInvalidInputs", testInvalidInputs);
    Test.run ();
}

void testUuidV4 () {
    string id = Identifiers.uuidV4 ();
    assert (Identifiers.isUuid (id));
    assert (id.substring (14, 1) == "4");

    Identifier ? parsed = Identifiers.parseUuid (id);
    assert (parsed != null);
    assert (parsed.type () == IdentifierType.UUID_V4);
    assert (parsed.value () == id.down ());
}

void testUuidV7 () {
    string a = Identifiers.uuidV7 ();
    Posix.usleep (2000);
    string b = Identifiers.uuidV7 ();

    assert (Identifiers.isUuid (a));
    assert (Identifiers.isUuid (b));
    assert (a.substring (14, 1) == "7");
    assert (b.substring (14, 1) == "7");

    int64 ? ta = Identifiers.timestampMillis (a);
    int64 ? tb = Identifiers.timestampMillis (b);
    assert (ta != null);
    assert (tb != null);
    assert (tb >= ta);
    assert (Identifiers.compareByTime (a, b) <= 0);

    Identifier ? parsed = Identifiers.parseUuid (a);
    assert (parsed != null);
    assert (parsed.type () == IdentifierType.UUID_V7);
}

void testUlidMonotonic () {
    string a = Identifiers.ulidMonotonic ();
    string b = Identifiers.ulidMonotonic ();

    assert (Identifiers.isUlid (a));
    assert (Identifiers.isUlid (b));
    assert (Identifiers.compareByTime (a, b) <= 0);

    Identifier ? parsed = Identifiers.parseUlid (a);
    assert (parsed != null);
    assert (parsed.type () == IdentifierType.ULID);
    assert (parsed.value () == a);
}

void testKsuid () {
    string id = Identifiers.ksuid ();
    assert (Identifiers.isKsuid (id));

    int64 ? ts = Identifiers.timestampMillis (id);
    assert (ts != null);
    assert (ts > 0);

    Identifier ? parsed = Identifiers.parseKsuid (id);
    assert (parsed != null);
    assert (parsed.type () == IdentifierType.KSUID);
    assert (parsed.value () == id);
}

void testRoundTrip () {
    string v7 = Identifiers.uuidV7 ();
    uint8[] ? v7Bytes = Identifiers.toBytes (v7);
    assert (v7Bytes != null);
    string ? v7Text = Identifiers.fromBytes (v7Bytes, "uuid_v7");
    assert (v7Text != null);
    assert (v7Text == v7);

    string ulid = Identifiers.ulid ();
    uint8[] ? ulidBytes = Identifiers.toBytes (ulid);
    assert (ulidBytes != null);
    string ? ulidText = Identifiers.fromBytes (ulidBytes, "ulid");
    assert (ulidText != null);
    assert (ulidText == ulid);

    string ksuid = Identifiers.ksuid ();
    uint8[] ? ksuidBytes = Identifiers.toBytes (ksuid);
    assert (ksuidBytes != null);
    string ? ksuidText = Identifiers.fromBytes (ksuidBytes, "ksuid");
    assert (ksuidText != null);
    assert (ksuidText == ksuid);
}

void testInvalidInputs () {
    assert (Identifiers.isUuid ("not-a-uuid") == false);
    assert (Identifiers.isUlid ("01ARZ3NDEKTSV4RRFFQ69G5FAV!") == false);
    assert (Identifiers.isKsuid ("invalid-ksuid") == false);

    assert (Identifiers.parseUuid ("invalid") == null);
    assert (Identifiers.parseUlid ("invalid") == null);
    assert (Identifiers.parseKsuid ("invalid") == null);

    assert (Identifiers.toBytes ("nope") == null);
    assert (Identifiers.fromBytes (new uint8[10], "ksuid") == null);
    assert (Identifiers.fromBytes (new uint8[16], "unknown") == null);

    string v4 = Identifiers.uuidV4 ();
    assert (Identifiers.timestampMillis (v4) == null);
}
