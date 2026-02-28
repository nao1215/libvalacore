filesystem_test_sources = files(
  './TestFilesystem.vala'
)

filesystem_test_sources += valacore_sources

test_unit = 'Filesystem-test'

exe = executable(test_unit,
                 sources: filesystem_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
