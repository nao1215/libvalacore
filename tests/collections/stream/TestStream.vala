using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/collections/stream/testFromList", testFromList);
    Test.add_func ("/collections/stream/testEmpty", testEmpty);
    Test.add_func ("/collections/stream/testOf", testOf);
    Test.add_func ("/collections/stream/testRange", testRange);
    Test.add_func ("/collections/stream/testRangeClosed", testRangeClosed);
    Test.add_func ("/collections/stream/testGenerate", testGenerate);
    Test.add_func ("/collections/stream/testFilter", testFilter);
    Test.add_func ("/collections/stream/testMap", testMap);
    Test.add_func ("/collections/stream/testFlatMap", testFlatMap);
    Test.add_func ("/collections/stream/testSorted", testSorted);
    Test.add_func ("/collections/stream/testDistinct", testDistinct);
    Test.add_func ("/collections/stream/testLimit", testLimit);
    Test.add_func ("/collections/stream/testSkip", testSkip);
    Test.add_func ("/collections/stream/testTakeWhile", testTakeWhile);
    Test.add_func ("/collections/stream/testDropWhile", testDropWhile);
    Test.add_func ("/collections/stream/testPeek", testPeek);
    Test.add_func ("/collections/stream/testCount", testCount);
    Test.add_func ("/collections/stream/testFindFirst", testFindFirst);
    Test.add_func ("/collections/stream/testFindLast", testFindLast);
    Test.add_func ("/collections/stream/testAnyMatch", testAnyMatch);
    Test.add_func ("/collections/stream/testAllMatch", testAllMatch);
    Test.add_func ("/collections/stream/testNoneMatch", testNoneMatch);
    Test.add_func ("/collections/stream/testReduce", testReduce);
    Test.add_func ("/collections/stream/testForEach", testForEach);
    Test.add_func ("/collections/stream/testToArray", testToArray);
    Test.add_func ("/collections/stream/testToHashSet", testToHashSet);
    Test.add_func ("/collections/stream/testToMap", testToMap);
    Test.add_func ("/collections/stream/testJoining", testJoining);
    Test.add_func ("/collections/stream/testFirstOr", testFirstOr);
    Test.add_func ("/collections/stream/testGroupBy", testGroupBy);
    Test.add_func ("/collections/stream/testPartitionBy", testPartitionBy);
    Test.add_func ("/collections/stream/testSumInt", testSumInt);
    Test.add_func ("/collections/stream/testSumDouble", testSumDouble);
    Test.add_func ("/collections/stream/testAverage", testAverage);
    Test.add_func ("/collections/stream/testMinMax", testMinMax);
    Test.add_func ("/collections/stream/testChaining", testChaining);
    Test.add_func ("/collections/stream/testEmptyBoundary", testEmptyBoundary);
    Test.run ();
}

ArrayList<string> stringList (string[] items) {
    var list = new ArrayList<string> (GLib.str_equal);
    foreach (string s in items) {
        list.add (s);
    }
    return list;
}

void testFromList () {
    var list = stringList ({ "a", "b", "c" });
    var s = Stream.fromList<string> (list);
    assert (s.count () == 3);
}

void testEmpty () {
    var s = Stream.empty<string> ();
    assert (s.count () == 0);
}

void testOf () {
    var s = Stream.of<string> ({ "a", "b", "c" });
    assert (s.count () == 3);
    assert (s.findFirst () == "a");
}

void testRange () {
    var result = Stream.range (2, 6).toList ();
    assert (result.size () == 4);
    assert (result.get (0) == 2);
    assert (result.get (3) == 5);

    var empty = Stream.range (3, 3).toList ();
    assert (empty.size () == 0);
}

void testRangeClosed () {
    var result = Stream.rangeClosed (2, 6).toList ();
    assert (result.size () == 5);
    assert (result.get (0) == 2);
    assert (result.get (4) == 6);

    var empty = Stream.rangeClosed (5, 4).toList ();
    assert (empty.size () == 0);
}

void testGenerate () {
    int n = 0;
    var result = Stream.generate<int> (() => {
        n++;
        return n;
    }, 3).toList ();
    assert (result.size () == 3);
    assert (result.get (0) == 1);
    assert (result.get (2) == 3);

    var empty = Stream.generate<int> (() => { return 1; }, 0).toList ();
    assert (empty.size () == 0);
}

void testFilter () {
    var list = stringList ({ "apple", "banana", "avocado", "cherry" });
    var result = Stream.fromList<string> (list)
                  .filter ((s) => { return s.has_prefix ("a"); })
                  .toList ();
    assert (result.size () == 2);
    assert (result.get (0) == "apple");
    assert (result.get (1) == "avocado");
}

void testMap () {
    var list = stringList ({ "hello", "world" });
    var result = Stream.fromList<string> (list)
                  .map<string> ((s) => { return s.up (); })
                  .toList ();
    assert (result.size () == 2);
    assert (result.get (0) == "HELLO");
    assert (result.get (1) == "WORLD");
}

void testFlatMap () {
    var list = stringList ({ "a,b", "c" });
    var result = Stream.fromList<string> (list)
                  .flatMap<string> ((s) => {
        return Stream.of<string> (s.split (","));
    })
                  .toList ();
    assert (result.size () == 3);
    assert (result.get (0) == "a");
    assert (result.get (1) == "b");
    assert (result.get (2) == "c");
}

void testSorted () {
    var list = stringList ({ "cherry", "apple", "banana" });
    var result = Stream.fromList<string> (list)
                  .sorted ((a, b) => { return strcmp (a, b); })
                  .toList ();
    assert (result.get (0) == "apple");
    assert (result.get (1) == "banana");
    assert (result.get (2) == "cherry");
}

void testDistinct () {
    var list = stringList ({ "a", "b", "a", "c", "b" });
    var result = Stream.fromList<string> (list)
                  .distinct (GLib.str_equal)
                  .toList ();
    assert (result.size () == 3);
    assert (result.get (0) == "a");
    assert (result.get (1) == "b");
    assert (result.get (2) == "c");
}

void testLimit () {
    var list = stringList ({ "a", "b", "c", "d", "e" });
    var result = Stream.fromList<string> (list).limit (3).toList ();
    assert (result.size () == 3);
    assert (result.get (2) == "c");

    var all = Stream.fromList<string> (list).limit (100).toList ();
    assert (all.size () == 5);

    var neg = Stream.fromList<string> (list).limit (-1).toList ();
    assert (neg.size () == 0);
}

void testSkip () {
    var list = stringList ({ "a", "b", "c", "d", "e" });
    var result = Stream.fromList<string> (list).skip (2).toList ();
    assert (result.size () == 3);
    assert (result.get (0) == "c");

    var none = Stream.fromList<string> (list).skip (100).toList ();
    assert (none.size () == 0);

    var negative = Stream.fromList<string> (list).skip (-2).toList ();
    assert (negative.size () == 5);
    assert (negative.get (0) == "a");
}

void testTakeWhile () {
    var list = stringList ({ "aa", "ab", "ba", "bb" });
    var result = Stream.fromList<string> (list)
                  .takeWhile ((s) => { return s.has_prefix ("a"); })
                  .toList ();
    assert (result.size () == 2);
    assert (result.get (0) == "aa");
    assert (result.get (1) == "ab");
}

void testDropWhile () {
    var list = stringList ({ "aa", "ab", "ba", "bb" });
    var result = Stream.fromList<string> (list)
                  .dropWhile ((s) => { return s.has_prefix ("a"); })
                  .toList ();
    assert (result.size () == 2);
    assert (result.get (0) == "ba");
    assert (result.get (1) == "bb");
}

void testPeek () {
    var list = stringList ({ "a", "b", "c" });
    int peekCount = 0;
    var result = Stream.fromList<string> (list)
                  .peek ((s) => { peekCount++; })
                  .toList ();
    assert (peekCount == 3);
    assert (result.size () == 3);
}

void testCount () {
    var list = stringList ({ "a", "b", "c" });
    assert (Stream.fromList<string> (list).count () == 3);
    assert (Stream.empty<string> ().count () == 0);
}

void testFindFirst () {
    var list = stringList ({ "x", "y", "z" });
    assert (Stream.fromList<string> (list).findFirst () == "x");
    assert (Stream.empty<string> ().findFirst () == null);
}

void testFindLast () {
    var list = stringList ({ "x", "y", "z" });
    assert (Stream.fromList<string> (list).findLast () == "z");
    assert (Stream.empty<string> ().findLast () == null);
}

void testAnyMatch () {
    var list = stringList ({ "apple", "banana", "cherry" });
    assert (Stream.fromList<string> (list).anyMatch ((s) => {
        return s == "banana";
    }) == true);
    assert (Stream.fromList<string> (list).anyMatch ((s) => {
        return s == "grape";
    }) == false);
    assert (Stream.empty<string> ().anyMatch ((s) => { return true; }) == false);
}

void testAllMatch () {
    var list = stringList ({ "apple", "avocado", "apricot" });
    assert (Stream.fromList<string> (list).allMatch ((s) => {
        return s.has_prefix ("a");
    }) == true);
    assert (Stream.fromList<string> (list).allMatch ((s) => {
        return s == "apple";
    }) == false);
    assert (Stream.empty<string> ().allMatch ((s) => { return false; }) == true);
}

void testNoneMatch () {
    var list = stringList ({ "apple", "banana", "cherry" });
    assert (Stream.fromList<string> (list).noneMatch ((s) => {
        return s == "grape";
    }) == true);
    assert (Stream.fromList<string> (list).noneMatch ((s) => {
        return s == "banana";
    }) == false);
    assert (Stream.empty<string> ().noneMatch ((s) => { return true; }) == true);
}

void testReduce () {
    var list = stringList ({ "a", "b", "c" });
    string joined = Stream.fromList<string> (list).reduce<string> ("", (acc, s) => {
        if (acc == "") {
            return s;
        }
        return acc + "," + s;
    });
    assert (joined == "a,b,c");

    string empty = Stream.empty<string> ().reduce<string> ("x", (acc, s) => {
        return acc + s;
    });
    assert (empty == "x");
}

void testForEach () {
    var list = stringList ({ "a", "b", "c" });
    int count = 0;
    Stream.fromList<string> (list).forEach ((s) => {
        count++;
    });
    assert (count == 3);
}

void testToArray () {
    var list = stringList ({ "x", "y", "z" });
    string[] arr = Stream.fromList<string> (list).toArray ();
    assert (arr.length == 3);
    assert (arr[0] == "x");
    assert (arr[2] == "z");
}

void testToHashSet () {
    var list = stringList ({ "a", "b", "a", "c" });
    var set = Stream.fromList<string> (list).toHashSet (GLib.str_hash, GLib.str_equal);
    assert (set.size () == 3);
    assert (set.contains ("a"));
    assert (set.contains ("b"));
    assert (set.contains ("c"));
}

void testToMap () {
    var list = stringList ({ "apple", "banana" });
    var map = Stream.fromList<string> (list).toMap<string, int> (
        (s) => { return s; },
        (s) => { return s.length; },
        GLib.str_hash,
        GLib.str_equal
    );
    assert (map.size () == 2);
    int ? appleLen = map.get ("apple");
    int ? bananaLen = map.get ("banana");
    assert (appleLen != null && appleLen == 5);
    assert (bananaLen != null && bananaLen == 6);
}

void testJoining () {
    var list = stringList ({ "a", "b", "c" });
    string joined = Stream.fromList<string> (list).joining (",");
    assert (joined == "a,b,c");
    assert (Stream.empty<string> ().joining (",") == "");
}

void testFirstOr () {
    var list = stringList ({ "x", "y" });
    assert (Stream.fromList<string> (list).firstOr ("fallback") == "x");
    assert (Stream.empty<string> ().firstOr ("fallback") == "fallback");
}

void testGroupBy () {
    var list = stringList ({ "apple", "avocado", "banana" });
    var groups = Stream.fromList<string> (list).groupBy<string> (
        (s) => { return s.substring (0, 1); },
        GLib.str_hash,
        GLib.str_equal
    );
    assert (groups.size () == 2);
    var aGroup = groups.get ("a");
    var bGroup = groups.get ("b");
    assert (aGroup != null && aGroup.size () == 2);
    assert (bGroup != null && bGroup.size () == 1);
}

void testPartitionBy () {
    var list = stringList ({ "a", "bb", "ccc", "d" });
    var pair = Stream.fromList<string> (list).partitionBy ((s) => {
        return s.length >= 2;
    });
    assert (pair.first ().size () == 2);
    assert (pair.second ().size () == 2);
    assert (pair.first ().get (0) == "bb");
    assert (pair.second ().get (0) == "a");
}

void testSumInt () {
    var list = stringList ({ "aa", "bbb", "c" });
    int total = Stream.fromList<string> (list).sumInt ((s) => {
        return s.length;
    });
    assert (total == 6);
    assert (Stream.empty<string> ().sumInt ((s) => { return s.length; }) == 0);
}

void testSumDouble () {
    var list = Stream.rangeClosed (1, 4);
    double total = list.sumDouble ((n) => {
        return (double) n * 0.5;
    });
    assert (total == 5.0);
}

void testAverage () {
    var list = Stream.rangeClosed (1, 3).map<int> ((n) => {
        return n * 2;
    });
    double ? avg = list.average ((n) => {
        return (double) n;
    });
    assert (avg != null && avg == 4.0);
    assert (Stream.empty<int> ().average ((n) => { return (double) n; }) == null);
}

void testMinMax () {
    var list = stringList ({ "banana", "apple", "cherry" });
    string ? min = Stream.fromList<string> (list).min ((a, b) => {
        return strcmp (a, b);
    });
    assert (min == "apple");

    string ? max = Stream.fromList<string> (list).max ((a, b) => {
        return strcmp (a, b);
    });
    assert (max == "cherry");

    assert (Stream.empty<string> ().min ((a, b) => { return 0; }) == null);
    assert (Stream.empty<string> ().max ((a, b) => { return 0; }) == null);
}

void testChaining () {
    var list = stringList ({
        "apple", "banana", "avocado", "cherry", "apricot", "blueberry"
    });
    var result = Stream.fromList<string> (list)
                  .filter ((s) => { return s.has_prefix ("a"); })
                  .sorted ((a, b) => { return strcmp (a, b); })
                  .limit (2)
                  .toList ();
    assert (result.size () == 2);
    assert (result.get (0) == "apple");
    assert (result.get (1) == "apricot");
}

void testEmptyBoundary () {
    var empty = Stream.empty<string> ();
    assert (empty.filter ((s) => { return true; }).count () == 0);
    assert (empty.limit (5).count () == 0);
    assert (empty.skip (5).count () == 0);
    assert (empty.takeWhile ((s) => { return true; }).count () == 0);
    assert (empty.dropWhile ((s) => { return true; }).count () == 0);
}
