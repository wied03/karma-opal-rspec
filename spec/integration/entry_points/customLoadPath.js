var testsContext = require.context('./spec', true, /_spec\.rb$/)
testsContext.keys().forEach(testsContext)
