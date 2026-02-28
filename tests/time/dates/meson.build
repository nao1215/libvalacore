dates_test_sources = files(
  './TestDates.vala'
)

dates_test_sources += valacore_sources

test_unit = 'Dates-test'

exe = executable(test_unit,
                 sources: dates_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
