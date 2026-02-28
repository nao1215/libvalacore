hmac_test_sources = files(
  './TestHmac.vala'
)

hmac_test_sources += valacore_sources

test_unit = 'Hmac-test'

exe = executable(test_unit,
                 sources: hmac_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
