modules = {
    user: 'User',
    credentials: 'Credentials',
    collection: 'Collection',
    collectioninfo: 'CollectionInfo',
    record: 'Record',
    token: 'Token',
    userinfo: 'UserInfo',
    message: 'Message',
    network: 'Network',
    article: 'Article',
    conversation: 'Conversation',
    membership: 'Membership'
}

for k, v of modules
    exports[v] = require("./#{k}")[v]

