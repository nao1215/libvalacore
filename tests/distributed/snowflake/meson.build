snowflake_test_sources = files(
  './TestSnowflake.vala'
)

snowflake_test_sources += valacore_sources

test_unit = 'Snowflake-test'

exe = executable(test_unit,
                 sources: snowflake_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
