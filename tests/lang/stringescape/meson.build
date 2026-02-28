test_name = meson.project_name() + '-test'

stringescape_test_sources = files(
  './TestStringEscape.vala'
)

stringescape_test_sources += valacore_sources

test_unit = 'StringEscape-test'

exe = executable(test_unit,
                 sources: stringescape_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
