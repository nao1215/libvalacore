biginteger_test_sources = files(
  './TestBigInteger.vala'
)

biginteger_test_sources += valacore_sources

test_unit = 'BigInteger-test'

exe = executable(test_unit,
                 sources: biginteger_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
