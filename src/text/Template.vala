using Vala.Collections;
using Vala.Encoding;

namespace Vala.Text {
    /**
     * Represents a segment in a compiled template.
     */
    internal class TemplateSegment : GLib.Object {
        internal enum Kind {
            LITERAL,
            VARIABLE,
            IF_BLOCK,
            EACH_BLOCK,
            FALLBACK
        }

        internal Kind kind;
        internal string text;
        internal string ? filter;
        internal string ? fallback_value;
        internal TemplateSegment[] children;
        internal TemplateSegment[] else_children;

        internal TemplateSegment (Kind kind, string text) {
            this.kind = kind;
            this.text = text;
            this.filter = null;
            this.fallback_value = null;
            this.children = {};
            this.else_children = {};
        }
    }

    /**
     * A pre-compiled template for repeated rendering.
     *
     * Compiled templates parse the template string once and reuse
     * the parsed structure across multiple render calls.
     *
     * Example:
     * {{{
     *     string tpl = "Hello, " + "{{na" + "me}}!";
     *     var tmpl = Template.compile (tpl);
     *     var vars = new HashMap<string, string> (str_hash, str_equal);
     *     vars.put ("name", "World");
     *     string result = tmpl.render (vars); // "Hello, World!"
     * }}}
     */
    public class CompiledTemplate : GLib.Object {
        private TemplateSegment[] _segments;

        internal CompiledTemplate (TemplateSegment[] segments) {
            _segments = segments;
        }

        /**
         * Renders the compiled template with the given variables.
         *
         * Example:
         * {{{
         *     string tpl = "{{gree" + "ting}}, {{na" + "me}}!";
         *     var tmpl = Template.compile (tpl);
         *     var vars = new HashMap<string, string> (str_hash, str_equal);
         *     vars.put ("greeting", "Hello");
         *     vars.put ("name", "World");
         *     string result = tmpl.render (vars);
         * }}}
         *
         * @param vars variable map for substitution.
         * @return rendered string.
         */
        public string render (HashMap<string, string> vars) {
            var sb = new GLib.StringBuilder ();
            renderSegments (_segments, vars, null, sb);
            return sb.str;
        }

        /**
         * Renders the compiled template using a JSON object as variables.
         *
         * Top-level string values in the JSON object are used as template
         * variables.
         *
         * Example:
         * {{{
         *     string tpl = "Hello, " + "{{na" + "me}}!";
         *     var tmpl = Template.compile (tpl);
         *     var json = Json.parse ("{\"name\": \"World\"}");
         *     string result = tmpl.renderJson (json);
         * }}}
         *
         * @param vars JSON object whose string values are used as variables.
         * @return rendered string.
         */
        public string renderJson (JsonValue vars) {
            var map = Template.jsonToMap (vars);
            return render (map);
        }

        private static void renderSegments (TemplateSegment[] segments,
                                            HashMap<string, string> vars,
                                            string ? loopItem,
                                            GLib.StringBuilder sb) {
            foreach (TemplateSegment seg in segments) {
                switch (seg.kind) {
                    case TemplateSegment.Kind.LITERAL:
                        sb.append (seg.text);
                        break;
                    case TemplateSegment.Kind.VARIABLE:
                        string ? val = null;
                        if (seg.text == ".") {
                            val = loopItem;
                        } else {
                            val = vars.get (seg.text);
                        }
                        if (val != null) {
                            sb.append (applyFilter (val, seg.filter));
                        }
                        break;
                    case TemplateSegment.Kind.IF_BLOCK:
                        string ? condVal = vars.get (seg.text);
                        if (condVal != null && condVal.length > 0
                            && condVal != "false" && condVal != "0") {
                            renderSegments (seg.children, vars, loopItem, sb);
                        } else {
                            renderSegments (seg.else_children, vars, loopItem, sb);
                        }
                        break;
                    case TemplateSegment.Kind.EACH_BLOCK:
                        string ? listVal = vars.get (seg.text);
                        if (listVal != null && listVal.length > 0) {
                            string[] items = listVal.split (",");
                            foreach (string item in items) {
                                string trimmed = item.strip ();
                                renderSegments (seg.children, vars, trimmed, sb);
                            }
                        }
                        break;
                    case TemplateSegment.Kind.FALLBACK:
                        string ? val2 = vars.get (seg.text);
                        if (val2 != null && val2.length > 0) {
                            sb.append (val2);
                        } else if (seg.fallback_value != null) {
                            sb.append (seg.fallback_value);
                        }
                        break;
                }
            }
        }

        private static string applyFilter (string val, string ? filter) {
            if (filter == null) {
                return val;
            }
            switch (filter) {
                case "upper":
                    return val.up ();
                case "lower":
                    return val.down ();
                case "trim":
                    return val.strip ();
                case "escape":
                    return escapeHtml (val);
                default:
                    return val;
            }
        }

        private static string escapeHtml (string input) {
            var sb = new GLib.StringBuilder ();
            int i = 0;
            unichar c;
            while (input.get_next_char (ref i, out c)) {
                switch (c) {
                    case '&':
                        sb.append ("&amp;");
                        break;
                    case '<':
                        sb.append ("&lt;");
                        break;
                    case '>':
                        sb.append ("&gt;");
                        break;
                    case '"':
                        sb.append ("&quot;");
                        break;
                    case '\'':
                        sb.append ("&#39;");
                        break;
                    default:
                        sb.append_unichar (c);
                        break;
                }
            }
            return sb.str;
        }
    }

    /**
     * Simple template engine with Mustache/Handlebars-style syntax.
     *
     * Supports variable substitution, conditionals, loops, filters,
     * and fallback values. Variables use double-brace delimiters.
     * Conditionals use #if / else / /if directives. Loops use
     * #each / /each directives. Filters are applied with the pipe
     * operator (upper, lower, trim, escape). Fallback provides a
     * default value when a variable is missing.
     *
     * Example:
     * {{{
     *     var vars = new HashMap<string, string> (str_hash, str_equal);
     *     vars.put ("name", "World");
     *     string tpl = "Hello, " + "{{na" + "me}}!";
     *     string result = Template.render (tpl, vars);
     * }}}
     */
    public class Template : GLib.Object {
        // Sentinel values used to signal parse stop reason.
        private const string STOP_ELSE = "__STOP_ELSE__";
        private const string STOP_ENDIF = "__STOP_ENDIF__";
        private const string STOP_ENDEACH = "__STOP_ENDEACH__";

        /**
         * Renders a template string with the given variables.
         *
         * Example:
         * {{{
         *     var vars = new HashMap<string, string> (str_hash, str_equal);
         *     vars.put ("user", "Alice");
         *     string tpl = "Hi " + "{{us" + "er}}!";
         *     string result = Template.render (tpl, vars);
         *     // result == "Hi Alice!"
         * }}}
         *
         * @param template template string.
         * @param vars variable map.
         * @return rendered string.
         */
        public static string render (string template, HashMap<string, string> vars) {
            var compiled = compile (template);
            return compiled.render (vars);
        }

        /**
         * Reads a template from a file and renders it with the given variables.
         *
         * Example:
         * {{{
         *     var vars = new HashMap<string, string> (str_hash, str_equal);
         *     vars.put ("title", "Home");
         *     string ? result = Template.renderFile (
         *         new Vala.Io.Path ("/tmp/page.tmpl"), vars);
         * }}}
         *
         * @param templatePath path to the template file.
         * @param vars variable map.
         * @return rendered string, or null if the file cannot be read.
         */
        public static string ? renderFile (Vala.Io.Path templatePath,
                                           HashMap<string, string> vars) {
            string ? content = Vala.Io.Files.readAllText (templatePath);
            if (content == null) {
                return null;
            }
            return render (content, vars);
        }

        /**
         * Renders a template using a JSON object as variables.
         *
         * Top-level string values in the JSON object are extracted as
         * template variables. Array values are joined with commas
         * for use with the #each directive.
         *
         * Example:
         * {{{
         *     var json = Json.parse ("{\"name\": \"World\"}");
         *     string tpl = "Hi " + "{{na" + "me}}!";
         *     string result = Template.renderJson (tpl, json);
         *     // result == "Hi World!"
         * }}}
         *
         * @param template template string.
         * @param vars JSON object containing variables.
         * @return rendered string.
         */
        public static string renderJson (string template, JsonValue vars) {
            var map = jsonToMap (vars);
            return render (template, map);
        }

        /**
         * Pre-compiles a template for repeated rendering.
         *
         * The returned CompiledTemplate can be rendered multiple times
         * with different variable sets without re-parsing.
         *
         * Example:
         * {{{
         *     string tpl = "Hello, " + "{{na" + "me}}!";
         *     var tmpl = Template.compile (tpl);
         *     var v1 = new HashMap<string, string> (str_hash, str_equal);
         *     v1.put ("name", "Alice");
         *     var v2 = new HashMap<string, string> (str_hash, str_equal);
         *     v2.put ("name", "Bob");
         *     assert (tmpl.render (v1) == "Hello, Alice!");
         *     assert (tmpl.render (v2) == "Hello, Bob!");
         * }}}
         *
         * @param template template string.
         * @return compiled template.
         */
        public static CompiledTemplate compile (string template) {
            int pos = 0;
            var merged = new GLib.Array<TemplateSegment> ();

            while (pos < template.length) {
                string ? stopped = null;
                TemplateSegment[] segments = parseSegments (template, ref pos, out stopped);
                for (int i = 0; i < segments.length; i++) {
                    merged.append_val (segments[i]);
                }

                if (stopped == null) {
                    break;
                }

                string literal = stopTokenToLiteral (stopped);
                if (literal.length > 0) {
                    merged.append_val (new TemplateSegment (TemplateSegment.Kind.LITERAL, literal));
                }
            }

            TemplateSegment[] segments = new TemplateSegment[merged.length];
            for (uint i = 0; i < merged.length; i++) {
                segments[i] = merged.index (i);
            }
            return new CompiledTemplate (segments);
        }

        internal static HashMap<string, string> jsonToMap (JsonValue json) {
            var map = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            if (!json.isObject ()) {
                return map;
            }
            ArrayList<string> ? keyList = json.keys ();
            if (keyList == null) {
                return map;
            }
            for (int ki = 0; ki < keyList.size (); ki++) {
                string key = keyList.get (ki);
                JsonValue ? val = json.get (key);
                if (val == null) {
                    continue;
                }
                if (val.isString ()) {
                    map.put (key, val.asString ());
                } else if (val.isNumber ()) {
                    double ? d = val.asDouble ();
                    if (d != null) {
                        int iv = (int) d;
                        if ((double) iv == d) {
                            map.put (key, iv.to_string ());
                        } else {
                            map.put (key, d.to_string ());
                        }
                    }
                } else if (val.isBool ()) {
                    map.put (key, val.asBool () ? "true" : "false");
                } else if (val.isArray ()) {
                    var sb = new GLib.StringBuilder ();
                    for (int i = 0; i < val.size (); i++) {
                        JsonValue ? elem = val.at (i);
                        if (i > 0) {
                            sb.append (",");
                        }
                        if (elem != null && elem.isString ()) {
                            sb.append (elem.asString ());
                        } else if (elem != null) {
                            sb.append (Json.stringify (elem));
                        }
                    }
                    map.put (key, sb.str);
                }
            }
            return map;
        }

        /**
         * Parses template text into segments.
         *
         * Returns when the end of the string is reached, or when a
         * control tag (else, /if, /each) is encountered.
         * The stoppedAt out parameter indicates which tag caused the stop.
         */
        private static TemplateSegment[] parseSegments (string tmpl, ref int pos,
                                                        out string ? stoppedAt) {
            stoppedAt = null;
            var segments = new GLib.Array<TemplateSegment> ();
            var literal = new GLib.StringBuilder ();

            while (pos < tmpl.length) {
                if (pos + 1 < tmpl.length && tmpl[pos] == '{' && tmpl[pos + 1] == '{') {
                    // Flush literal
                    if (literal.len > 0) {
                        segments.append_val (
                            new TemplateSegment (TemplateSegment.Kind.LITERAL, literal.str));
                        literal.truncate (0);
                    }

                    pos += 2;
                    int closeIdx = tmpl.index_of ("}}", pos);
                    if (closeIdx < 0) {
                        literal.append ("{{");
                        literal.append (tmpl.substring (pos));
                        pos = tmpl.length;
                        break;
                    }

                    string tag = tmpl.substring (pos, closeIdx - pos).strip ();
                    pos = closeIdx + 2;

                    if (tag.has_prefix ("#if ")) {
                        string varName = tag.substring (4).strip ();
                        var seg = new TemplateSegment (
                            TemplateSegment.Kind.IF_BLOCK, varName);

                        string ? innerStop = null;
                        seg.children = parseSegments (tmpl, ref pos, out innerStop);

                        if (innerStop == STOP_ELSE) {
                            string ? elseStop = null;
                            seg.else_children = parseSegments (tmpl, ref pos, out elseStop);
                        }
                        segments.append_val (seg);
                    } else if (tag.has_prefix ("#each ")) {
                        string varName = tag.substring (6).strip ();
                        var seg = new TemplateSegment (
                            TemplateSegment.Kind.EACH_BLOCK, varName);

                        string ? innerStop = null;
                        seg.children = parseSegments (tmpl, ref pos, out innerStop);
                        segments.append_val (seg);
                    } else if (tag == "else") {
                        stoppedAt = STOP_ELSE;
                        break;
                    } else if (tag == "/if") {
                        stoppedAt = STOP_ENDIF;
                        break;
                    } else if (tag == "/each") {
                        stoppedAt = STOP_ENDEACH;
                        break;
                    } else if (tag.has_prefix ("fallback ")) {
                        parseFallback (tag.substring (9).strip (), segments);
                    } else if (tag.contains (" | ")) {
                        int pipeIdx = tag.index_of (" | ");
                        string varName = tag.substring (0, pipeIdx).strip ();
                        string filterName = tag.substring (pipeIdx + 3).strip ();
                        var seg = new TemplateSegment (
                            TemplateSegment.Kind.VARIABLE, varName);
                        seg.filter = filterName;
                        segments.append_val (seg);
                    } else {
                        segments.append_val (
                            new TemplateSegment (TemplateSegment.Kind.VARIABLE, tag));
                    }
                } else {
                    unichar c;
                    int nextPos = pos;
                    if (tmpl.get_next_char (ref nextPos, out c)) {
                        literal.append_unichar (c);
                        pos = nextPos;
                    } else {
                        pos++;
                    }
                }
            }

            if (literal.len > 0) {
                segments.append_val (
                    new TemplateSegment (TemplateSegment.Kind.LITERAL, literal.str));
            }

            TemplateSegment[] result = new TemplateSegment[segments.length];
            for (uint i = 0; i < segments.length; i++) {
                result[i] = segments.index (i);
            }
            return result;
        }

        private static void parseFallback (string rest,
                                           GLib.Array<TemplateSegment> segments) {
            int quoteStart = rest.index_of ("\"");
            if (quoteStart < 0) {
                segments.append_val (
                    new TemplateSegment (TemplateSegment.Kind.VARIABLE, rest.strip ()));
                return;
            }
            string varName = rest.substring (0, quoteStart).strip ();
            int quoteEnd = rest.index_of ("\"", quoteStart + 1);
            string defaultVal;
            if (quoteEnd > quoteStart + 1) {
                defaultVal = rest.substring (quoteStart + 1, quoteEnd - quoteStart - 1);
            } else {
                defaultVal = "";
            }
            var seg = new TemplateSegment (TemplateSegment.Kind.FALLBACK, varName);
            seg.fallback_value = defaultVal;
            segments.append_val (seg);
        }

        private static string stopTokenToLiteral (string token) {
            if (token == STOP_ELSE) {
                return "{{else}}";
            }
            if (token == STOP_ENDIF) {
                return "{{/if}}";
            }
            if (token == STOP_ENDEACH) {
                return "{{/each}}";
            }
            return "";
        }
    }
}
