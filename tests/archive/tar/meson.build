tar_test_sources = files(
  './TestTar.vala'
)

tar_test_sources += valacore_sources

test_unit = 'Tar-test'

exe = executable(test_unit,
                 sources: tar_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
