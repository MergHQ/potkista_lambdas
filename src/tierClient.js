const axios = require('axios')

const TIER_TOWN = 'HELSINKI'

const tierRequestConfig = {
  headers: {
    'X-Api-Key': process.env.TIER_API_KEY
  }
}

const mangleData = data =>
  data
    .filter(({ isRentable }) => isRentable)
    .map(({code, batteryLevel, lat, lng}) => ({ vendor: 'TIER', code, batteryLevel, lat, lng }))

exports.fetchTier = () => axios
  .get('https://platform.tier-services.io/vehicle?zoneId=' + TIER_TOWN, tierRequestConfig)
  .then(({ data }) => data.data)
  .then(mangleData)
