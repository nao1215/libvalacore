toml_test_sources = files(
  './TestToml.vala'
)

toml_test_sources += valacore_sources

test_unit = 'Toml-test'

exe = executable(test_unit,
                 sources: toml_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
