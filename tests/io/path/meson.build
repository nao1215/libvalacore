test_name = meson.project_name() + '-test'

path_test_sources = files(
  './TestPath.vala'
)

path_test_sources += valacore_sources

path_test_unit = 'Path-test'

exe = executable(path_test_unit,
                 sources: path_test_sources,
                 dependencies : dependencies,
                 install: false)
test(path_test_unit, exe)