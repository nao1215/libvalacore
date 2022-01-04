test_name = meson.project_name() + '-test'

file_test_sources = files(
  './TestFile.vala'
)

file_test_sources += valacore_sources

test_unit = 'File-test'

exe = executable(test_unit,
                 sources: file_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)