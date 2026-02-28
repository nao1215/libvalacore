base64_test_sources = files(
  './TestBase64.vala'
)

base64_test_sources += valacore_sources

test_unit = 'Base64-test'

exe = executable(test_unit,
                 sources: base64_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
