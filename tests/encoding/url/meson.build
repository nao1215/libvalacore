url_test_sources = files(
  './TestUrl.vala'
)

url_test_sources += valacore_sources

test_unit = 'UrlEncoding-test'

exe = executable(test_unit,
                 sources: url_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
