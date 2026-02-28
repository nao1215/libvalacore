bigdecimal_test_sources = files(
  './TestBigDecimal.vala'
)

bigdecimal_test_sources += valacore_sources

test_unit = 'BigDecimal-test'

exe = executable(test_unit,
                 sources: bigdecimal_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
