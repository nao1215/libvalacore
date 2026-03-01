singleflight_test_sources = files(
  './TestSingleFlight.vala'
)

singleflight_test_sources += valacore_sources

test_unit = 'SingleFlight-test'

exe = executable(test_unit,
                 sources: singleflight_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
