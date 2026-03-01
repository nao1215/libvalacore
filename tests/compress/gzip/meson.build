gzip_test_sources = files(
  './TestGzip.vala'
)

gzip_test_sources += valacore_sources

test_unit = 'Gzip-test'

exe = executable(test_unit,
                 sources: gzip_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
