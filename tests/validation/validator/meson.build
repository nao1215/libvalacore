validator_test_sources = files(
  './TestValidator.vala'
)

validator_test_sources += valacore_sources

test_unit = 'Validator-test'

exe = executable(test_unit,
                 sources: validator_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
