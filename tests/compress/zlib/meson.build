zlib_test_sources = files(
  './TestZlib.vala'
)

zlib_test_sources += valacore_sources

test_unit = 'Zlib-test'

exe = executable(test_unit,
                 sources: zlib_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
