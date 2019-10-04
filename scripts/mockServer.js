const express = require('express')
const lambda = require('../src/exports').handler

const app = express()

app.all('*', async (req, res) => {
  res.json(JSON.parse((await lambda(null,null)).body))
})

app.listen(3001)