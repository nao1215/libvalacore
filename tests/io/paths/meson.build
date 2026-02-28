path_test_sources = files(
  './TestPaths.vala'
)

path_test_sources += valacore_sources

path_test_unit = 'Paths-test'

exe = executable(path_test_unit,
                 sources: path_test_sources,
                 dependencies : dependencies,
                 install: false)
test(path_test_unit, exe)