namespace Vala.Lang {
    /**
     * String escaping utilities.
     */
    public class StringEscape : GLib.Object {
        /**
         * Escapes HTML special characters.
         *
         * @param s source text.
         * @return escaped HTML text.
         */
        public static string escapeHtml (string s) {
            return s
                .replace ("&", "&amp;")
                .replace ("<", "&lt;")
                .replace (">", "&gt;")
                .replace ("\"", "&quot;")
                .replace ("'", "&#39;");
        }

        /**
         * Escapes JSON special characters.
         *
         * @param s source text.
         * @return escaped JSON text.
         */
        public static string escapeJson (string s) {
            GLib.StringBuilder builder = new GLib.StringBuilder ();

            for (int i = 0; i < s.length; i++) {
                char c = s[i];
                switch (c) {
                case '\\':
                    builder.append ("\\\\");
                    break;
                case '"':
                    builder.append ("\\\"");
                    break;
                case '\b':
                    builder.append ("\\b");
                    break;
                case '\f':
                    builder.append ("\\f");
                    break;
                case '\n':
                    builder.append ("\\n");
                    break;
                case '\r':
                    builder.append ("\\r");
                    break;
                case '\t':
                    builder.append ("\\t");
                    break;
                default:
                    if (c < 0x20) {
                        builder.append ("\\u");
                        builder.append ("%04x".printf ((int) c));
                    } else {
                        builder.append_c (c);
                    }
                    break;
                }
            }

            return builder.str;
        }

        /**
         * Escapes XML special characters.
         *
         * @param s source text.
         * @return escaped XML text.
         */
        public static string escapeXml (string s) {
            return s
                .replace ("&", "&amp;")
                .replace ("<", "&lt;")
                .replace (">", "&gt;")
                .replace ("\"", "&quot;")
                .replace ("'", "&apos;");
        }
    }
}
