yaml_test_sources = files(
  './TestYaml.vala'
)

yaml_test_sources += valacore_sources

test_unit = 'Yaml-test'

exe = executable(test_unit,
                 sources: yaml_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
