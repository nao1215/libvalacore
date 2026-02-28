using Vala.Parser;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/testBuilderDefaults", testBuilderDefaults);
    Test.add_func ("/testBuilderChaining", testBuilderChaining);
    Test.add_func ("/testAddOption", testAddOption);
    Test.add_func ("/testParseShortOption", testParseShortOption);
    Test.add_func ("/testParseLongOption", testParseLongOption);
    Test.add_func ("/testParseMultipleOptions", testParseMultipleOptions);
    Test.add_func ("/testHasOptionTrue", testHasOptionTrue);
    Test.add_func ("/testHasOptionFalse", testHasOptionFalse);
    Test.add_func ("/testHasOptionUnregistered", testHasOptionUnregistered);
    Test.add_func ("/testCopyArgWithoutCmdNameAndOptions", testCopyArgWithoutCmdNameAndOptions);
    Test.add_func ("/testCopyArgEmpty", testCopyArgEmpty);
    Test.add_func ("/testParseResultBeforeParse", testParseResultBeforeParse);
    Test.add_func ("/testParseResultAfterParse", testParseResultAfterParse);
    Test.add_func ("/testParseResultNoArgs", testParseResultNoArgs);
    Test.add_func ("/testUsage", testUsage);
    Test.add_func ("/testShowVersion", testShowVersion);
    Test.add_func ("/testUsageWithDescription", testUsageWithDescription);
    Test.add_func ("/testParseNoOptions", testParseNoOptions);
    Test.add_func ("/testParseOnlyArgs", testParseOnlyArgs);
    Test.run ();
}

ArgParser createTestParser () {
    return new ArgParser.Builder ()
            .applicationName ("testapp")
            .applicationArgument ("FILE")
            .description ("A test application for unit testing.")
            .version ("1.0.0")
            .author ("Test Author")
            .contact ("https://example.com")
            .build ();
}

void testBuilderDefaults () {
    var parser = new ArgParser.Builder ().build ();
    /* Builder with no fields set should produce a valid ArgParser */
    parser.parse (new string[] { "" });
    assert (parser.hasOption ("x") == false);
}

void testBuilderChaining () {
    var builder = new ArgParser.Builder ();
    var result = builder
                  .applicationName ("app")
                  .applicationArgument ("ARG")
                  .description ("desc")
                  .version ("2.0")
                  .author ("author")
                  .contact ("contact");
    assert (result.appName == "app");
    assert (result.appArg == "ARG");
    assert (result.desc == "desc");
    assert (result.ver == "2.0");
    assert (result.appAuthor == "author");
    assert (result.appContact == "contact");
}

void testAddOption () {
    var parser = createTestParser ();
    parser.addOption ("h", "help", "Show help");
    parser.addOption ("v", "version", "Show version");
    /* Options added but not parsed yet, should be false */
    assert (parser.hasOption ("h") == false);
    assert (parser.hasOption ("v") == false);
}

void testParseShortOption () {
    var parser = createTestParser ();
    parser.addOption ("h", "help", "Show help");
    parser.addOption ("v", "version", "Show version");
    parser.parse (new string[] { "testapp", "-h" });
    assert (parser.hasOption ("h") == true);
    assert (parser.hasOption ("v") == false);
}

void testParseLongOption () {
    var parser = createTestParser ();
    parser.addOption ("h", "help", "Show help");
    parser.addOption ("v", "version", "Show version");
    parser.parse (new string[] { "testapp", "--version" });
    assert (parser.hasOption ("h") == false);
    assert (parser.hasOption ("v") == true);
}

void testParseMultipleOptions () {
    var parser = createTestParser ();
    parser.addOption ("h", "help", "Show help");
    parser.addOption ("v", "version", "Show version");
    parser.addOption ("d", "debug", "Debug mode");
    parser.parse (new string[] { "testapp", "-h", "--debug" });
    assert (parser.hasOption ("h") == true);
    assert (parser.hasOption ("v") == false);
    assert (parser.hasOption ("d") == true);
}

void testHasOptionTrue () {
    var parser = createTestParser ();
    parser.addOption ("o", "output", "Output file");
    parser.parse (new string[] { "testapp", "-o" });
    assert (parser.hasOption ("o") == true);
}

void testHasOptionFalse () {
    var parser = createTestParser ();
    parser.addOption ("o", "output", "Output file");
    parser.parse (new string[] { "testapp" });
    assert (parser.hasOption ("o") == false);
}

void testHasOptionUnregistered () {
    var parser = createTestParser ();
    parser.addOption ("o", "output", "Output file");
    parser.parse (new string[] { "testapp", "-x" });
    /* -x was not registered, so hasOption("x") returns false */
    assert (parser.hasOption ("x") == false);
}

void testCopyArgWithoutCmdNameAndOptions () {
    var parser = createTestParser ();
    parser.addOption ("h", "help", "Show help");
    parser.addOption ("d", "debug", "Debug mode");
    parser.parse (new string[] { "testapp", "-h", "file1.txt", "--debug", "file2.txt" });
    var args = parser.copyArgWithoutCmdNameAndOptions ();
    assert (args.length () == 2);
    assert (args.nth_data (0) == "file1.txt");
    assert (args.nth_data (1) == "file2.txt");
}

void testCopyArgEmpty () {
    var parser = createTestParser ();
    parser.addOption ("h", "help", "Show help");
    parser.parse (new string[] { "testapp", "-h" });
    var args = parser.copyArgWithoutCmdNameAndOptions ();
    assert (args.length () == 0);
}

void testParseResultBeforeParse () {
    var parser = createTestParser ();
    parser.addOption ("h", "help", "Show help");
    string result = parser.parseResult ();
    assert (result == "No result: Before parsing");
}

void testParseResultAfterParse () {
    var parser = createTestParser ();
    parser.addOption ("h", "help", "Show help");
    parser.addOption ("v", "version", "Show version");
    parser.parse (new string[] { "testapp", "-h", "arg1" });
    string result = parser.parseResult ();
    assert (result.contains ("[Options]"));
    assert (result.contains ("ON :"));
    assert (result.contains ("OFF:"));
    assert (result.contains ("[Arguments]"));
    assert (result.contains ("arg1"));
}

void testParseResultNoArgs () {
    var parser = createTestParser ();
    parser.addOption ("h", "help", "Show help");
    parser.parse (new string[] { "testapp", "-h" });
    string result = parser.parseResult ();
    assert (result.contains ("NO ARGUMENTS."));
}

void testUsage () {
    var parser = createTestParser ();
    parser.addOption ("h", "help", "Show help");
    parser.addOption ("v", "version", "Show version");
    /* usage() prints to stdout; calling it exercises the code paths */
    parser.usage ();
}

void testShowVersion () {
    var parser = createTestParser ();
    parser.showVersion ();
}

void testUsageWithDescription () {
    /* Test with empty description to hit the isNullOrEmpty branch */
    var parser = new ArgParser.Builder ()
                  .applicationName ("app")
                  .applicationArgument ("ARG")
                  .description ("")
                  .version ("1.0")
                  .author ("author")
                  .contact ("contact")
                  .build ();
    parser.addOption ("h", "help", "Show help");
    parser.usage ();
}

void testParseNoOptions () {
    var parser = createTestParser ();
    /* Parse with no registered options */
    parser.parse (new string[] { "testapp", "arg1", "arg2" });
    var args = parser.copyArgWithoutCmdNameAndOptions ();
    assert (args.length () == 2);
}

void testParseOnlyArgs () {
    var parser = createTestParser ();
    parser.addOption ("h", "help", "Show help");
    parser.parse (new string[] { "/usr/bin/testapp", "hello", "world" });
    assert (parser.hasOption ("h") == false);
    var args = parser.copyArgWithoutCmdNameAndOptions ();
    assert (args.length () == 2);
    assert (args.nth_data (0) == "hello");
    assert (args.nth_data (1) == "world");
}
