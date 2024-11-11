# roles/couchdb/files/init-couchdb.sh
#!/bin/bash

COUCHDB_HOST="couchdb.couchdb.svc.cluster.local"
COUCHDB_PORT="5984"
COUCHDB_URL="http://${COUCHDB_HOST}:${COUCHDB_PORT}"

# Function to make curl requests with basic auth
function couch_req() {
    local method=$1
    local endpoint=$2
    local data=$3
    
    curl -s -X ${method} \
        -H "Content-Type: application/json" \
        -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" \
        ${COUCHDB_URL}${endpoint} \
        ${data:+-d "$data"}
}

echo "Creating system databases..."

# Create _users database
couch_req PUT "/_users" ""

# Create _replicator database
couch_req PUT "/_replicator" ""

# Enable single node setup
couch_req POST "/_cluster_setup" '{
  "action": "enable_single_node",
  "username": "'${COUCHDB_USER}'",
  "password": "'${COUCHDB_PASSWORD}'",
  "bind_address": "0.0.0.0",
  "port": 5984,
  "singlenode": true
}'

# Configure CORS
couch_req PUT "/_node/nonode@nohost/_config/httpd/enable_cors" '"true"'
couch_req PUT "/_node/nonode@nohost/_config/cors/origins" '"app://obsidian.md,capacitor://localhost,http://localhost"'
couch_req PUT "/_node/nonode@nohost/_config/cors/credentials" '"true"'
couch_req PUT "/_node/nonode@nohost/_config/cors/methods" '"GET, PUT, POST, HEAD, DELETE"'
couch_req PUT "/_node/nonode@nohost/_config/cors/headers" '"accept, authorization, content-type, origin, referer"'

# Set max sizes
couch_req PUT "/_node/nonode@nohost/_config/chttpd/max_http_request_size" '"4294967296"'
couch_req PUT "/_node/nonode@nohost/_config/couchdb/max_document_size" '"50000000"'

echo "CouchDB initialization complete!"