atomicfile_test_sources = files(
  './TestAtomicFile.vala'
)

atomicfile_test_sources += valacore_sources

test_unit = 'AtomicFile-test'

exe = executable(test_unit,
                 sources: atomicfile_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
