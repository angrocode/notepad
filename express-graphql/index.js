
const http = require('http')
const { buildSchema } = require('graphql')
const { graphqlHTTP } = require('express-graphql')

const schema = `
    type Query {
        """getting the current milliseconds"""
        ping: Int
    }
`

const resolver = {
    ping: () => new Date().getMilliseconds()
}

http.createServer((req, res) => {

    graphqlHTTP({
        schema: buildSchema(schema),
        rootValue: resolver,
        graphiql: true,
    })(req, res)

}).listen(80, 'localhost', e => {
    e ? console.log(`HTTP server start error: ${e}`) : console.log(`HTTP server running ...`)
})
