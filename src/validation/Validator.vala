using Vala.Collections;

namespace Vala.Validation {
    /**
     * Validation error for one field.
     */
    public class ValidationError : GLib.Object {
        private string _field;
        private string _message;

        public ValidationError (string field, string message) {
            _field = field;
            _message = message;
        }

        /**
         * Returns field name.
         *
         * @return field name.
         */
        public string field () {
            return _field;
        }

        /**
         * Returns error message.
         *
         * @return error message.
         */
        public string message () {
            return _message;
        }
    }

    /**
     * Validation result object.
     */
    public class ValidationResult : GLib.Object {
        private ArrayList<ValidationError> _errors;

        public ValidationResult (ArrayList<ValidationError> errors) {
            _errors = errors;
        }

        /**
         * Returns true when no validation error exists.
         *
         * @return true if validation succeeded.
         */
        public bool isValid () {
            return _errors.size () == 0;
        }

        /**
         * Returns all validation errors.
         *
         * @return error list.
         */
        public ArrayList<ValidationError> errors () {
            return _errors;
        }

        /**
         * Returns errors only for specified field.
         *
         * @param field field name.
         * @return filtered error list.
         */
        public ArrayList<ValidationError> errorsByField (string field) {
            var filtered = new ArrayList<ValidationError> ();
            for (int i = 0; i < _errors.size (); i++) {
                ValidationError ? err = _errors.get (i);
                if (err != null && err.field () == field) {
                    filtered.add (err);
                }
            }
            return filtered;
        }

        /**
         * Returns first validation error.
         *
         * @return first error or null.
         */
        public ValidationError ? firstError () {
            return _errors.get (0);
        }

        /**
         * Returns only error messages.
         *
         * @return message list.
         */
        public ArrayList<string> errorMessages () {
            var messages = new ArrayList<string> (GLib.str_equal);
            for (int i = 0; i < _errors.size (); i++) {
                ValidationError ? err = _errors.get (i);
                if (err != null) {
                    messages.add (err.message ());
                }
            }
            return messages;
        }
    }

    /**
     * Fluent validator for user input and configuration values.
     */
    public class Validator : GLib.Object {
        private ArrayList<ValidationError> _errors;
        private HashMap<string, string ?> _field_values;

        /**
         * Creates empty validator.
         */
        public Validator () {
            _errors = new ArrayList<ValidationError> ();
            _field_values = new HashMap<string, string ?> (GLib.str_hash, GLib.str_equal);
        }

        /**
         * Adds required check.
         *
         * @param field field name.
         * @param value value.
         * @return this validator.
         */
        public Validator required (string field, string ? value) {
            ensureField (field);
            rememberValue (field, value);

            if (value == null || value.strip ().length == 0) {
                addError (field, "%s is required".printf (field));
            }
            return this;
        }

        /**
         * Adds minimum length check.
         *
         * @param field field name.
         * @param value value.
         * @param min minimum length.
         * @return this validator.
         */
        public Validator minLength (string field, string ? value, int min) {
            ensureField (field);
            if (min < 0) {
                GLib.error ("min must be non-negative");
            }
            rememberValue (field, value);

            if (value == null || value.length < min) {
                addError (field, "%s must be at least %d characters".printf (field, min));
            }
            return this;
        }

        /**
         * Adds maximum length check.
         *
         * @param field field name.
         * @param value value.
         * @param max maximum length.
         * @return this validator.
         */
        public Validator maxLength (string field, string ? value, int max) {
            ensureField (field);
            if (max < 0) {
                GLib.error ("max must be non-negative");
            }
            rememberValue (field, value);

            if (value != null && value.length > max) {
                addError (field, "%s must be at most %d characters".printf (field, max));
            }
            return this;
        }

        /**
         * Adds integer range check.
         *
         * @param field field name.
         * @param value value.
         * @param min minimum value.
         * @param max maximum value.
         * @return this validator.
         */
        public Validator range (string field, int value, int min, int max) {
            ensureField (field);
            if (min > max) {
                GLib.error ("min must be less than or equal to max");
            }
            rememberValue (field, value.to_string ());

            if (value < min || value > max) {
                addError (field, "%s must be in range [%d, %d]".printf (field, min, max));
            }
            return this;
        }

        /**
         * Adds regular expression check.
         *
         * @param field field name.
         * @param value value.
         * @param regex regular expression.
         * @return this validator.
         */
        public Validator pattern (string field, string ? value, string regex) {
            ensureField (field);
            rememberValue (field, value);
            if (regex.length == 0) {
                GLib.error ("regex must not be empty");
            }

            try {
                var re = new GLib.Regex (regex);
                if (value == null || !re.match (value, 0)) {
                    addError (field, "%s has invalid format".printf (field));
                }
            } catch (GLib.RegexError err) {
                addError (field, "%s has invalid regex: %s".printf (field, err.message));
            }
            return this;
        }

        /**
         * Adds email format check.
         *
         * @param field field name.
         * @param value value.
         * @return this validator.
         */
        public Validator email (string field, string ? value) {
            return pattern (field,
                            value,
                            "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");
        }

        /**
         * Adds URL format check.
         *
         * @param field field name.
         * @param value value.
         * @return this validator.
         */
        public Validator url (string field, string ? value) {
            return pattern (field,
                            value,
                            "^https?://[A-Za-z0-9.-]+(:[0-9]+)?(/.*)?$");
        }

        /**
         * Adds custom validation rule for remembered field value.
         *
         * @param field field name.
         * @param fn predicate that returns true when valid.
         * @param message error message.
         * @return this validator.
         */
        public Validator custom (string field, owned PredicateFunc<string ?> fn, string message) {
            ensureField (field);
            if (message.length == 0) {
                GLib.error ("message must not be empty");
            }

            string ? value = _field_values.get (field);
            if (!fn (value)) {
                addError (field, message);
            }
            return this;
        }

        /**
         * Finalizes validation result.
         *
         * @return validation result.
         */
        public ValidationResult validate () {
            return new ValidationResult (_errors);
        }

        private void addError (string field, string message) {
            _errors.add (new ValidationError (field, message));
        }

        private void rememberValue (string field, string ? value) {
            _field_values.put (field, value);
        }

        private static void ensureField (string field) {
            if (field.length == 0) {
                GLib.error ("field must not be empty");
            }
        }
    }
}
