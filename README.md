# Hooky

## Demo
Loom Video: https://www.loom.com/share/cc7d47cbcd8944b2bd7f2e0d706f4cf2

## Instructions
1. Add ./db/pg-data/ as shared docker resource
2. Run docker-compose up
3. Run cURL like so
```
## Create Webhook
curl -X "POST" "http://localhost:5001/api/v1/webhook" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d $'{
  "body": "Avengers Assemble!",
  "httpMethod": "POST",
  "url": "https://webhook.site/e1fd1d22-0b59-454a-9398-e1fe0481e0ab",
  "headers": [
    {
      "key": "abc",
      "value": "123"
    }
  ],
  "queryParams": [
    {
      "key": "def",
      "value": "456"
    }
  ]
}'
```

## Postgres
host: localhost

port: 5432

username: hooky

password: P0stGr3$$
