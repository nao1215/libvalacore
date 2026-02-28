/*
 * ArgParser.vala
 *
 * Copyright 2021 Naohiro CHIKAMATSU
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
using Vala.Io;
/**
 * Vala.Parser namespace provides command-line argument parsing with the Builder pattern.
 */
namespace Vala.Parser {
    /**
     * ArgParse class parse application options. Options must be registered before
     * parsing the option arguments.
     */
    public class ArgParser : GLib.Object {
        /** Application name */
        private string appName;
        /** Application argument information for help message. */
        private string appArg;
        /** Application description for help message. */
        private string description;
        /** Application version */
        private string version;
        /** Application's author (developer) */
        private string author;
        /** Contact information (e.g. email, GitHub URL, etc.)*/
        private string contact;
        /** Application option list. */
        private List<Option> optionList;
        /** Argument without Options (e.g. test in "$ command -h -d test") */
        private List<string> argListWithoutOptions;
        /** Flag whether it has been parsed. */
        private bool parsed = false;

        /**
         * Private constructor. Call from Builder class.
         * @param Builder Builder of ArgParser class
         */
        private ArgParser (Builder builder) {
            this.appName = builder.appName;
            this.appArg = builder.appArg;
            this.description = builder.desc;
            this.version = builder.ver;
            this.author = builder.appAuthor;
            this.contact = builder.appContact;
            this.optionList = new List<Option> ();
            this.argListWithoutOptions = new List<string>();
        }

        /**
         * Add option for using parse.
         * @param shortOption Short option string.
         * @param longOption Long option string.
         * @param description Option description.
         */
        public void addOption (string shortOption, string longOption, string description) {
            optionList.append (new Option (shortOption, longOption, description));
        }

        /**
         * Show usage of this application on STDOUT.
         */
        public void usage () {
            showVersion ();
            stdout.printf ("\n");
            showDescriptionIfNeeded ();
            stdout.printf ("\n");
            showUsage ();
            stdout.printf ("\n");
            showOptions ();
            stdout.printf ("\n");
            showContactInfo ();
        }

        /**
         * Show version of this appliction on STDOUT.
         */
        public void showVersion () {
            stdout.printf ("[Application name & Version]\n");
            stdout.printf (" %s version %s\n", appName, version);
        }

        /**
         * Parse the option string.
         * @param args command line arguments.
         */
        public void parse (string[] args) {
            validOptionsIfNeeded (args);
            getArgListWithoutOptions (args);
            parsed = true;
        }

        /**
         * Returns whether the option is specified.
         * @param shortOption Short option (Only one characther)
         * @return true: option is valid, false: option is invalid.
         */
        public bool hasOption (string shortOption) {
            foreach (Option option in optionList) {
                if (option.GetShortOption () == shortOption) {
                    return option.IsValid ();
                }
            }
            return false;
        }

        /**
         * Copy commandline arguments without application name and options.
         * @return commandline arguments without application name and options.
         */
        public List<string> copyArgWithoutCmdNameAndOptions () {
            return argListWithoutOptions.copy_deep (strdup);
        }

        /**
         * Return string that contains all option and arguments.
         * Option contains ON / OFF information.
         * @return string that contains all option and arguments.
         */
        public string parseResult () {
            if (!parsed) {
                return "No result: Before parsing".dup ();
            }
            string result = "[Options]\n";
            foreach (var o in optionList) {

                result += o.IsValid () ? " ON :" : " OFF:";
                result += o.GetLongOption () + ":" + o.GetDescription () + "\n";
            }

            result += "[Arguments]\n";
            if (argListWithoutOptions.length () == 0) {
                result += " NO ARGUMENTS.\n";
            } else {
                foreach (var arg in argListWithoutOptions) {
                    result += arg + "\n";
                }
            }
            return result.dup ();
        }

        /**
         * Parse the arguments and enable options if necessary.
         * @param args command line arguments.
         */
        private void validOptionsIfNeeded (string[] args) {
            foreach (Option option in optionList) {
                foreach (string arg in args) {
                    if (isOpt (option, arg)) {
                        option.Enable ();
                        break;
                    }
                }
            }
        }

        /**
         * Create an argument string excluding command name and options.
         * @param args command line arguments.
         */
        private void getArgListWithoutOptions (string[] args) {
            foreach (string arg in args) {
                if (arg.contains (appName)) {
                    var p = new Vala.Io.Path (arg);
                    if (p.basename () == appName) {
                        continue;
                    }
                }

                bool optionFound = false;
                foreach (Option option in optionList) {
                    if (isOpt (option, arg)) {
                        optionFound = true;
                        break;
                    }
                }
                if (!optionFound) {
                    argListWithoutOptions.append (arg);
                }
            }
        }

        /**
         * Returns whether the argument string is a specified option.
         * @param opt Option information.
         * @param arg commandline argument string.
         */
        private bool isOpt (Option opt, string arg) {
            if (arg.contains ("-" + opt.GetShortOption ())) {
                if (arg.length == "-".length + opt.GetShortOption ().length) {
                    return true;
                }
            }

            if (arg.contains ("--" + opt.GetLongOption ())) {
                if (arg.length == "--".length + opt.GetLongOption ().length) {
                    return true;
                }
            }
            return false;
        }

        /**
         * Show description section on STDIN.
         * If the description is empty, it will not be displayed.
         */
        private void showDescriptionIfNeeded () {
            if (Strings.isNullOrEmpty (description)) {
                return;
            }
            stdout.printf ("[Description]\n");
            string[] descs = Strings.splitByNum (description, 78);
            foreach (string str in descs) {
                stdout.printf ("  %s\n", str);
            }
        }

        /**
         *  Show usage section on STDIN.
         */
        private void showUsage () {
            stdout.printf ("[Usage]\n");
            stdout.printf ("  %s [options] %s\n", appName, appArg);
        }

        /**
         * Show usage options on STDIN.
         */
        private void showOptions () {
            stdout.printf ("[Options]\n");
            foreach (Option option in optionList) {
                stdout.printf ("  %-18s", "-" + option.GetShortOption () + ", --" +
                               option.GetLongOption ());
                stdout.printf (" %s\n", option.GetDescription ());
            }
        }

        /**
         * Show contact information for application developers.
         */
        private void showContactInfo () {
            stdout.printf ("[Contact]\n");
            stdout.printf ("  Author  : %s\n", author);
            stdout.printf ("  Web Site: %s\n", contact);
        }

        /** Gof Builder pattern for ArgParse constructor. */
        public class Builder {
            /**
             * Unfortunately, in the Vala language, if the function name and variable
             * name are the same, a compile error will occur (the same specifications as
             * in the C language). Therefore, the variable name is changed.
             */
            /** Application name */
            private string _appName;
            public string appName { get {
                                        return _appName;
                                    } }
            /** Application argument information for help message. */
            private string _appArg;
            public string appArg { get {
                                       return _appArg;
                                   } }
            /** Application description for help message. */
            private string _desc;
            public string desc { get {
                                     return _desc;
                                 } }
            /** Application version */
            private string _ver;
            public string ver { get {
                                    return _ver;
                                } }
            /** Application's author (developer) */
            private string _appAuthor;
            public string appAuthor { get {
                                          return _appAuthor;
                                      } }
            /** Contact information (e.g. email, GitHub URL, etc.)*/
            private string _appContact;
            public string appContact { get {
                                           return _appContact;
                                       } }

            /** Constructor */
            public Builder () {
                this._appName = "";
                this._appArg = "";
                this._desc = "";
                this._ver = "";
                this._appAuthor = "";
                this._appContact = "";
            }

            /**
             * Set application name.
             * @param appName application name string (e.g. cat)
             */
            public Builder applicationName (string appName) {
                this._appName = appName;
                return this;
            }

            /**
             * Set application argument information.
             * @param appArg Application argument Inforamtion.
             *               (e.g. directory_path in "$ ddf [Options] directory_path")
             */
            public Builder applicationArgument (string appArg) {
                this._appArg = appArg;
                return this;
            }

            /**
             * Set application description.
             * @param desc application description string.
             */
            public Builder description (string desc) {
                this._desc = desc;
                return this;
            }

            /**
             * Set application version.
             * @param ver application version string (Semantic Versioning format).
             */
            public Builder version (string ver) {
                this._ver = ver;
                return this;
            }

            /**
             * Set application author.
             * @param author application author string.
             */
            public Builder author (string author) {
                this._appAuthor = author;
                return this;
            }

            /**
             * Set application developer contact information.
             * @param contact application developer contact information(e.g. GitHub URL)
             */
            public Builder contact (string contact) {
                this._appContact = contact;
                return this;
            }

            /**
             * Constructor for ArgParser class.
             */
            public ArgParser build () {
                return new ArgParser (this);
            }
        }
    }

    /**
     * The Option class saves information for one option (e.g. information of -h option).
     * This class is not used directly. Used via the ArgParser class.
     */
    private class Option : Object {
        /** Short option(e.g. -d). It is a single letter. Hyphens are excluded. */
        private string shortOption;
        /** Long option(e.g. --version). Hyphens are excluded. */
        private string longOption;
        /** Option description for help messages. */
        private string description;
        /** Whether the option is valid. true means when the user specifies an option. */
        private bool enable;

        /**
         * Constructor.
         * @param shortOption Short option string.
         * @param longOption Long option string.
         * @param description Option description.
         */
        public Option (string shortOption, string longOption, string description) {
            this.shortOption = shortOption;
            this.longOption = longOption;
            this.description = description;
            this.enable = false;
        }

        /**
         * Return short option.
         * @return Short option string.
         */
        public string GetShortOption () {
            return shortOption;
        }

        /**
         * Return long option.
         * @return Long option string.
         */
        public string GetLongOption () {
            return longOption;
        }

        /**
         * Return description for option.
         * @return String of description
         */
        public string GetDescription () {
            return description;
        }

        /**
         * Enable option.
         */
        public void Enable () {
            enable = true;
        }

        /**
         * Returns whether the option is valid.
         * @return true: option is valid, false: option is invalid.
         */
        public bool IsValid () {
            return enable;
        }
    }
}