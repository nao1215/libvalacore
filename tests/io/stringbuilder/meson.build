stringbuilder_test_sources = files(
  './TestStringBuilder.vala'
)

stringbuilder_test_sources += valacore_sources

test_unit = 'StringBuilder-test'

exe = executable(test_unit,
                 sources: stringbuilder_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
