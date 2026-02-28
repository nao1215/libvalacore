test_name = meson.project_name() + '-test'

random_test_sources = files(
  './TestRandom.vala'
)

random_test_sources += valacore_sources

test_unit = 'Random-test'

exe = executable(test_unit,
                 sources: random_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
