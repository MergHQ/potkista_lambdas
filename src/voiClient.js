const axios = require('axios')

const VOI_COORDS = { lat: 60.2042066, lng: 24.9618155 }

const mangleData = data =>
  data
    .map(({short, battery, location}) => ({ vendor: 'VOI', code: short, batteryLevel: battery, lat: location[0], lng: location[1] }))

exports.fetchVoi = () => axios
  .get(`https://api.voiapp.io/v1/vehicle/status/ready?lat=${VOI_COORDS.lat}&lng=${VOI_COORDS.lng}`)
  .then(({ data }) => data)
  .then(mangleData)

