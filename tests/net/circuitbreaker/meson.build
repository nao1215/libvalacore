circuitbreaker_test_sources = files(
  './TestCircuitBreaker.vala'
)

circuitbreaker_test_sources += valacore_sources

test_unit = 'CircuitBreaker-test'

exe = executable(test_unit,
                 sources: circuitbreaker_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
