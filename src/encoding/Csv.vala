using Vala.Io;

namespace Vala.Encoding {
    /**
     * Static utility methods for CSV parsing and writing.
     *
     * Example:
     * {{{
     *     string csv = "name,age\nalice,20";
     *     var rows = Csv.parse (csv);
     *     assert (rows.get (0).get (0) == "name");
     * }}}
     */
    public class Csv : GLib.Object {
        /**
         * Parses CSV text into a list of rows.
         *
         * Supported features:
         * - comma delimiter
         * - quoted fields with escaped quotes ("")
         * - line breaks inside quoted fields
         *
         * Returns an empty list when the input is malformed
         * (for example, unclosed quotes).
         *
         * @param csv CSV text.
         * @return parsed rows and columns.
         */
        public static Vala.Collections.ArrayList<Vala.Collections.ArrayList<string> > parse (string csv) {
            var rows = new Vala.Collections.ArrayList<Vala.Collections.ArrayList<string> > ();
            if (csv.length == 0) {
                return rows;
            }

            var currentRow = new Vala.Collections.ArrayList<string>(GLib.str_equal);
            var currentField = new GLib.StringBuilder ();
            bool inQuotes = false;

            for (int i = 0; i < csv.length; i++) {
                char c = csv[i];

                if (inQuotes) {
                    if (c == '"') {
                        if (i + 1 < csv.length && csv[i + 1] == '"') {
                            currentField.append_c ('"');
                            i++;
                        } else {
                            inQuotes = false;
                        }
                    } else {
                        currentField.append_c (c);
                    }
                    continue;
                }

                if (c == '"') {
                    inQuotes = true;
                    continue;
                }

                if (c == ',') {
                    currentRow.add (currentField.str);
                    currentField = new GLib.StringBuilder ();
                    continue;
                }

                if (c == '\n' || c == '\r') {
                    if (c == '\r' && i + 1 < csv.length && csv[i + 1] == '\n') {
                        i++;
                    }
                    currentRow.add (currentField.str);
                    rows.add (currentRow);
                    currentRow = new Vala.Collections.ArrayList<string>(GLib.str_equal);
                    currentField = new GLib.StringBuilder ();
                    continue;
                }

                currentField.append_c (c);
            }

            if (inQuotes) {
                return new Vala.Collections.ArrayList<Vala.Collections.ArrayList<string> > ();
            }

            if (currentRow.size () > 0 || currentField.len > 0 || csv[csv.length - 1] == ',') {
                currentRow.add (currentField.str);
                rows.add (currentRow);
            }
            return rows;
        }

        /**
         * Parses a CSV file into a list of rows.
         *
         * @param path path to CSV file.
         * @return parsed rows and columns, or empty list on read/parse error.
         */
        public static Vala.Collections.ArrayList<Vala.Collections.ArrayList<string> > parseFile (Vala.Io.Path path) {
            string ? csv = Files.readAllText (path);
            if (csv == null) {
                return new Vala.Collections.ArrayList<Vala.Collections.ArrayList<string> > ();
            }
            return parse (csv);
        }

        /**
         * Serializes rows/columns to CSV text.
         *
         * Fields containing separator, quote, or line breaks are quoted.
         * Quotes inside fields are escaped as double quotes.
         *
         * @param data rows and columns to serialize.
         * @param separator field separator (for example ",").
         * @return CSV text.
         */
        public static string write (Vala.Collections.ArrayList<Vala.Collections.ArrayList<string> > data,
                                    string separator) {
            if (separator.length == 0) {
                error ("separator must not be empty");
            }

            var builder = new GLib.StringBuilder ();
            for (int i = 0; i < (int) data.size (); i++) {
                Vala.Collections.ArrayList<string> ? row = data.get (i);
                if (row == null) {
                    continue;
                }

                for (int j = 0; j < (int) row.size (); j++) {
                    if (j > 0) {
                        builder.append (separator);
                    }
                    string ? field = row.get (j);
                    builder.append (escapeField (field ?? "", separator));
                }
                if (i + 1 < (int) data.size ()) {
                    builder.append_c ('\n');
                }
            }
            return builder.str;
        }

        private static string escapeField (string field, string separator) {
            bool needsQuotes = field.contains (separator) ||
                               field.contains ("\"") ||
                               field.contains ("\n") ||
                               field.contains ("\r");
            if (!needsQuotes) {
                return field;
            }
            return "\"" + field.replace ("\"", "\"\"") + "\"";
        }
    }
}
