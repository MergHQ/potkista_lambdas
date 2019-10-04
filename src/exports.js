const { fetchTier } = require('./tierClient')
const { fetchVoi } = require('./voiClient')

exports.handler = (event, context) =>
  Promise.all([fetchTier(), fetchVoi()])
    .then(([tiers, vois]) => ({
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json; charset=utf-8'
      },
      body: JSON.stringify([...tiers, ...vois])
    })
  )
