filelock_test_sources = files(
  './TestFileLock.vala'
)

filelock_test_sources += valacore_sources

test_unit = 'FileLock-test'

exe = executable(test_unit,
                 sources: filelock_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
