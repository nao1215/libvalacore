http_test_sources = files(
  './TestHttp.vala'
)

http_test_sources += valacore_sources

test_unit = 'Http-test'

exe = executable(test_unit,
                 sources: http_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
